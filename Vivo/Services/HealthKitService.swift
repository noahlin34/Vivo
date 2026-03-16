//
//  HealthKitService.swift
//  Vivo
//

import Foundation
import HealthKit

struct ImportedVital {
    let type: String
    let value: Double
    let secondaryValue: Double?
    let unit: String
    let recordedAt: Date
}

@Observable
final class HealthKitService {

    var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return HKHealthStore.isHealthDataAvailable()
        #endif
    }

    private let store = HKHealthStore()

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let bp = HKCorrelationType.correlationType(forIdentifier: .bloodPressure) {
            types.insert(bp)
        }
        if let systolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic) {
            types.insert(systolic)
        }
        if let diastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            types.insert(diastolic)
        }
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        if let hr = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(hr)
        }
        if let bg = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) {
            types.insert(bg)
        }
        return types
    }()

    func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchRecentVitals(days: Int = 30) async throws -> [ImportedVital] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        async let bp = fetchBloodPressure(since: cutoff)
        async let weight = fetchQuantity(.bodyMass, unit: .pound(), vitalType: "Weight", vitalUnit: "lbs", since: cutoff)
        async let hr = fetchQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), vitalType: "Heart Rate", vitalUnit: "bpm", since: cutoff)
        async let bg = fetchQuantity(.bloodGlucose, unit: HKUnit(from: "mg/dL"), vitalType: "Blood Sugar", vitalUnit: "mg/dL", since: cutoff)

        let results = try await [bp, weight, hr, bg]
        return results.flatMap { $0 }
    }

    // MARK: - Private

    private func fetchBloodPressure(since cutoff: Date) async throws -> [ImportedVital] {
        guard let correlationType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: cutoff, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKCorrelationQuery(
                type: correlationType,
                predicate: predicate,
                samplePredicates: nil
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let correlations = results else {
                    continuation.resume(returning: [])
                    return
                }

                let vitals: [ImportedVital] = correlations.compactMap { correlation in
                    guard
                        let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
                        let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic),
                        let systolicSample = correlation.objects(for: systolicType).first as? HKQuantitySample,
                        let diastolicSample = correlation.objects(for: diastolicType).first as? HKQuantitySample
                    else { return nil }

                    let systolic = systolicSample.quantity.doubleValue(for: .millimeterOfMercury())
                    let diastolic = diastolicSample.quantity.doubleValue(for: .millimeterOfMercury())

                    return ImportedVital(
                        type: "Blood Pressure",
                        value: systolic,
                        secondaryValue: diastolic,
                        unit: "mmHg",
                        recordedAt: correlation.startDate
                    )
                }
                continuation.resume(returning: vitals)
            }
            store.execute(query)
        }
    }

    private func fetchQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        vitalType: String,
        vitalUnit: String,
        since cutoff: Date
    ) async throws -> [ImportedVital] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: cutoff, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let vitals = quantitySamples.map { sample in
                    ImportedVital(
                        type: vitalType,
                        value: sample.quantity.doubleValue(for: unit),
                        secondaryValue: nil,
                        unit: vitalUnit,
                        recordedAt: sample.startDate
                    )
                }
                continuation.resume(returning: vitals)
            }
            store.execute(query)
        }
    }
}
