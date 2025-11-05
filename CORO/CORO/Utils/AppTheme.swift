import SwiftUI
import UIKit

enum AppTheme {

    enum Colors {
        static let background = Color.adaptive(
            light: UIColor(red: 246/255, green: 243/255, blue: 238/255, alpha: 1),
            dark: UIColor(red: 14/255, green: 14/255, blue: 18/255, alpha: 1)
        )

        static let surface = Color.adaptive(
            light: UIColor(red: 255/255, green: 253/255, blue: 250/255, alpha: 1),
            dark: UIColor(red: 28/255, green: 28/255, blue: 34/255, alpha: 1)
        )

        static let surfaceElevated = Color.adaptive(
            light: UIColor(red: 255/255, green: 251/255, blue: 244/255, alpha: 1),
            dark: UIColor(red: 36/255, green: 36/255, blue: 44/255, alpha: 1)
        )

        static let outline = Color.adaptive(
            light: UIColor(red: 224/255, green: 213/255, blue: 201/255, alpha: 1),
            dark: UIColor(red: 71/255, green: 71/255, blue: 79/255, alpha: 1)
        )

        static let accentGradientStart = Color.adaptive(
            light: UIColor(red: 233/255, green: 96/255, blue: 44/255, alpha: 1),
            dark: UIColor(red: 255/255, green: 142/255, blue: 64/255, alpha: 1)
        )

        static let accentGradientEnd = Color.adaptive(
            light: UIColor(red: 204/255, green: 73/255, blue: 55/255, alpha: 1),
            dark: UIColor(red: 255/255, green: 104/255, blue: 97/255, alpha: 1)
        )

        static let accent = Color.adaptive(
            light: UIColor(red: 224/255, green: 103/255, blue: 53/255, alpha: 1),
            dark: UIColor(red: 255/255, green: 156/255, blue: 86/255, alpha: 1)
        )

        static let textPrimary = Color.adaptive(
            light: UIColor(red: 51/255, green: 40/255, blue: 34/255, alpha: 1),
            dark: UIColor(red: 241/255, green: 236/255, blue: 229/255, alpha: 1)
        )

        static let textSecondary = Color.adaptive(
            light: UIColor(red: 120/255, green: 110/255, blue: 102/255, alpha: 1),
            dark: UIColor(red: 161/255, green: 161/255, blue: 169/255, alpha: 1)
        )

        static let success = Color.adaptive(
            light: UIColor(red: 54/255, green: 171/255, blue: 116/255, alpha: 1),
            dark: UIColor(red: 108/255, green: 219/255, blue: 165/255, alpha: 1)
        )

        static let warning = Color.adaptive(
            light: UIColor(red: 249/255, green: 179/255, blue: 16/255, alpha: 1),
            dark: UIColor(red: 255/255, green: 204/255, blue: 64/255, alpha: 1)
        )

        static func modelAccent(for id: String) -> Color {
            switch id {
            case "gemini":
                return Color.adaptive(
                    light: UIColor(red: 75/255, green: 115/255, blue: 255/255, alpha: 1),
                    dark: UIColor(red: 123/255, green: 160/255, blue: 255/255, alpha: 1)
                )
            case "llama-70b":
                return Color.adaptive(
                    light: UIColor(red: 130/255, green: 82/255, blue: 255/255, alpha: 1),
                    dark: UIColor(red: 172/255, green: 135/255, blue: 255/255, alpha: 1)
                )
            case "llama-8b":
                return Color.adaptive(
                    light: UIColor(red: 255/255, green: 102/255, blue: 184/255, alpha: 1),
                    dark: UIColor(red: 255/255, green: 147/255, blue: 211/255, alpha: 1)
                )
            case "deepseek":
                return Color.adaptive(
                    light: UIColor(red: 12/255, green: 167/255, blue: 177/255, alpha: 1),
                    dark: UIColor(red: 66/255, green: 208/255, blue: 215/255, alpha: 1)
                )
            case "llama-3.2-1b-local":
                return Color.adaptive(
                    light: UIColor(red: 255/255, green: 149/255, blue: 101/255, alpha: 1),
                    dark: UIColor(red: 255/255, green: 190/255, blue: 140/255, alpha: 1)
                )
            default:
                return Color.adaptive(
                    light: UIColor(red: 168/255, green: 168/255, blue: 180/255, alpha: 1),
                    dark: UIColor(red: 210/255, green: 210/255, blue: 221/255, alpha: 1)
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
