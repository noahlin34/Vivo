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

    var body: some View {
        VStack(spacing: 0) {
            if !pointsDown {
                caret.rotationEffect(.degrees(180))
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
                caret
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

    var body: some View {
        GeometryReader { geo in
            // Convert global frame coords → overlay-local coords by subtracting the overlay's own origin
            let overlayOrigin = geo.frame(in: .global).origin
            let overlaySize = geo.size
            if walkthrough.isActive {
                switch walkthrough.currentStep {
                case .tapMedsTab:
                    spotlightView(
                        frame: walkthrough.medsTabFrame.toLocal(overlayOrigin),
                        cornerRadius: 14,
                        padding: 10,
                        message: "Tap Meds to set up\nyour medications",
                        tooltipAbove: true,
                        overlaySize: overlaySize
                    )
                    .transition(.opacity)
                case .tapAddButton:
                    spotlightView(
                        frame: walkthrough.addButtonFrame.toLocal(overlayOrigin),
                        cornerRadius: 16,
                        padding: 10,
                        message: "Tap + to add your\nfirst medication",
                        tooltipAbove: false,
                        overlaySize: overlaySize
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
    }

    // MARK: - Spotlight View

    private func spotlightView(
        frame: CGRect,
        cornerRadius: CGFloat,
        padding: CGFloat,
        message: String,
        tooltipAbove: Bool,
        overlaySize: CGSize
    ) -> some View {
        let spotRect = frame.insetBy(dx: -padding, dy: -padding)
        let tooltipHalfWidth: CGFloat = 110
        let tooltipHalfHeight: CGFloat = 50
        let margin: CGFloat = 16

        // Clamp X so tooltip stays on screen
        let rawX = spotRect.midX
        let tooltipX = min(max(rawX, tooltipHalfWidth + margin), overlaySize.width - tooltipHalfWidth - margin)

        // Place tooltip above or below; clamp so it never enters the status bar or bottom edge
        let rawY = tooltipAbove ? spotRect.minY - tooltipHalfHeight - margin : spotRect.maxY + tooltipHalfHeight + margin
        let tooltipY = min(max(rawY, tooltipHalfHeight + margin), overlaySize.height - tooltipHalfHeight - margin)

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

            // Tooltip
            TooltipBubble(message: message, pointsDown: tooltipAbove)
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

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce)
                Text("You're all set!")
                    .font(.system(size: 26, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                Text("You can add more medications and\ntrack your health from each tab.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    hasCompletedWalkthrough = true
                    walkthrough.finish()
                }
            }
        }
    }
}

// MARK: - Coordinate Helper

private extension CGRect {
    /// Converts a rect from global screen coordinates to the overlay's local coordinate space.
    func toLocal(_ overlayOrigin: CGPoint) -> CGRect {
        CGRect(x: minX - overlayOrigin.x, y: minY - overlayOrigin.y, width: width, height: height)
    }
}
