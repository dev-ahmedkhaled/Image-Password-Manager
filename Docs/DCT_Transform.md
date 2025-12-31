# DCT Transform Module Documentation

## Overview
This module handles **DCT (Discrete Cosine Transform)** operations on images. DCT is a mathematical technique that converts images into frequency components, similar to how music can be broken down into different notes.

---

## What is DCT?

Think of an image as a collection of patterns - some patterns change quickly (like sharp edges), and some change slowly (like smooth gradients). DCT separates these patterns into different "frequencies":

- **Low frequencies** = Smooth, gradual changes (most important visual information)
- **Mid frequencies** = Moderate details
- **High frequencies** = Sharp edges and fine details

---

## Main Functions

### 1. `manual_dctmtx(n)`
**Purpose**: Creates a transformation matrix for DCT calculations

**How it works**:
```
T = sqrt(2/n) * cos(π * (2*cols + 1) * rows / (2*n))
```

**Simple explanation**: 
- Creates an 8×8 special matrix filled with cosine values
- This matrix is like a "translator" that converts pixel values into frequency values
- The first row is divided by √2 for normalization (mathematical balancing)

**Returns**: An 8×8 transformation matrix

---

### 2. `imageToDCT(imagePath)`
**Purpose**: Converts an entire image into DCT coefficients

**Steps**:
1. **Load the image** from the file path
2. **Convert to grayscale** if it's colored (RGB → single channel)
3. **Resize** to make dimensions multiples of 8 (required for 8×8 blocks)
4. **Split** the image into 8×8 pixel blocks
5. **Apply DCT** to each block separately

**Why 8×8 blocks?**
- Standard size used in JPEG compression
- Good balance between efficiency and quality
- Each block can be processed independently

**Returns**: A structure containing:
- `blocks`: DCT coefficients for all 8×8 blocks
- `rows`, `cols`: Image dimensions
- `originalImage`: The processed grayscale image

---

### 3. `blockDCT(img)`
**Purpose**: Applies DCT transformation to each 8×8 block

**Math formula**:
```
DCT_block = T × Block × T'
```
Where:
- `T` = DCT transformation matrix
- `Block` = 8×8 pixel values (0-255)
- `T'` = Transpose of T (flipped matrix)

**Simple explanation**:
- Takes pixel values (like 150, 200, 75...)
- Transforms them into frequency coefficients
- Top-left coefficient = average brightness (DC coefficient)
- Other coefficients = different frequency patterns

---

### 4. `blockIDCT(dctBlocks, rows, cols)`
**Purpose**: Converts DCT coefficients back into an image (Inverse DCT)

**Math formula**:
```
Block = T' × DCT_block × T
```

**Simple explanation**:
- Reverses the DCT process
- Takes frequency coefficients
- Reconstructs the original 8×8 pixel blocks
- Assembles blocks back into a complete image

---

### 5. `dctToImage(dctCoeffs)`
**Purpose**: High-level function to reconstruct the full image

**Steps**:
1. Calls `blockIDCT()` to convert all blocks
2. **Clamps values** to 0-255 range (prevents invalid pixel values)
3. Returns the reconstructed image

---

### 6. `getMidFrequencyPositions()`
**Purpose**: Returns the positions in an 8×8 DCT block where we'll hide data

**Why mid-frequencies?**
- **Low frequencies** (top-left): Too important for image quality
- **High frequencies** (bottom-right): Often removed by compression
- **Mid frequencies**: Perfect balance - can be modified without visible changes

**Returns**: 14 positions in zigzag order:
```
[1,2], [2,1], [3,1], [2,2], [1,3], [1,4]...
```

---

### 7. `calculateQualityMetrics(original, modified)`
**Purpose**: Measures how different the modified image is from the original

**Metrics calculated**:

#### MSE (Mean Squared Error)
```
MSE = average of (original_pixel - modified_pixel)²
```
- Lower MSE = Better quality (less difference)
- MSE of 0 = Perfect match

#### PSNR (Peak Signal-to-Noise Ratio)
```
PSNR = 10 × log₁₀(255² / MSE)
```
- Measured in decibels (dB)
- Higher PSNR = Better quality

**Quality interpretation**:
- **PSNR > 40 dB**: Excellent - changes are invisible
- **PSNR > 30 dB**: Good - minor differences
- **PSNR < 30 dB**: Poor - visible differences

---

## How DCT Works: Visual Example

**Original 8×8 block** (pixel values):
```
100 100 100 100 100 100 100 100
100 150 150 150 150 150 150 100
100 150 200 200 200 200 150 100
...
```

**After DCT** (frequency coefficients):
```
1200.5  -10.2   0.5   0.1  ...  (low freq → high freq)
 -15.3    2.1   0.3   0.0  ...
   0.8    0.4   0.1   0.0  ...
```

**Key observations**:
- First value (1200.5) = DC coefficient = average brightness
- Values decrease towards bottom-right (high frequencies)
- Small coefficients can be modified without affecting image quality

---

## Usage Example

```octave
% Convert image to DCT
dctCoeffs = imageToDCT('myimage.jpg');

% Access DCT blocks
block1 = dctCoeffs.blocks(:,:,1);  % First 8×8 block

% Convert back to image
reconstructed = dctToImage(dctCoeffs);

% Check quality
metrics = calculateQualityMetrics(original, reconstructed);
```

---

## Why This Module Exists

This module is the foundation for steganography (hiding data in images):
1. Convert image to frequency domain (DCT)
2. Modify mid-frequency coefficients to hide data
3. Convert back to pixel domain
4. Result: Image looks the same, but contains hidden information!

---

## Technical Notes

- **Package required**: `image` (loaded with `pkg load image`)
- **Image format**: Works with grayscale images
- **Block size**: Fixed at 8×8 (industry standard)
- **Precision**: Uses `double` for accurate calculations