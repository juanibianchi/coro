import SwiftUI

struct LoadingSkeletonView: View {
    @State private var isAnimating = false
    let modelCount: Int

    var body: some View {
        VStack(spacing: 0) {
            // Header with animated shimmer
            VStack(spacing: 16) {
                // Prompt placeholder
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        ShimmerRectangle(width: 100, height: 10)
                        Spacer()
                    }

                    VStack(spacing: 8) {
                        ShimmerRectangle(width: nil, height: 12)
                        ShimmerRectangle(width: 250, height: 12)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.Colors.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppTheme.Colors.outline.opacity(0.4), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Stats placeholder
                HStack(spacing: 12) {
                    ShimmerCircle(size: 12)
                    ShimmerRectangle(width: 60, height: 10)
                    ShimmerCircle(size: 6)
                    ShimmerCircle(size: 12)
                    ShimmerRectangle(width: 70, height: 10)
                }
                .padding(.bottom, 12)
            }
            .background(AppTheme.Colors.surface.opacity(0.95))

            // Tab bar placeholder
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<modelCount, id: \.self) { _ in
                        ShimmerRectangle(width: 140, height: 44)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .background(AppTheme.Colors.surface.opacity(0.95))

            // Content area
            VStack(spacing: 20) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            ShimmerRectangle(width: nil, height: 14)
                            ShimmerRectangle(width: 280, height: 14)
                            ShimmerRectangle(width: 220, height: 14)
                        }
                        Spacer()
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppTheme.Colors.surface.opacity(0.9))
        }
    }
}

struct ShimmerRectangle: View {
    let width: CGFloat?
    let height: CGFloat
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.15),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(6)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

struct ShimmerCircle: View {
    let size: CGFloat
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.15),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}
