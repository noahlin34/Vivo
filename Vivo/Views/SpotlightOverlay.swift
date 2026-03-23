//
//  SpotlightOverlay.swift
//  Vivo
//

import SwiftUI

// MARK: - Reverse Mask Helper

extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .ignoresSafeArea()
                .overlay { mask().blendMode(.destinationOut) }
        }
    }
}

// MARK: - Tooltip Bubble

private struct TooltipBubble: View {
    let message: String
    let pointsDown: Bool
    var caretOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            if !pointsDown {
                caret.rotationEffect(.degrees(180))
                    .offset(x: caretOffset)
            }
            Text(message)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(Color.nearBlack)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .warmShadow()
            if pointsDown {
                caret.offset(x: caretOffset)
            }
        }
    }

    private var caret: some View {
        Triangle()
            .fill(Color.cardBg)
            .frame(width: 16, height: 8)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

// MARK: - Spotlight Overlay

struct SpotlightOverlay: View {
    let walkthrough: WalkthroughManager
    @AppStorage("hasCompletedWalkthrough") private var hasCompletedWalkthrough = false

    // The overlay is attached with .ignoresSafeArea() so its coordinate space
    // starts at (0,0) — identical to .global. Use UIScreen bounds for clamping.
    private var screenSize: CGSize { UIScreen.main.bounds.size }
    @State private var featuresVisible = false

    var body: some View {
        if walkthrough.isActive {
            switch walkthrough.currentStep {
            case .tapMedsTab:
                spotlightView(
                    frame: walkthrough.medsTabFrame,
                    cornerRadius: 14,
                    padding: 10,
                    message: "Tap Meds to set up\nyour medications",
                    tooltipAbove: true
                )
                .transition(.opacity)
            case .tapAddButton:
                spotlightView(
                    frame: walkthrough.addButtonFrame,
                    cornerRadius: 16,
                    padding: 10,
                    message: "Tap + to add your\nfirst medication",
                    tooltipAbove: false
                )
                .transition(.opacity)
            case .addingMedication:
                EmptyView()
            case .complete:
                completionOverlay
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Spotlight View

    private func spotlightView(
        frame: CGRect,
        cornerRadius: CGFloat,
        padding: CGFloat,
        message: String,
        tooltipAbove: Bool
    ) -> some View {
        let spotRect = frame.insetBy(dx: -padding, dy: -padding)
        let tooltipHalfWidth: CGFloat = 110
        let tooltipHalfHeight: CGFloat = 50
        let margin: CGFloat = 16

        // Clamp X so tooltip stays on screen
        let rawX = spotRect.midX
        let tooltipX = min(max(rawX, tooltipHalfWidth + margin), screenSize.width - tooltipHalfWidth - margin)

        // Offset the caret so it points at the actual target even when the box is clamped
        let rawCaretOffset = spotRect.midX - tooltipX
        let caretOffset = min(max(rawCaretOffset, -(tooltipHalfWidth - 10)), tooltipHalfWidth - 10)

        // Place tooltip above or below; clamp so it never enters the status bar or bottom edge
        let rawY = tooltipAbove ? spotRect.minY - tooltipHalfHeight - margin : spotRect.maxY + tooltipHalfHeight + margin
        let tooltipY = min(max(rawY, tooltipHalfHeight + margin), screenSize.height - tooltipHalfHeight - margin)

        return ZStack {
            // Dim layer with cutout
            Color.black.opacity(0.55)
                .reverseMask {
                    RoundedRectangle(cornerRadius: cornerRadius + 4, style: .continuous)
                        .frame(width: spotRect.width, height: spotRect.height)
                        .position(x: spotRect.midX, y: spotRect.midY)
                }
                .ignoresSafeArea()

            // Pulsing ring
            RoundedRectangle(cornerRadius: cornerRadius + 4, style: .continuous)
                .strokeBorder(Color.primaryTeal.opacity(0.7), lineWidth: 2)
                .frame(width: spotRect.width, height: spotRect.height)
                .position(x: spotRect.midX, y: spotRect.midY)

            // Tooltip — caret offset tracks the target when the box is clamped
            TooltipBubble(message: message, pointsDown: tooltipAbove, caretOffset: caretOffset)
                .frame(maxWidth: 220)
                .position(x: tooltipX, y: tooltipY)
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.25), value: walkthrough.currentStep)
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Checkmark + title + subtitle
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce)
                    Text("You're all set!")
                        .font(.system(size: 26, weight: .regular, design: .serif))
                        .foregroundStyle(.white)
                    Text("Your first medication is tracked.")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.75))
                }

                // Divider
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 8)

                // Section header
                Text("Here's what else Vivo can do:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                // Feature rows
                VStack(spacing: 14) {
                    featureRow(icon: "pill.fill",          gradient: [.tealStart,   .tealEnd],   name: "Meds",   description: "Track doses & refills",             index: 0)
                    featureRow(icon: "stethoscope",        gradient: [.amberStart,  .amberEnd],  name: "Care",   description: "Doctors & appointments",            index: 1)
                    featureRow(icon: "waveform.path.ecg",  gradient: [.roseStart,   .roseEnd],   name: "Vitals", description: "Blood pressure, weight & more",      index: 2)
                    featureRow(icon: "note.text",          gradient: [.purpleStart, .purpleEnd], name: "Notes",  description: "Health journal & questions",         index: 3)
                }

                // Let's go button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasCompletedWalkthrough = true
                        walkthrough.finish()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Let's go")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(colors: [Color.tealStart, Color.tealEnd], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .warmShadow()
                }
                .buttonStyle(.plain)
                .opacity(featuresVisible ? 1 : 0)
                .offset(y: featuresVisible ? 0 : 10)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.65), value: featuresVisible)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 32)
        }
        .onAppear {
            featuresVisible = false
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.2)) {
                featuresVisible = true
            }
        }
    }

    private func featureRow(icon: String, gradient: [Color], name: String, description: String, index: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
        }
        .opacity(featuresVisible ? 1 : 0)
        .offset(y: featuresVisible ? 0 : 12)
        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.3 + Double(index) * 0.08), value: featuresVisible)
    }
}

