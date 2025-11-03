#!/bin/bash

# Script to add test files to CORO Xcode project
# This script opens Xcode and provides instructions

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_PATH="$SCRIPT_DIR/CORO.xcodeproj"
TESTS_DIR="$SCRIPT_DIR/COROTests"

echo "================================================"
echo "Adding Test Files to CORO Xcode Project"
echo "================================================"
echo ""

# Check if files exist
if [ ! -d "$TESTS_DIR" ]; then
    echo "❌ Error: COROTests directory not found!"
    exit 1
fi

# Check if Xcode project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Error: CORO.xcodeproj not found!"
    exit 1
fi

echo "✓ Found project at: $PROJECT_PATH"
echo "✓ Found tests at: $TESTS_DIR"
echo ""

# Count test files
TEST_COUNT=$(find "$TESTS_DIR" -name "*.swift" | wc -l | tr -d ' ')
echo "📝 Found $TEST_COUNT test files to add"
echo ""

# List the files
echo "Test files:"
find "$TESTS_DIR" -name "*.swift" -exec basename {} \;
echo ""

echo "================================================"
echo "Opening Xcode..."
echo "================================================"
echo ""

# Open Xcode with the project
open "$PROJECT_PATH"

sleep 2

echo "✅ Xcode should now be open!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. In Xcode, look at the left sidebar (Project Navigator)"
echo "2. Right-click on 'CORO' folder"
echo "3. Select 'Add Files to \"CORO\"...'"
echo "4. Navigate to: $TESTS_DIR"
echo "5. Select ALL files (Cmd+A) including:"
echo "   - ChatViewModelTests.swift"
echo "   - MarkdownTextTests.swift"
echo "   - ModelConversionTests.swift"
echo "   - README.md"
echo "6. ⚠️  IMPORTANT: In the dialog, ensure:"
echo "   - 'Create groups' is selected (not 'Create folder references')"
echo "   - Under 'Add to targets', CHECK 'COROTests' ONLY"
echo "   - UNCHECK 'CORO' target"
echo "7. Click 'Add'"
echo ""
echo "Then run tests with: Cmd + U"
echo ""
echo "================================================"
echo ""
echo "Or use this alternative method:"
echo "================================================"
echo ""
echo "Run this command to create a test target automatically:"
echo ""
echo "cd '$SCRIPT_DIR'"
echo "xcodebuild -project CORO.xcodeproj -list"
echo ""

# Check if test target exists
echo "Checking for test target..."
if xcodebuild -project "$PROJECT_PATH" -list 2>/dev/null | grep -q "COROTests"; then
    echo "✓ Test target 'COROTests' already exists!"
    echo ""
    echo "You can now add files through Xcode UI or run:"
    echo "./manual_add_tests.sh"
else
    echo "⚠️  Test target 'COROTests' not found!"
    echo ""
    echo "Creating test target..."
    echo ""
    echo "Unfortunately, test targets must be created through Xcode UI."
    echo "Please follow these steps in Xcode:"
    echo ""
    echo "1. File → New → Target"
    echo "2. Select 'iOS' → 'Unit Testing Bundle'"
    echo "3. Name it 'COROTests'"
    echo "4. Click 'Finish'"
    echo "5. Then run this script again to add the test files"
fi

echo ""
echo "================================================"
