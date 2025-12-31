# Steganography Module Documentation

## What is This?

This is a **steganography** program that hides secret data inside images without anyone noticing. Think of it like invisible ink for digital images!

**Steganography** = The art of hiding messages in plain sight.

---

## How It Works (Simple Explanation)

### The Big Picture

1. **Hiding Data**: Takes your secret data and embeds it into an image's DCT coefficients
2. **Extracting Data**: Reads the hidden data back out from the image
3. **Magic Number**: Uses a special code (like a password) to verify the data is there

### What is DCT?

**DCT (Discrete Cosine Transform)** is a mathematical technique that breaks an image into frequency components, similar to how music can be broken into different notes.

- **Low frequencies** = Smooth areas, basic shapes (most important for how image looks)
- **Mid frequencies** = Textures and details (where we hide data)
- **High frequencies** = Fine edges and noise (least important)

We hide data in **mid-frequency** areas because:
- They're important enough to survive compression
- They're not so important that changing them is noticeable

---

## Main Functions

### 1. `embedData(dctCoeffs, encryptedData)`

**Purpose**: Hides secret data inside an image

**Inputs**:
- `dctCoeffs` - The image's DCT coefficients (frequency data)
- `encryptedData` - Your secret data (as bytes)

**Process**:
1. Converts your data into individual bits (1s and 0s)
2. Creates a header with magic number [80, 65, 83, 83] (spells "PASS" in ASCII)
3. Checks if the image is big enough to hold your data
4. Embeds bits into mid-frequency DCT coefficients
5. Returns modified DCT coefficients

**Output**: Modified DCT data with your secret embedded

---

### 2. `extractData(dctCoeffs)`

**Purpose**: Retrieves hidden data from an image

**Inputs**:
- `dctCoeffs` - The DCT coefficients from a stego-image

**Process**:
1. Extracts bits from mid-frequency positions
2. Reads the header (first 8 bytes)
3. Checks for magic number [80, 65, 83, 83]
4. Reads data length from header
5. Extracts the actual hidden data
6. Converts bits back to bytes

**Output**: Your original secret data

---

## The Math Behind It

### Quantization Index Modulation (QIM)

This is the core technique for embedding data. Here's how it works:

#### Step 1: Quantization
```
quantized = round(coefficient / Q)
```
- **Q** = Quantization step (set to 15 for robustness)
- We divide the DCT coefficient by Q and round it
- This creates a whole number we can work with

#### Step 2: Embedding a Bit

**To embed a 1**:
- Make sure the quantized value is **odd**
- If it's even, add 1 to make it odd

**To embed a 0**:
- Make sure the quantized value is **even**
- If it's odd, subtract 1 to make it even

#### Step 3: Reconstruction
```
newCoefficient = quantized × Q
```
- Multiply back by Q to get the modified coefficient

#### Example:

Let's say we have a coefficient = 47 and Q = 15

**To embed a 1**:
```
quantized = round(47 / 15) = round(3.13) = 3
3 is odd ✓ (already correct for bit 1)
newCoefficient = 3 × 15 = 45
```

**To embed a 0**:
```
quantized = round(47 / 15) = 3
3 is odd ✗ (need even for bit 0)
quantized = 3 - 1 = 2
newCoefficient = 2 × 15 = 30
```

### Why Q = 15?

The quantization step determines robustness vs. invisibility:
- **Smaller Q** (like 5): Changes are tiny and invisible, but easily destroyed
- **Larger Q** (like 15): Changes are bigger and more robust, but potentially noticeable
- Q = 15 is a good balance for surviving JPEG compression and rounding errors

---

## Helper Functions

### `createHeader(dataLength)`

Creates an 8-byte header:
- Bytes 1-4: Magic number [80, 65, 83, 83]
- Bytes 5-8: Data length as a 32-bit integer

This header tells us:
1. "Yes, there's hidden data here" (via magic number)
2. "Here's how many bytes to extract" (via length)

---

### `bytesToBits(bytes)`

Converts bytes into individual bits.

**Example**: 
- Byte = 65 (letter 'A')
- Binary = 01000001
- Bits = [0, 1, 0, 0, 0, 0, 0, 1]

**The Math**:
```matlab
for bitPos = 7 down to 0:
    bit = bitget(byte, bitPos + 1)
```
- `bitget` extracts each bit position from the byte
- We go from most significant bit (position 7) to least significant (position 0)

---

### `bitsToBytes(bits)`

Converts bits back into bytes (reverse of above).

**Example**:
- Bits = [0, 1, 0, 0, 0, 0, 0, 1]
- Result = 65 (letter 'A')

**The Math**:
```matlab
for each 8 bits:
    if bit is 1:
        byte = bitset(byte, position)
```
- Builds each byte by setting individual bit positions

---

### `getMidFrequencyPositions()`

Returns an array of (row, column) positions in the 8×8 DCT block that correspond to mid-frequency coefficients.

**Why Mid-Frequency?**
- **Low frequency** (top-left): Most visually important - don't touch!
- **Mid frequency** (diagonal band): Good hiding spot
- **High frequency** (bottom-right): Easily lost in compression

---

## Key Constants

### `MAGIC_NUMBER = [80, 65, 83, 83]`
- ASCII codes for "PASS"
- Used to verify that hidden data exists
- Like a secret handshake!

### `HEADER_SIZE = 8`
- 8 bytes for the header
- 4 bytes for magic number + 4 bytes for data length

### `Q = 15`
- Quantization step size
- Determines robustness of embedding
- Higher = more robust but less invisible
- Must match between embedding and extraction!

---

## Capacity Calculation

```
Capacity = Number of Blocks × Bits per Block
```

- **Number of Blocks**: How many 8×8 blocks in the image
- **Bits per Block**: How many mid-frequency positions we use (usually 10-20)

**Example**:
- 512×512 image = 64×64 = 4,096 blocks
- 15 bits per block
- Capacity = 4,096 × 15 = 61,440 bits = 7,680 bytes

---

## Error Handling

### "Data too large!"
Your secret data doesn't fit in the image. Solutions:
- Use a bigger image
- Compress your data first
- Encrypt with a more compact format

### "Magic number not found!"
The image doesn't contain hidden data, or:
- Wrong decryption key was used
- Image was modified too much
- Q value doesn't match between embed and extract

---

## Security Features

1. **Magic Number**: Prevents false positives (thinking random images have data)
2. **Encryption Expected**: Data should be encrypted before hiding
3. **Mid-Frequency Hiding**: Makes data hard to detect statistically
4. **Robustness**: Q = 15 allows data to survive JPEG compression

---

## Tips for Best Results

1. **Use PNG or BMP images**: JPEG compression may damage hidden data
2. **Larger images**: More capacity for your data
3. **Encrypt first**: Always encrypt sensitive data before hiding
4. **Match Q values**: Use the same Q when embedding and extracting
5. **Test extraction**: Always verify data can be extracted correctly

---

## Common Questions

**Q: Can I see the difference in the image?**  
A: Usually no! The changes are in mid-frequency coefficients that are imperceptible to human eyes.

**Q: Will this survive JPEG compression?**  
A: With Q = 15, it should survive moderate JPEG compression, but not aggressive compression.

**Q: How much data can I hide?**  
A: Depends on image size. A 512×512 image can typically hold 5-10 KB of data.

**Q: Is this secure?**  
A: The hiding is secure, but always encrypt your data first! This module expects pre-encrypted data.

---

## Technical Summary

**Algorithm**: Quantization Index Modulation (QIM)  
**Domain**: DCT (Discrete Cosine Transform)  
**Embedding Location**: Mid-frequency coefficients  
**Robustness**: Q = 15 (moderate)  
**Capacity**: ~1-2 bits per DCT coefficient used