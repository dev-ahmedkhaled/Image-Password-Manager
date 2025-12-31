# encode_to_image Documentation

## Overview
This function **hides encrypted data inside an image** using DCT steganography. It combines DCT transformation, data embedding, and image reconstruction into one complete workflow.

---

## What This Function Does

**In simple terms**: Takes your encrypted password data and invisibly hides it inside a normal-looking image (like a photo of nature).

**Analogy**: Like hiding a secret message written in invisible ink on a postcard. The postcard looks completely normal, but the message is there if you know how to look for it.

---

## Function Signature

```octave
function [stego_image, stego_image_path] = encode_to_image(ciphertext, cover_image_path, output_path)
```

### Parameters

**`ciphertext`** (string, required)
- Encrypted Base64 string from `encode_json_to_ciphertext`
- Example: `"U2FsdGVkX1+8vN2Ks8QfG..."`
- Will be converted to bytes and hidden in image

**`cover_image_path`** (string, required)
- Path to the "cover" image (innocent-looking image)
- Example: `"images/nature.jpg"`
- Can be JPG, PNG, BMP, etc.

**`output_path`** (string, optional)
- Where to save the stego image
- Default: Adds `_stego` to original filename
- Example: `"nature.jpg"` → `"nature_stego.png"`

### Returns
**`stego_image`** (matrix)
- The image with hidden data (as pixel matrix)

**`stego_image_path`** (string)
- Full path where stego image was saved

---

## Complete Workflow

### The Big Picture
```
Cover Image → DCT → Embed Ciphertext → Inverse DCT → Stego Image
   (JPEG)              (modify coeffs)               (PNG with hidden data)
```

---

## Step-by-Step Process

### Step 0: Setup Module Paths
```octave
% Find and add modules directory
if exist("modules/dct_transform.m", "file")
    addpath("modules");
end
```

**Why this is needed**:
- Octave needs to know where `imageToDCT`, `embedData`, etc. are located
- The function tries multiple common locations
- Adds the path so functions are accessible

---

### Step 1: Handle Default Output Path
```octave
if nargin < 3 || isempty(output_path)
    [pathstr, name, ext] = fileparts(cover_image_path);
    output_path = fullfile(pathstr, [name, "_stego", ext]);
end
```

**Example transformations**:
```
Input:  "images/nature.jpg"
Output: "images/nature_stego.jpg" (auto-generated)

Input:  "photo.png"
Output: "photo_stego.png"
```

---

### Step 2: Validate Inputs
```octave
if ~exist(cover_image_path, 'file')
    error("Cover image not found at '%s'", cover_image_path);
end

if isempty(ciphertext)
    error("Ciphertext is empty!");
end
```

**Checks**:
- ✓ Cover image exists
- ✓ Ciphertext is not empty
- ✓ Stops with clear error if validation fails

---

### Step 3: Prepare Ciphertext Data
```octave
ciphertext = strtrim(ciphertext);  % Remove whitespace
fprintf('Ciphertext length: %d characters\n', length(ciphertext));

% Convert Base64 string to uint8 bytes
ciphertext_bytes = uint8(ciphertext(:));
```

**What's happening**:
```
Input:  "U2FsdGVk..." (string)
        ↓
Clean:  "U2FsdGVk..." (trimmed)
        ↓
Output: [85, 50, 70, 115, 100, 71, 86, 114, ...] (ASCII byte array)
```

**Why keep it as ASCII bytes?**
- Preserves the Base64 string exactly
- Later decryption needs the exact Base64 string
- Each character becomes one byte (easy to embed and extract)

---

### Step 4: Convert Image to DCT Domain
```octave
fprintf('\nStep 1: Converting image to DCT domain...\n');
dctCoeffs = imageToDCT(abs_cover_path);
```

**What happens internally**:
1. Load image from file
2. Convert to grayscale if needed
3. Resize to multiple of 8
4. Split into 8×8 blocks
5. Apply DCT to each block

**Result**: `dctCoeffs` structure
```octave
dctCoeffs.blocks    % 8×8×N array (N = number of blocks)
dctCoeffs.rows      % Image height
dctCoeffs.cols      % Image width
dctCoeffs.originalImage  % Grayscale pixel data
```

---

### Step 5: Embed Ciphertext in DCT Coefficients
```octave
fprintf('\nStep 2: Embedding ciphertext into DCT coefficients...\n');
modifiedDCT = embedData(dctCoeffs, ciphertext_bytes);
```

**What happens**:
1. Convert bytes to bits: `[85, 50, ...]` → `[0,1,0,1,0,1,0,1,...]`
2. Create 8-byte header with magic number and data length
3. Combine header + data bits
4. For each bit:
   - Find mid-frequency coefficient in DCT block
   - Quantize coefficient (divide by Q=15, round)
   - Make quantized value odd (for bit 1) or even (for bit 0)
   - Update coefficient

**Modified DCT**: Contains hidden data in mid-frequency coefficients

---

### Step 6: Reconstruct Stego Image
```octave
fprintf('\nStep 3: Reconstructing stego image...\n');
stego_image = dctToImage(modifiedDCT);
```

**What happens**:
1. Apply inverse DCT to each modified block
2. Reassemble blocks into full image
3. Clamp pixel values to 0-255 range

**Result**: Image that looks nearly identical to original but contains hidden data

---

### Step 7: Calculate Quality Metrics
```octave
fprintf('\nStep 4: Calculating quality metrics...\n');
original_processed = dctCoeffs.originalImage;
metrics = calculateQualityMetrics(
    double(original_processed),
    double(stego_image)
);
```

**Metrics calculated**:
- **MSE** (Mean Squared Error): Average pixel difference squared
- **PSNR** (Peak Signal-to-Noise Ratio): Quality measure in dB

**Typical values**:
```
MSE:  0.15 to 2.0 (lower is better)
PSNR: 40-50 dB (higher is better)
```

**Quality interpretation**:
- PSNR > 40 dB: Excellent (changes invisible)
- PSNR > 30 dB: Good (minor differences)
- PSNR < 30 dB: Poor (visible artifacts)

---

### Step 8: Save Stego Image
```octave
fprintf('\nStep 5: Saving stego image...\n');

% Force PNG format (lossless)
[~, ~, ext] = fileparts(output_path);
if ~strcmpi(ext, '.png')
    output_path = strrep(output_path, ext, '.png');
end

% Prepare and save
stego_image = max(0, min(255, stego_image));  % Clamp
stego_image = uint8(stego_image);             % Convert to 8-bit
imwrite(stego_image, output_path, 'png');
```

**Why PNG?**
```
JPEG: Lossy compression → Destroys hidden data ❌
PNG:  Lossless compression → Preserves hidden data ✓
BMP:  No compression → Also works but large files
```

---

## The Math Behind It

### 1. Ciphertext to Bytes Conversion
```
ASCII string:  "U2FsdGVk"
              ↓
ASCII codes:  [85, 50, 70, 115, 100, 71, 86, 107]
              ↓
Binary bits:  01010101 00110010 01000110 ...
```

---

### 2. DCT Transformation
For each 8×8 pixel block:
```
Pixels:     DCT Coefficients:
[150 150]   [1200.5  -10.2]
[150 150]   [ -15.3    2.1]
   ...           ...
```

**Formula**:
```
DCT[u,v] = Σ Σ pixel[x,y] × cos(...) × cos(...)
```

---

### 3. Quantization-Based Embedding
```
Original coefficient: 127.5

Step 1: Quantize
quantized = round(127.5 / 15) = round(8.5) = 9

Step 2: Embed bit
To hide '0': Make even → quantized = 8
To hide '1': Keep odd  → quantized = 9

Step 3: Reconstruct
new_coefficient = quantized × 15 = 135
```

**Change in image**:
```
Coefficient changed: 127.5 → 135
Pixel value change: ~1-2 pixels (invisible to human eye)
```

---

### 4. Inverse DCT
Converts frequency coefficients back to pixels:
```
DCT Coefficients → Inverse DCT → Reconstructed Pixels
[1200.5, -10.2]                  [150, 151, 149, ...]
```

**Formula**:
```
pixel[x,y] = Σ Σ DCT[u,v] × cos(...) × cos(...)
```

---

## Capacity Calculation

For a 512×512 image:
```
Blocks: (512÷8) × (512÷8) = 64 × 64 = 4,096 blocks

Bits per block: 14 mid-frequency positions

Total capacity: 4,096 × 14 = 57,344 bits
              = 7,168 bytes
              = ~7 KB

After 8-byte header: ~7,160 bytes for actual data
```

**Rule of thumb**: Image can hide approximately 1 byte per 64 pixels

---

## Usage Examples

### Example 1: Basic Usage
```octave
% Step 1: Encrypt data
ciphertext = encode_json_to_ciphertext('secrets.json', 'master.txt');

% Step 2: Hide in image
[stego_img, path] = encode_to_image(ciphertext, 'photos/beach.jpg');

% Result: beach_stego.png contains hidden passwords
```

---

### Example 2: Custom Output Path
```octave
ciphertext = encode_json_to_ciphertext('data.json', 'pass.txt');

[stego_img, path] = encode_to_image(
    ciphertext,
    'images/nature.jpg',
    'output/secret_vault.png'  % Custom path
);

fprintf('Saved to: %s\n', path);
```

---

### Example 3: Complete Workflow
```octave
% Create password data
passwords = struct(
    'entries', {{
        struct('title', 'Email', 'password', 'Pass123')
    }}
);

% Save to JSON
json_str = jsonencode(passwords);
fid = fopen('temp.json', 'w');
fprintf(fid, '%s', json_str);
fclose(fid);

% Encrypt
cipher = encode_json_to_ciphertext('temp.json', 'MyMasterPass');
fprintf('Encrypted: %d chars\n', length(cipher));

% Hide in image
[img, path] = encode_to_image(cipher, 'cover.jpg');
fprintf('Hidden in: %s\n', path);

% Clean up
delete('temp.json');
```

---

### Example 4: Checking Capacity
```octave
% Check if data will fit
cover_img = imread('photo.jpg');
[rows, cols, ~] = size(cover_img);

% Calculate capacity
blocks = floor(rows/8) * floor(cols/8);
capacity_bytes = floor((blocks * 14) / 8) - 8;  % Subtract header

fprintf('Image: %dx%d\n', rows, cols);
fprintf('Capacity: %d bytes (%.1f KB)\n', capacity_bytes, capacity_bytes/1024);

% Check ciphertext size
cipher = encode_json_to_ciphertext('data.json', 'pass.txt');
fprintf('Data size: %d bytes\n', length(cipher));

if length(cipher) <= capacity_bytes
    fprintf('✓ Data will fit!\n');
    [img, path] = encode_to_image(cipher, 'photo.jpg');
else
    fprintf('✗ Data too large! Need larger image.\n');
end
```

---

## Error Handling

### Common Errors

**1. "Cover image not found"**
```
Error: Cover image not found at 'images/missing.jpg'
```
**Solution**: Check file path and spelling

---

**2. "Ciphertext is empty!"**
```
Error: Ciphertext is empty!
```
**Solution**: Ensure encryption was successful

---

**3. "Data too large!"**
```
Error: Data too large! Need 80000 bits but capacity is 57344 bits
```
**Solutions**:
- Use larger cover image
- Compress your data
- Use multiple images

---

**4. "Cannot find dct_transform.m"**
```
Error: imageToDCT function not accessible.
```
**Solution**: Ensure modules folder exists and contains required files
```bash
ls modules/dct_transform.m
ls modules/steganography.m
```

---

**5. Quality Degradation**
```
Quality: Poor (visible differences)
PSNR: 25.3 dB
```
**Causes**:
- Q value too high (making large changes)
- Too much data for image size
- Image already compressed

---

## Quality Optimization

### Choosing the Right Cover Image

**Good cover images**:
- ✓ Complex textures (nature, crowds)
- ✓ Varied colors and patterns
- ✓ Large size (more capacity)
- ✓ High quality (uncompressed)

**Bad cover images**:
- ✗ Solid colors (changes more visible)
- ✗ Simple patterns
- ✗ Small images (low capacity)
- ✗ Already heavily compressed

---

### Example Quality Comparison

**Image 1: Nature photo (1024×768)**
```
Capacity: 10.5 KB
PSNR: 47.2 dB (Excellent)
Visual difference: None
```

**Image 2: Blue sky (512×512)**
```
Capacity: 7 KB
PSNR: 31.8 dB (Good)
Visual difference: Slight banding
```

**Image 3: White background (256×256)**
```
Capacity: 1.75 KB
PSNR: 22.1 dB (Poor)
Visual difference: Visible noise
```

---

## File Format Recommendations

### Input (Cover Image)
- **Best**: PNG, BMP (uncompressed)
- **Good**: High-quality JPEG (90%+)
- **Avoid**: Low-quality JPEG, GIF

### Output (Stego Image)
- **Must use**: PNG ✓
- **Never use**: JPEG ✗ (lossy compression destroys data)

**The script enforces PNG output**:
```octave
if ~strcmpi(ext, '.png')
    warning('Output must be PNG for lossless storage...');
    output_path = strrep(output_path, ext, '.png');
end
```

---

## Performance Notes

### Encoding Speed

For a 512×512 image:
```
Step 1: DCT transformation    → 0.5 seconds
Step 2: Data embedding        → 0.1 seconds
Step 3: Inverse DCT           → 0.5 seconds
Step 4: Quality metrics       → 0.1 seconds
Step 5: Save image            → 0.2 seconds
────────────────────────────────────────────
Total:                         ~1.4 seconds
```

**Scaling**:
- 1024×1024: ~5 seconds
- 2048×2048: ~20 seconds
- Time ≈ O(pixels × log(pixels))

---

## Security Considerations

### What This Function Secures
- ✓ Hidden data is invisible
- ✓ Statistical properties preserved
- ✓ Works with already-encrypted data

### What This Function Doesn't Secure
- ✗ Doesn't encrypt (assumes input is encrypted)
- ✗ Anyone with the extraction code can get data
- ✗ Not resistant to image manipulation

**Best practice**: Always encrypt before embedding!

---

## Visual Comparison Tool

```octave
function show_comparison(original_path, stego_path)
    orig = imread(original_path);
    steg = imread(stego_path);
    
    % Show side by side
    figure;
    subplot(1,3,1);
    imshow(orig);
    title('Original');
    
    subplot(1,3,2);
    imshow(steg);
    title('With Hidden Data');
    
    subplot(1,3,3);
    imshow(abs(double(orig) - double(steg)) * 10);  % Amplify differences
    title('Difference (×10)');
    colorbar;
end
```

---

## Troubleshooting Guide

### Problem: PSNR too low (< 30 dB)

**Solutions**:
1. Reduce Q value in steganography.m (less robust but better quality)
2. Use larger image (more blocks to spread data)
3. Compress input data before encryption

---

### Problem: Can't extract data later

**Causes**:
- Image saved as JPEG (use PNG!)
- Image was resized
- Image went through social media (compression)

---

### Problem: "embedData function not found"

**Solution**:
```octave
% Manually add path and run
addpath('modules');
run('modules/steganography.m');
```

---

## Summary

**Complete workflow**:
```
JSON → Encrypt → Base64 → ASCII bytes → Embed in DCT → Save PNG
```

**What this function does**:
1. ✅ Converts ciphertext to bytes
2. ✅ Transforms image to DCT domain
3. ✅ Embeds data in mid-frequencies
4. ✅ Reconstructs stego image
5. ✅ Calculates quality metrics
6. ✅ Saves as lossless PNG

**Output**: Normal-looking image with invisible hidden data

**Key requirement**: Always save output as PNG!