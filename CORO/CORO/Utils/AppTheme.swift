import SwiftUI
import UIKit

enum AppTheme {

    enum Colors {
        static let background = Color.adaptive(
            light: UIColor(red: 11/255, green: 18/255, blue: 32/255, alpha: 1),
            dark: UIColor(red: 11/255, green: 18/255, blue: 32/255, alpha: 1)
        )

        static let surface = Color.adaptive(
            light: UIColor(red: 17/255, green: 29/255, blue: 51/255, alpha: 1),
            dark: UIColor(red: 17/255, green: 29/255, blue: 51/255, alpha: 1)
        )

        static let surfaceElevated = Color.adaptive(
            light: UIColor(red: 23/255, green: 39/255, blue: 66/255, alpha: 1),
            dark: UIColor(red: 23/255, green: 39/255, blue: 66/255, alpha: 1)
        )

        static let outline = Color.adaptive(
            light: UIColor(red: 45/255, green: 63/255, blue: 90/255, alpha: 1),
            dark: UIColor(red: 45/255, green: 63/255, blue: 90/255, alpha: 1)
        )

        static let accentGradientStart = Color.adaptive(
            light: UIColor(red: 255/255, green: 118/255, blue: 67/255, alpha: 1),
            dark: UIColor(red: 255/255, green: 118/255, blue: 67/255, alpha: 1)
        )

        static let accentGradientEnd = Color.adaptive(
            light: UIColor(red: 255/255, green: 88/255, blue: 90/255, alpha: 1),
            dark: UIColor(red: 255/255, green: 88/255, blue: 90/255, alpha: 1)
        )

        static let accent = Color.adaptive(
            light: UIColor(red: 255/255, green: 135/255, blue: 77/255, alpha: 1),
            dark: UIColor(red: 255/255, green: 135/255, blue: 77/255, alpha: 1)
        )

        static let textPrimary = Color.adaptive(
            light: UIColor(red: 244/255, green: 243/255, blue: 240/255, alpha: 1),
            dark: UIColor(red: 244/255, green: 243/255, blue: 240/255, alpha: 1)
        )

        static let textSecondary = Color.adaptive(
            light: UIColor(red: 150/255, green: 166/255, blue: 196/255, alpha: 1),
            dark: UIColor(red: 150/255, green: 166/255, blue: 196/255, alpha: 1)
        )

        static let success = Color.adaptive(
            light: UIColor(red: 68/255, green: 198/255, blue: 150/255, alpha: 1),
            dark: UIColor(red: 68/255, green: 198/255, blue: 150/255, alpha: 1)
        )

        static let warning = Color.adaptive(
            light: UIColor(red: 255/255, green: 214/255, blue: 102/255, alpha: 1),
            dark: UIColor(red: 255/255, green: 214/255, blue: 102/255, alpha: 1)
        )

        static func modelAccent(for id: String) -> Color {
            switch id {
            case "gemini":
                return Color.adaptive(
                    light: UIColor(red: 79/255, green: 172/255, blue: 255/255, alpha: 1),
                    dark: UIColor(red: 79/255, green: 172/255, blue: 255/255, alpha: 1)
                )
            case "llama-70b":
                return Color.adaptive(
                    light: UIColor(red: 156/255, green: 112/255, blue: 255/255, alpha: 1),
                    dark: UIColor(red: 156/255, green: 112/255, blue: 255/255, alpha: 1)
                )
            case "llama-8b":
                return Color.adaptive(
                    light: UIColor(red: 255/255, green: 105/255, blue: 175/255, alpha: 1),
                    dark: UIColor(red: 255/255, green: 105/255, blue: 175/255, alpha: 1)
                )
            case "mixtral":
                return Color.adaptive(
                    light: UIColor(red: 255/255, green: 166/255, blue: 92/255, alpha: 1),
                    dark: UIColor(red: 255/255, green: 166/255, blue: 92/255, alpha: 1)
                )
            case "deepseek":
                return Color.adaptive(
                    light: UIColor(red: 53/255, green: 192/255, blue: 205/255, alpha: 1),
                    dark: UIColor(red: 53/255, green: 192/255, blue: 205/255, alpha: 1)
                )
            case "llama-3.2-1b-local":
                return Color.adaptive(
                    light: UIColor(red: 255/255, green: 139/255, blue: 117/255, alpha: 1),
                    dark: UIColor(red: 255/255, green: 139/255, blue: 117/255, alpha: 1)
                )
            case "cerebras-llama-3.1-8b":
                return Color(red: 1.0, green: 0.54, blue: 0.36)
            case "cerebras-llama-3.3-70b":
                return Color(red: 0.98, green: 0.45, blue: 0.53)
            case "cerebras-gpt-oss-120b":
                return Color(red: 0.53, green: 0.72, blue: 1.0)
            case "cerebras-qwen-3-32b":
                return Color(red: 0.38, green: 0.82, blue: 0.78)
            default:
                return Color.adaptive(
                    light: UIColor(red: 108/255, green: 127/255, blue: 160/255, alpha: 1),
                    dark: UIColor(red: 108/255, green: 127/255, blue: 160/255, alpha: 1)
                )
            }
        }
    }

    enum Gradients {
        static let accent = LinearGradient(
            colors: [Colors.accentGradientStart, Colors.accentGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Typography {
        static let hero = Font.system(size: 32, weight: .semibold, design: .rounded)
        static let title = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let subtitle = Font.system(size: 17, weight: .medium, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let caption = Font.system(size: 13, weight: .medium, design: .default)
        static let overline = Font.system(size: 12, weight: .semibold, design: .rounded)
    }
}

private extension Color {
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}
