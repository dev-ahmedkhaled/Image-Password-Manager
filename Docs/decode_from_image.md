# decode_from_image Documentation

## Overview
This function **extracts hidden encrypted data from a stego image**. It's the reverse of `encode_to_image` and recovers the ciphertext that was embedded in the image's DCT coefficients.

---

## What This Function Does

**In simple terms**: Takes an image that looks normal but contains hidden data, and pulls out the secret encrypted text.

**Analogy**: Like using a UV light to reveal invisible ink on a postcard - the postcard looks normal to everyone else, but you can see the hidden message.

---

## Function Signature

```octave
function ciphertext = decode_from_image(stego_image_path)
```

### Parameters

**`stego_image_path`** (string, required)
- Path to the image containing hidden data
- Example: `"images/nature_stego.png"`
- Must be the stego image created by `encode_to_image`

### Returns
**`ciphertext`** (string)
- Extracted Base64-encoded encrypted string
- Example: `"U2FsdGVkX1+8vN2Ks8QfG..."`
- Ready to be decrypted with `decode_from_ciphertext`

---

## Complete Workflow

### The Big Picture
```
Stego Image → DCT → Extract bits → Convert to bytes → Base64 ciphertext
  (PNG)                 (read coeffs)                     (encrypted data)
```

---

## Step-by-Step Process

### Step 0: Setup Module Paths
```octave
% Try to find and add modules directory
if exist("modules/dct_transform.m", "file")
    addpath("modules");
end
```

**Why this matters**:
- Needs access to `imageToDCT` and `extractData` functions
- Tries multiple common locations
- Adds modules path if found

---

### Step 1: Validate Input
```octave
if ~exist(stego_image_path, 'file')
    error("Stego image not found at '%s'", stego_image_path);
end

fprintf('Stego image: %s\n', stego_image_path);
```

**Check**: File exists before attempting to read

---

### Step 2: Convert Image to DCT Domain
```octave
fprintf('\nStep 1: Converting stego image to DCT domain...\n');
dctCoeffs = imageToDCT(stego_image_path);
```

**What happens internally**:
1. Load image from file
2. Convert to grayscale
3. Resize to multiple of 8 (if needed)
4. Split into 8×8 blocks
5. Apply DCT to each block

**Result**: DCT coefficients that contain hidden data

---

### Step 3: Extract Embedded Data
```octave
fprintf('\nStep 2: Extracting embedded data from DCT coefficients...\n');
extracted_bytes = extractData(dctCoeffs);
```

**What `extractData` does**:

1. **Extract header (64 bits)**
   ```
   First 64 bits → 8 bytes header
   [80, 65, 83, 83, length_bytes...]
   ```

2. **Verify magic number**
   ```
   Check if first 4 bytes = [80, 65, 83, 83] ("PASS")
   If not → Error: "Magic number not found!"
   ```

3. **Read data length**
   ```
   Bytes 5-8 → uint32 → number of data bytes
   Example: [232, 3, 0, 0] → 1000 bytes
   ```

4. **Extract data bits**
   ```
   Total bits = (8 × 8) + (dataLength × 8)
   Extract bits from DCT mid-frequency positions
   ```

5. **Convert bits to bytes**
   ```
   Bits: [0,1,0,1,0,1,0,1, 0,0,1,1,0,0,1,0, ...]
         └─────┬─────┘  └─────┬─────┘
           Byte 1         Byte 2
   ```

---

### Step 4: Convert Bytes to String
```octave
% Ensure row vector for char conversion
if size(extracted_bytes, 1) > size(extracted_bytes, 2)
    extracted_bytes = extracted_bytes';
end

ciphertext = char(extracted_bytes);
ciphertext = strtrim(ciphertext);  % Remove trailing nulls
```

**Conversion**:
```
Bytes:  [85, 50, 70, 115, 100, 71, 86, 107]
        ↓
Chars:  ['U', '2', 'F', 's', 'd', 'G', 'V', 'k']
        ↓
String: "U2FsdGVk" (Base64 ciphertext)
```

---

## The Math Behind Extraction

### 1. DCT Transformation
For each 8×8 block in the stego image:
```
Pixels:         DCT Coefficients:
[151 150]   →   [1200.5  -15.0]  ← Modified by embedding
[149 150]       [   0.0    2.1]  ← Modified by embedding
```

---

### 2. Quantization-Based Extraction
For each mid-frequency position:
```
Step 1: Get coefficient
coeff = -15.0

Step 2: Quantize (Q=15, must match embedding)
quantized = round(-15.0 / 15) = round(-1) = -1

Step 3: Check odd/even
abs(-1) = 1 (odd) → bit = 1

Step 4: Store bit
extracted_bits[i] = 1
```

**Extraction rule**:
```
If |quantized| is odd  → bit = 1
If |quantized| is even → bit = 0
```

---

### 3. Mid-Frequency Positions
Data is extracted from the same 14 positions per block:
```
8×8 DCT Block:
[DC  *   *   *   .   .   .   .]
[ *  *   *   .   .   .   .   .]
[ *  *   .   .   .   .   .   .]
[ *  .   .   .   .   .   .   .]
[ .  .   .   .   .   .   .   .]
[                              ]

* = Extraction positions (14 total)
DC = Skipped (DC coefficient)
. = Not used (high frequencies)
```

Specific positions:
```
[1,2], [2,1], [3,1], [2,2], [1,3], [1,4],
[2,3], [3,2], [4,1], [5,1], [4,2], [3,3],
[2,4], [1,5]
```

---

### 4. Bits to Bytes Conversion
```octave
% For every 8 bits, construct a byte
bits = [0,1,0,1,0,1,0,1]  % Example
      
byte = 0
for bit_position = 0 to 7
    if bits[position] == 1
        byte = byte | (1 << (7 - position))

Result: byte = 85 (ASCII 'U')
```

**Full example**:
```
Bits:  [0,1,0,1,0,1,0,1, 0,0,1,1,0,0,1,0, 0,1,0,0,0,1,1,0]
       └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
         85 ('U')          50 ('2')          70 ('F')

String: "U2F"
```

---

## Header Structure

### The 8-Byte Header
```
Byte 0-3: Magic Number [80, 65, 83, 83]
Byte 4-7: Data Length (uint32, little-endian)
```

**Example header**:
```
[80, 65, 83, 83, 232, 3, 0, 0]
 │   │   │   │    └─────┬─────┘
 └───┴───┴───┘          │
   "PASS"         1000 (0x03E8)
```

**Why verify magic number?**
- Confirms image contains hidden data
- Prevents extracting garbage from normal images
- Acts as a signature

---

## Usage Examples

### Example 1: Basic Extraction
```octave
% Extract ciphertext from stego image
ciphertext = decode_from_image('images/vault_stego.png');

% Decrypt
plaintext = decode_from_ciphertext(ciphertext, 'master_password.txt');

% Parse JSON
data = jsondecode(plaintext);
fprintf('Found %d passwords\n', length(data.entries));
```

---

### Example 2: Complete Recovery Workflow
```octave
% Step 1: Extract from image
fprintf('Extracting hidden data...\n');
cipher = decode_from_image('secret_vault.png');
fprintf('Ciphertext length: %d chars\n', length(cipher));

% Step 2: Decrypt
fprintf('Decrypting...\n');
json_str = decode_from_ciphertext(cipher, 'MyMasterPass');

% Step 3: Parse and use
passwords = jsondecode(json_str);
for i = 1:length(passwords.entries)
    entry = passwords.entries(i);
    fprintf('%s: %s\n', entry.title, entry.password);
end
```

---

### Example 3: Testing Multiple Images
```octave
function test_extraction()
    images = {'vault1.png', 'vault2.png', 'vault3.png'};
    
    for i = 1:length(images)
        try
            fprintf('\nTesting %s...\n', images{i});
            cipher = decode_from_image(images{i});
            fprintf('✓ Success: %d bytes\n', length(cipher));
        catch ME
            fprintf('✗ Failed: %s\n', ME.message);
        end
    end
end
```

---

### Example 4: Verify Before Extracting
```octave
function cipher = safe_extract(image_path, expected_magic)
    % Extract
    cipher = decode_from_image(image_path);
    
    % Extra validation (optional)
    if nargin > 1
        % Check if ciphertext starts correctly
        if ~startsWith(cipher, expected_magic)
            error('Extracted data does not match expected format');
        end
    end
    
    fprintf('Extraction successful!\n');
end

% Usage
cipher = safe_extract('vault.png', 'U2FsdGVk');  % Base64 for "Salted__"
```

---

## Error Handling

### Common Errors

**1. "Stego image not found"**
```
Error: Stego image not found at 'images/missing.png'
```
**Solution**: Check file path and ensure file exists

---

**2. "Magic number not found!"**
```
Error: Magic number not found! This image may not contain hidden data.
```

**Causes**:
- Image doesn't contain hidden data
- Wrong image file
- Image was compressed (JPEG) after embedding
- Image was resized/modified

**Debug**:
```octave
% Check what was extracted
extracted_bytes = extractData(dctCoeffs);
fprintf('First 4 bytes: %d %d %d %d\n', extracted_bytes(1:4));
fprintf('Expected: 80 65 83 83\n');
```

---

**3. "Data length is unrealistic"**
```
Error: Data length: 2147483647 bytes  % Too large!
```

**Causes**:
- Magic number matched by chance (random data)
- Image was modified
- Wrong Q value in steganography.m

---

**4. Extracted ciphertext is gibberish**
```
Ciphertext: "�%$#@!..."  % Random characters
```

**Causes**:
- Image underwent lossy compression
- DCT coefficients were modified
- Q value mismatch between embed and extract

---

## Validation and Debugging

### Debug Mode
```octave
function ciphertext = decode_from_image_debug(stego_image_path)
    fprintf('\n=== DEBUG MODE ===\n');
    
    % Step 1: Load and convert
    dctCoeffs = imageToDCT(stego_image_path);
    fprintf('Image size: %dx%d\n', dctCoeffs.rows, dctCoeffs.cols);
    fprintf('Num blocks: %d\n', size(dctCoeffs.blocks, 3));
    
    % Step 2: Extract and verify header
    extracted_bytes = extractData(dctCoeffs);
    fprintf('\nExtracted header:\n');
    fprintf('  Magic: [%d %d %d %d]\n', extracted_bytes(1:4));
    fprintf('  Expected: [80 65 83 83]\n');
    
    length_bytes = extracted_bytes(5:8);
    data_length = typecast(uint8(length_bytes), 'uint32');
    fprintf('  Data length: %d bytes\n', data_length);
    
    % Step 3: Convert to string
    ciphertext = char(extracted_bytes');
    ciphertext = strtrim(ciphertext);
    
    fprintf('\nCiphertext preview: %s...\n', ciphertext(1:min(50,end)));
    fprintf('Total length: %d chars\n', length(ciphertext));
end
```

---

### Verify Image Integrity
```octave
function is_valid = check_stego_image(image_path)
    is_valid = false;
    
    try
        % Try extraction
        dctCoeffs = imageToDCT(image_path);
        extracted = extractData(dctCoeffs);
        
        % Check magic number
        magic = extracted(1:4);
        expected = [80, 65, 83, 83];
        
        if isequal(magic', expected)
            fprintf('✓ Valid stego image\n');
            is_valid = true;
        else
            fprintf('✗ Invalid magic number\n');
        end
        
    catch ME
        fprintf('✗ Extraction failed: %s\n', ME.message);
    end
end
```

---

## Performance

### Extraction Speed

For a 512×512 image:
```
Step 1: Load and DCT       → 0.5 seconds
Step 2: Extract bits       → 0.1 seconds
Step 3: Convert to string  → 0.01 seconds
─────────────────────────────────────────
Total:                      ~0.6 seconds
```

**Scaling**:
- 1024×1024: ~2.5 seconds
- 2048×2048: ~10 seconds

---

## Comparison: Encode vs Decode

| Operation | Encode | Decode |
|-----------|--------|--------|
| Input | Ciphertext string | Stego image |
| Process | Embed bits | Extract bits |
| DCT | Forward DCT | Forward DCT |
| Quantization | Modify coeffs | Read coeffs |
| Output | Stego image | Ciphertext string |
| Time | ~1.4 sec | ~0.6 sec |

---

## Image Format Requirements

### Supported Input Formats
- **PNG**: ✓ Best (lossless)
- **BMP**: ✓ Also lossless
- **JPEG**: ⚠️ Only if high quality AND unmodified
- **GIF**: ✗ May lose data

### Why PNG is Critical
```
Stego Image (PNG):  DCT coeffs preserved → Extraction works ✓
After JPEG save:    DCT coeffs changed   → Extraction fails ✗
After resize:       Blocks misaligned    → Extraction fails ✗
```

---

## Security Considerations

### What Gets Revealed
- ✓ Ciphertext only (still encrypted)
- ✗ NOT the original passwords
- ✗ NOT the master password

### Steganography ≠ Encryption
```
Without decryption password:
Extracted data = "U2FsdGVkX1..." (gibberish)

With decryption password:
Extracted data → Decrypt → Passwords revealed
```

**Bottom line**: Even if someone extracts the ciphertext, they still need your master password to decrypt it.

---

## Troubleshooting Guide

### Problem: Magic number mismatch

**Check 1**: Verify it's a stego image
```octave
% Try viewing the image
img = imread('suspected_stego.png');
imshow(img);
% Does it look like the one you created?
```

**Check 2**: Check file hasn't been modified
```octave
% Compare file sizes
info_original = dir('original_stego.png');
info_current = dir('current_image.png');
fprintf('Original: %d bytes\n', info_original.bytes);
fprintf('Current:  %d bytes\n', info_current.bytes);
```

---

### Problem: Ciphertext looks wrong

**Symptoms**:
```
Expected: "U2FsdGVkX1..."  (Base64)
Got:      "��#@%$..."      (garbage)
```

**Solutions**:
1. Verify Q value matches in `steganography.m`:
   ```octave
   Q = 15;  % Must be same for embed and extract
   ```

2. Check if image was compressed:
   ```octave
   info = imfinfo('stego.png');
   fprintf('Format: %s\n', info.Format);  % Should be PNG
   ```

3. Try extracting from original stego image:
   ```bash
   # Find original
   ls -la *stego*.png
   ```

---

## Advanced: Manual Extraction

### Extract Specific Blocks
```octave
function show_extraction_process(image_path)
    dctCoeffs = imageToDCT(image_path);
    midFreqPos = getMidFrequencyPositions();
    Q = 15;
    
    % Extract from first 3 blocks
    for b = 1:3
        block = dctCoeffs.blocks(:,:,b);
        fprintf('\nBlock %d:\n', b);
        
        for p = 1:min(5, size(midFreqPos,1))
            row = midFreqPos(p,1);
            col = midFreqPos(p,2);
            coeff = block(row,col);
            quantized = round(coeff / Q);
            bit = mod(abs(quantized), 2);
            
            fprintf('  Pos[%d,%d]: coeff=%.2f, quant=%d, bit=%d\n', ...
                    row, col, coeff, quantized, bit);
        end
    end
end
```

---

## Summary

**Complete workflow**:
```
PNG stego image → DCT → Extract bits → Bytes → Base64 string → Decrypt → JSON
```

**What this function does**:
1. ✅ Loads stego image
2. ✅ Converts to DCT domain
3. ✅ Extracts bits from mid-frequencies
4. ✅ Verifies magic number
5. ✅ Converts bytes to ciphertext string

**Output**: Encrypted Base64 ciphertext (ready for decryption)

**Key requirement**: Image must be unmodified PNG from `encode_to_image`