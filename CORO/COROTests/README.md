# CORO iOS Test Suite

Comprehensive unit tests for the CORO iOS app covering ViewModels, Services, and UI components.

## Test Coverage

### ChatViewModelTests (20+ tests)

Tests for the core business logic of the app:

**Initialization Tests**
- `testInitialization` - Verifies default state on startup
- `testLoadDefaultModels` - Ensures models load correctly

**Model Selection Tests**
- `testToggleModel` - Tests model selection/deselection
- `testSelectAllModels` - Tests selecting all models at once
- `testDeselectAllModels` - Tests clearing all selections

**Validation Tests**
- `testCanSubmitWithEmptyPrompt` - Validates empty prompt handling
- `testCanSubmitWithNoModels` - Validates no model selection
- `testCanSubmitWithValidInput` - Validates proper input acceptance

**Chat Request Tests**
- `testSendChatRequestWithEmptyPrompt` - Error handling for empty prompts
- `testSendChatRequestWithNoModels` - Error handling for no models
- `testSendChatRequestSuccess` - Successful API request flow
- `testSendChatRequestWithError` - Error handling for API failures

**Conversation History Tests**
- `testConversationHistoryUpdates` - Verifies history tracking
- `testStartNewChat` - Tests conversation reset

**Model Routing Tests**
- `testCloudAndLocalModelSeparation` - Tests cloud vs on-device routing

**Helper Methods Tests**
- `testGetModelName` - Model name retrieval
- `testGetModelColor` - Model color mapping

### MarkdownTextTests (18 tests)

Tests for LaTeX and mathematical notation preprocessing:

**Basic Conversions**
- `testBoxedConversion` - `\boxed{64}` → **[64]**
- `testInlineMathRemoval` - Removes `$` delimiters
- `testDisplayMathConversion` - `$$..$$` handling

**Symbol Conversions**
- `testTimesSymbolConversion` - `\times` → ×
- `testDivSymbolConversion` - `\div` → ÷
- `testGreekLetters` - α, β, γ, π conversions
- `testComparisonSymbols` - ≤, ≥, ≠ conversions
- `testInfinitySymbol` - `\infty` → ∞
- `testApproximatelySymbol` - `\approx` → ≈
- `testSumSymbol` - `\sum` → Σ
- `testSqrtSymbol` - `\sqrt` → √

**Expression Conversions**
- `testFractionConversion` - `\frac{3}{4}` → (3/4)
- `testSuperscriptConversion` - `x^{2}` → x²
- `testSubscriptConversion` - `x_{1}` → x₁

**Complex Cases**
- `testComplexExpression` - Multi-symbol expressions
- `testMultipleBoxedValues` - Multiple boxed values
- `testMixedContent` - LaTeX mixed with plain text
- `testNoLatex` - Plain text passthrough

### ModelConversionTests (15+ tests)

Tests for data model conversions and persistence:

**SavedModelResponse Tests**
- `testSavedModelResponseToModelResponse` - Response conversion
- `testSavedModelResponseWithError` - Error state conversion
- `testSavedModelResponseHasError` - Error detection
- `testDisplayLatency` - Latency formatting
- `testDisplayTokens` - Token count formatting

**SavedConversationMessage Tests**
- `testSavedConversationMessageToMessage` - Message conversion
- `testMessageToSavedConversationMessage` - Reverse conversion
- `testRoundTripConversion` - Bidirectional conversion

**Conversation Model Tests**
- `testConversationInitialization` - Model initialization
- `testConversationFromChatResponse` - Chat response conversion

**Model Info Tests**
- `testModelInfoIsPremium` - Premium model detection
- `testModelInfoEquality` - Model comparison

**Message Tests**
- `testMessageEquality` - Message comparison

**ModelResponse Tests**
- `testModelResponseEquality` - Response comparison
- `testModelResponseWithError` - Error state handling

## Running Tests

### Using Xcode

1. **Open the project:**
   ```bash
   open CORO.xcodeproj
   ```

2. **Run all tests:**
   - Press `Cmd + U`
   - Or: Product → Test in the menu

3. **Run specific test file:**
   - Click the diamond icon next to the test class
   - Or: `Cmd + Ctrl + Option + U` with cursor in test

4. **Run single test:**
   - Click the diamond icon next to the test method

### Using Command Line

```bash
# Run all tests
xcodebuild test \
  -project CORO.xcodeproj \
  -scheme CORO \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests with code coverage
xcodebuild test \
  -project CORO.xcodeproj \
  -scheme CORO \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES

# Run specific test class
xcodebuild test \
  -project CORO.xcodeproj \
  -scheme CORO \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:COROTests/ChatViewModelTests
```

## Mock Services

The test suite includes mock implementations for external dependencies:

### MockAPIService
- Simulates API requests and responses
- Configurable success/failure modes
- Tracks method invocations

### MockMLXService
- Simulates on-device model inference
- Configurable responses and errors
- Tracks generation calls

## Test Best Practices

### Structure
Each test follows the Arrange-Act-Assert pattern:
```swift
func testExample() {
    // Arrange - Set up test data
    viewModel.prompt = "Test"

    // Act - Perform the action
    await viewModel.sendChatRequest()

    // Assert - Verify the outcome
    XCTAssertEqual(viewModel.viewState, .success)
}
```

### Async Testing
Async tests use Swift's async/await:
```swift
func testAsyncOperation() async {
    await viewModel.sendChatRequest()
    XCTAssertEqual(viewModel.responses.count, 1)
}
```

### MainActor Tests
UI-related tests run on MainActor:
```swift
@MainActor
final class ViewModelTests: XCTestCase {
    // Tests run on main thread
}
```

## Adding New Tests

1. **Create test file** in COROTests directory:
   ```swift
   import XCTest
   @testable import CORO

   final class MyNewTests: XCTestCase {
       func testSomething() {
           // Test code
       }
   }
   ```

2. **Add to Xcode project:**
   - File → Add Files to "CORO"
   - Select the test file
   - Ensure it's added to COROTests target

3. **Run tests** to verify

## Continuous Integration

Tests should be run automatically in CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Tests
  run: |
    xcodebuild test \
      -project CORO.xcodeproj \
      -scheme CORO \
      -destination 'platform=iOS Simulator,name=iPhone 15' \
      -enableCodeCoverage YES
```

## Test Metrics

Track these metrics for test health:
- **Test Count**: 50+ tests
- **Code Coverage**: Aim for >80%
- **Test Duration**: Keep <5 seconds per test
- **Flakiness**: Zero flaky tests

## Troubleshooting

### Tests Won't Run
- Clean build folder: `Cmd + Shift + K`
- Reset simulator: `xcrun simctl erase all`
- Rebuild project: `Cmd + B`

### Import Errors
- Ensure `@testable import CORO` is present
- Check test target membership
- Verify scheme settings include test target

### Async Test Failures
- Add proper `await` keywords
- Ensure async tests are marked `async`
- Check timeout settings

## Future Enhancements

Potential additions to the test suite:
- [ ] UI Tests for critical user flows
- [ ] Performance tests for heavy operations
- [ ] Integration tests with live API (optional)
- [ ] Snapshot tests for UI components
- [ ] Accessibility tests
