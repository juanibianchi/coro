import XCTest
import SwiftUI
@testable import CORO

final class MarkdownTextTests: XCTestCase {

    // MARK: - LaTeX Preprocessing Tests

    func testBoxedConversion() {
        let input = "The answer is $\\boxed{64}$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("**[64]**"))
        XCTAssertFalse(processed.contains("\\boxed"))
    }

    func testInlineMathRemoval() {
        let input = "Calculate $x^2 + y^2$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertFalse(processed.contains("$"))
        XCTAssertTrue(processed.contains("x^2 + y^2"))
    }

    func testDisplayMathConversion() {
        let input = "Formula: $$E = mc^2$$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertFalse(processed.contains("$$"))
        XCTAssertTrue(processed.contains("E = mc^2"))
    }

    func testTimesSymbolConversion() {
        let input = "Calculate $2 \\times 3$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("×"))
        XCTAssertFalse(processed.contains("\\times"))
    }

    func testDivSymbolConversion() {
        let input = "Calculate $6 \\div 2$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("÷"))
        XCTAssertFalse(processed.contains("\\div"))
    }

    func testGreekLetters() {
        let input = "Variables: $\\alpha$, $\\beta$, $\\gamma$, $\\pi$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("α"))
        XCTAssertTrue(processed.contains("β"))
        XCTAssertTrue(processed.contains("γ"))
        XCTAssertTrue(processed.contains("π"))
    }

    func testComparisonSymbols() {
        let input = "Range: $x \\leq 10$ and $y \\geq 5$ and $z \\neq 0$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("≤"))
        XCTAssertTrue(processed.contains("≥"))
        XCTAssertTrue(processed.contains("≠"))
    }

    func testFractionConversion() {
        let input = "Fraction: $\\frac{3}{4}$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("(3/4)"))
        XCTAssertFalse(processed.contains("\\frac"))
    }

    func testSuperscriptConversion() {
        let input = "Power: $x^{2}$ and $y^{3}$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("²"))
        XCTAssertTrue(processed.contains("³"))
    }

    func testSubscriptConversion() {
        let input = "Variable: $x_{1}$ and $y_{2}$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("₁"))
        XCTAssertTrue(processed.contains("₂"))
    }

    func testComplexExpression() {
        let input = "Solution: $\\boxed{\\frac{\\pi}{2} \\times r^{2}}$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        // Should convert boxed, fraction, pi, times, and superscript
        XCTAssertTrue(processed.contains("π"))
        XCTAssertTrue(processed.contains("×"))
        XCTAssertTrue(processed.contains("²"))
        XCTAssertFalse(processed.contains("\\boxed"))
        XCTAssertFalse(processed.contains("\\frac"))
    }

    func testMultipleBoxedValues() {
        let input = "Answers: $\\boxed{12}$ and $\\boxed{24}$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("**[12]**"))
        XCTAssertTrue(processed.contains("**[24]**"))
    }

    func testMixedContent() {
        let input = "Normal text with $x^{2}$ and \\alpha without math delimiters"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("Normal text"))
        XCTAssertTrue(processed.contains("²"))
        XCTAssertTrue(processed.contains("α"))
    }

    func testNoLatex() {
        let input = "Just plain text without any LaTeX"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertEqual(input, processed)
    }

    func testInfinitySymbol() {
        let input = "Limit approaches $\\infty$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("∞"))
        XCTAssertFalse(processed.contains("\\infty"))
    }

    func testApproximatelySymbol() {
        let input = "Value is $\\approx 3.14$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("≈"))
        XCTAssertFalse(processed.contains("\\approx"))
    }

    func testSumSymbol() {
        let input = "Total: $\\sum x_i$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("Σ"))
        XCTAssertFalse(processed.contains("\\sum"))
    }

    func testSqrtSymbol() {
        let input = "Root: $\\sqrt{16}$"
        let markdownText = MarkdownText(input)
        let processed = markdownText.preprocessLaTeX(input)

        XCTAssertTrue(processed.contains("√"))
        XCTAssertFalse(processed.contains("\\sqrt"))
    }
}
