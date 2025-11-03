# Final Steps to Run iOS Tests

## What I've Already Fixed

✅ Changed test target from UI Testing to Unit Testing
✅ Added Equatable conformance to ModelInfo and ModelResponse
✅ Set TEST_HOST and BUNDLE_LOADER in project configuration

## What You Need to Do (3 Minutes)

### Option 1: Run in Xcode (Recommended)

1. **If Xcode is showing that "save test plan" dialog**, click **"Don't Save"**

2. **Close Xcode completely** (Cmd + Q)

3. **Reopen the project**:
   ```bash
   open CORO.xcodeproj
   ```

4. **In Xcode**, press `Cmd + U` to run all tests
   - OR click the diamond icon next to any test class/method to run specific tests

5. **If you get the scheme error again**:
   - Click scheme dropdown → "Edit Scheme..."
   - Click "Test" in left sidebar
   - Click the "+" button below the test list
   - Select "COROTests"
   - Click "Close"
   - Try `Cmd + U` again

### Option 2: Run from Command Line

```bash
cd /Users/juanignaciobianchi/devdev/coro/CORO

# Clean build folder first
rm -rf ~/Library/Developer/Xcode/DerivedData/*CORO*

# Run tests
xcodebuild test \
  -project CORO.xcodeproj \
  -scheme CORO \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:COROTests/ChatViewModelTests_NoMLX
```

### Option 3: If All Else Fails - Use Simplified Tests Only

The file `ChatViewModelTests_NoMLX.swift` contains ~20 tests that work without MLX dependencies.

In Xcode:
1. Open `COROTests` folder in navigator
2. Click on `ChatViewModelTests_NoMLX.swift`
3. Click the diamond icon next to `class ChatViewModelTests_NoMLX`
4. These tests should run immediately

## Why This Was Complicated

The test target was created as the wrong type (UI testing instead of unit testing), which caused all those "Undefined symbol" errors. Unit tests need to:
1. Be type `bundle.unit-test` ✅ Fixed
2. Have TEST_HOST pointing to the app ✅ Fixed
3. Have BUNDLE_LOADER configured ✅ Fixed
4. Be included in the scheme's Test action ⚠️ Needs Xcode UI

## Summary

All the code-level fixes are done. You just need to either:
- Run tests in Xcode (Cmd + U), OR
- Add COROTests to the scheme if you get an error

That's it!
