# MLX Swift Setup Instructions

## Add MLX Swift Package to Xcode

1. **Open CORO.xcodeproj in Xcode**

2. **Add Swift Package:**
   - Select the CORO project in the navigator (top item)
   - Select the CORO target
   - Go to "Package Dependencies" tab
   - Click the "+" button

3. **Add MLX Swift:**
   - Enter package URL: `https://github.com/ml-explore/mlx-swift`
   - Click "Add Package"
   - Select version: "Up to Next Major Version" with 0.18.0 or later
   - Click "Add Package"

4. **Add MLX Swift Examples (for LLM support):**
   - Click "+" again
   - Enter package URL: `https://github.com/ml-explore/mlx-swift-examples`
   - Click "Add Package"
   - Select version: "Up to Next Major Version" with latest
   - Select these libraries to add:
     - **LLM** (this is the main one we need)
   - Click "Add Package"

5. **Verify Installation:**
   - Build the project (Cmd+B)
   - You should see MLX, MLXNN, MLXRandom, and LLM in the package dependencies

## Download Model

The quantized Llama 3.2 1B model will be downloaded automatically on first use, or you can pre-download it:

**Model Location:**
- HuggingFace: `mlx-community/Llama-3.2-1B-Instruct-4bit`
- Size: ~600MB
- Auto-downloads to app's documents directory

---

Once packages are added, the code will automatically work!
