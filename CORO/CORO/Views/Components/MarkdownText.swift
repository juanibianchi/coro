import SwiftUI

struct MarkdownText: View {
    let content: String
    let fontSize: CGFloat
    let lineSpacing: CGFloat

    init(_ content: String, fontSize: CGFloat = 16, lineSpacing: CGFloat = 7) {
        self.content = content
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
    }

    var body: some View {
        let processedContent = preprocessLaTeX(content)

        if let attributedString = try? AttributedString(markdown: processedContent, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributedString)
                .font(.system(size: fontSize))
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
        } else {
            // Fallback if markdown parsing fails
            Text(processedContent)
                .font(.system(size: fontSize))
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
        }
    }

    /// Pre-process LaTeX expressions to make them more readable
    func preprocessLaTeX(_ text: String) -> String {
        var processed = text

        // Handle \boxed{value} - convert to [value]
        processed = processed.replacingOccurrences(
            of: #"\\boxed\{([^}]+)\}"#,
            with: "**[$1]**",
            options: .regularExpression
        )

        // Handle display math $$...$$ - convert to indented text
        processed = processed.replacingOccurrences(
            of: #"\$\$([^$]+)\$\$"#,
            with: "\n\n**$1**\n\n",
            options: .regularExpression
        )

        // Handle inline math $...$ - just remove the $ delimiters
        processed = processed.replacingOccurrences(
            of: #"\$([^$]+)\$"#,
            with: "$1",
            options: .regularExpression
        )

        // Convert common LaTeX commands to Unicode
        let latexReplacements: [String: String] = [
            #"\\times"#: "×",
            #"\\div"#: "÷",
            #"\\pm"#: "±",
            #"\\leq"#: "≤",
            #"\\geq"#: "≥",
            #"\\neq"#: "≠",
            #"\\approx"#: "≈",
            #"\\infty"#: "∞",
            #"\\alpha"#: "α",
            #"\\beta"#: "β",
            #"\\gamma"#: "γ",
            #"\\delta"#: "δ",
            #"\\pi"#: "π",
            #"\\theta"#: "θ",
            #"\\lambda"#: "λ",
            #"\\mu"#: "μ",
            #"\\sigma"#: "σ",
            #"\\sum"#: "Σ",
            #"\\sqrt"#: "√",
            #"\\frac"#: "/",
            #"\\\\"#: "\n"
        ]

        for (latex, unicode) in latexReplacements {
            processed = processed.replacingOccurrences(of: latex, with: unicode)
        }

        // Handle simple fractions \frac{a}{b} -> (a/b)
        processed = processed.replacingOccurrences(
            of: #"\\frac\{([^}]+)\}\{([^}]+)\}"#,
            with: "($1/$2)",
            options: .regularExpression
        )

        // Handle superscripts ^{n} - convert to Unicode superscripts where possible
        let superscriptMap: [String: String] = [
            "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
            "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"
        ]
        processed = processed.replacingOccurrences(
            of: #"\^\{([0-9])\}"#,
            with: { match in
                let digit = String(match.dropFirst(2).dropLast())
                return superscriptMap[digit] ?? "^\(digit)"
            },
            options: .regularExpression
        )

        // Handle subscripts _{n} - convert to Unicode subscripts where possible
        let subscriptMap: [String: String] = [
            "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
            "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉"
        ]
        processed = processed.replacingOccurrences(
            of: #"_\{([0-9])\}"#,
            with: { match in
                let digit = String(match.dropFirst(2).dropLast())
                return subscriptMap[digit] ?? "_\(digit)"
            },
            options: .regularExpression
        )

        return processed
    }
}

extension String {
    func replacingOccurrences(
        of pattern: String,
        with replacement: @escaping (String) -> String,
        options: CompareOptions = []
    ) -> String {
        guard options.contains(.regularExpression),
              let regex = try? NSRegularExpression(pattern: pattern) else {
            return self
        }

        let nsString = self as NSString
        let matches = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))

        var result = self
        for match in matches.reversed() {
            let matchString = nsString.substring(with: match.range)
            let replacementString = replacement(matchString)
            result = (result as NSString).replacingCharacters(in: match.range, with: replacementString) as String
        }

        return result
    }
}
