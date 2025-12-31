# Password_saver Documentation

## Overview
This is the **main encoding script** that takes your password file, encrypts it, and hides it inside an image. It's a complete "save passwords to vault" workflow in one script.

---

## What This Script Does

**In simple terms**: Takes your passwords from a JSON file, scrambles them with encryption, and invisibly hides them inside a normal-looking photo.

**Analogy**: Like putting your diary in a secret compartment inside a photo frame - the photo looks normal, but your secrets are hidden inside.

---

## Complete Workflow

```
JSON passwords → Encrypt (AES-256) → Hide in image (DCT) → Save PNG vault
```

### Visual Flow
```
secrets.json        AES-256-CBC         DCT Steganography      nature_stego.png
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐    ┌──────────────┐
│ Passwords   │ →  │ Encrypted    │ →  │ Hidden in       │ →  │ Vault        │
│ (readable)  │    │ (scrambled)  │    │ Image (encoded) │    │ (secure)     │
└─────────────┘    └──────────────┘    └─────────────────┘    └──────────────┘
```

---

## Script Structure

### Configuration Section
```octave
json_file = 'Passwords/secrets.json';      % Your passwords
cover_image = 'images/nature.jpg';         % Cover photo
stego_output = 'images/nature_stego.png';  % Output vault
master_pass_file = 'Passwords/correctpass.txt';  % Master password
```

**What to customize**:
- `json_file`: Path to your password data
- `cover_image`: Photo to hide data in (larger = more capacity)
- `stego_output`: Where to save the vault image
- `master_pass_file`: Your master password file

---

## Phase 1: Encryption

```octave
fprintf('Step 1: Encrypting %s...\n', json_file);
ciphertext = encode_json_to_ciphertext(json_file, master_pass_file);
fprintf('✓ Encryption successful! Ciphertext length: %d\n', length(ciphertext));
```

### What Happens
1. Reads `secrets.json`
2. Reads master password from `correctpass.txt`
3. Uses OpenSSL with AES-256-CBC to encrypt
4. Produces Base64 ciphertext string

### Example Output
```
Step 1: Encrypting Passwords/secrets.json...
Encrypting: Passwords/secrets.json
--- Encrypted Output ---
U2FsdGVkX1+8vN2Ks8QfGhyZm1vLmnB3Q4K9x...
------------------------
✓ Encryption successful! Ciphertext length: 1456
```

---

## Phase 2: Embedding

```octave
fprintf('\nStep 2: Embedding data into %s...\n', cover_image);
stego_image = encode_to_image(ciphertext, cover_image);
```

### What Happens
1. Loads `nature.jpg`
2. Converts to DCT domain (frequency representation)
3. Hides ciphertext in mid-frequency coefficients
4. Reconstructs image with hidden data
5. Returns image matrix

### Example Output
```
Step 2: Embedding data into images/nature.jpg...

=== Encoding Ciphertext into Image ===
Cover image: images/nature.jpg

Step 1: Converting image to DCT domain...
Converted RGB to grayscale
Image size: 512x512
DCT transformation complete. Blocks: 64x64

Step 2: Embedding ciphertext into DCT coefficients...

=== Starting Data Embedding ===
Data size: 1456 bytes (11648 bits)
Total bits to embed (header + data): 11712
Image capacity: 57344 bits (7168 bytes)
Embedding complete!

Step 3: Reconstructing stego image...
Image reconstruction complete

Step 4: Calculating quality metrics...

=== Quality Metrics ===
MSE:  0.2341
PSNR: 44.43 dB
Quality: Excellent (imperceptible)
```

---

## Phase 3: Saving

```octave
imwrite(uint8(stego_image), stego_output);
fprintf('✓ Success! Vault saved to: %s\n', stego_output);
```

### What Happens
1. Converts image matrix to 8-bit unsigned integers (0-255)
2. Saves as PNG (lossless format)
3. Your password vault is now ready!

### Example Output
```
✓ Success! Vault saved to: images/nature_stego.png

========================================
   VAULT UPDATED AND SECURED            
========================================
```

---

## File Structure

### Input Files Required

**1. `secrets.json`** - Your password data
```json
{
  "password_manager": {
    "version": "1.0",
    "entries": [
      {
        "title": "Gmail",
        "username": "myemail@gmail.com",
        "password": "MySecretPassword123",
        "url": "https://gmail.com",
        "notes": "Personal email account"
      },
      {
        "title": "Bank",
        "username": "user123",
        "password": "BankPass456",
        "url": "https://mybank.com",
        "notes": "Checking account"
      }
    ]
  }
}
```

**2. `correctpass.txt`** - Master password
```
MyMasterPassword123
```
**Note**: Single line, no extra spaces

**3. `nature.jpg`** - Cover image
- Any image file (JPG, PNG, BMP)
- Larger image = more hiding capacity
- Complex patterns work best (nature photos, crowds)

---

### Output File

**`nature_stego.png`** - Your password vault
- **Looks like**: Normal photo
- **Actually contains**: Encrypted passwords
- **Format**: PNG (lossless)
- **Size**: Same dimensions as cover image

---

## Path Setup (Technical Details)

```octave
project_root = pwd;
module_path = fullfile(project_root, 'modules');
encode_path = fullfile(project_root, 'Encode');
decode_path = fullfile(project_root, 'Decode');

if exist(module_path, 'dir'), addpath(module_path); end
if exist(encode_path, 'dir'), addpath(encode_path); end
if exist(decode_path, 'dir'), addpath(decode_path); end
```

**What this does**:
- Finds required function folders
- Adds them to Octave's search path
- Ensures all functions are accessible

**Required folders**:
- `modules/` - Contains `dct_transform.m`, `steganography.m`
- `Encode/` - Contains encoding functions
- `Decode/` - Contains decoding functions (for future extraction)

---

## Error Handling

### Try-Catch Blocks

**For Encryption**:
```octave
try
    ciphertext = encode_json_to_ciphertext(json_file, master_pass_file);
    fprintf('✓ Encryption successful!\n');
catch ME
    error('Encryption failed: %s', ME.message);
end
```

**For Embedding**:
```octave
try
    stego_image = encode_to_image(ciphertext, cover_image);
    imwrite(uint8(stego_image), stego_output);
    fprintf('✓ Success!\n');
catch ME
    error('Embedding failed: %s', ME.message);
end
```

---

## Common Errors and Solutions

### Error 1: "JSON file not found"
```
Error: JSON file not found at 'Passwords/secrets.json'
```

**Solutions**:
1. Check file exists:
   ```bash
   ls Passwords/secrets.json
   ```

2. Fix path in script:
   ```octave
   json_file = 'correct/path/to/secrets.json';
   ```

3. Create JSON file:
   ```bash
   mkdir -p Passwords
   # Then create secrets.json
   ```

---

### Error 2: "Cover image not found"
```
Error: Cover image not found at 'images/nature.jpg'
```

**Solutions**:
1. Check image exists:
   ```bash
   ls images/nature.jpg
   ```

2. Use different image:
   ```octave
   cover_image = 'path/to/your/photo.jpg';
   ```

3. Download sample image or use your own photo

---

### Error 3: "Data too large!"
```
Error: Data too large! Need 80000 bits but capacity is 57344 bits
```

**Meaning**: Your password file is too big for this image

**Solutions**:
1. Use larger cover image:
   ```octave
   cover_image = 'images/larger_photo.jpg';  % e.g., 1024×1024
   ```

2. Reduce password entries in JSON

3. Split data across multiple images

**Capacity formula**:
```
Capacity (bytes) ≈ (width × height) / 64
```

---

### Error 4: "openssl: command not found"
```
Error: Encryption failed. Check if OpenSSL is installed...
```

**Solutions**:
```bash
# Ubuntu/Debian:
sudo apt-get install openssl

# macOS:
brew install openssl

# Windows:
# Download from: https://slproweb.com/products/Win32OpenSSL.html
```

---

### Error 5: "Could not find modules folder!"
```
Error: Could not find modules folder!
```

**Solution**: Ensure project structure is correct:
```
project/
├── Password_saver.m
├── modules/
│   ├── dct_transform.m
│   └── steganography.m
├── Encode/
│   ├── encode_json_to_ciphertext.m
│   └── encode_to_image.m
└── Passwords/
    └── secrets.json
```

---

## Usage Examples

### Example 1: Basic Usage (Default Settings)
```octave
% Just run the script
run('Password_saver.m')

% Output:
% ✓ Encryption successful!
% ✓ Success! Vault saved to: images/nature_stego.png
```

---

### Example 2: Custom Paths
```octave
% Edit configuration at top of script
json_file = 'MyData/passwords.json';
cover_image = 'Photos/vacation.jpg';
stego_output = 'Vaults/my_secure_vault.png';
master_pass_file = 'Keys/master_key.txt';

% Then run
run('Password_saver.m')
```

---

### Example 3: Multiple Vaults
```octave
% Save different password groups in different images

% Work passwords
json_file = 'Passwords/work_passwords.json';
cover_image = 'images/office.jpg';
stego_output = 'vaults/work_vault.png';
run('Password_saver.m')

% Personal passwords
json_file = 'Passwords/personal_passwords.json';
cover_image = 'images/beach.jpg';
stego_output = 'vaults/personal_vault.png';
run('Password_saver.m')
```

---

### Example 4: Batch Processing
```octave
% Process multiple password files
files = {'work.json', 'personal.json', 'banking.json'};
images = {'office.jpg', 'beach.jpg', 'secure.jpg'};

for i = 1:length(files)
    json_file = ['Passwords/' files{i}];
    cover_image = ['images/' images{i}];
    stego_output = ['vaults/vault_' num2str(i) '.png'];
    
    fprintf('\n=== Processing %s ===\n', files{i});
    
    try
        cipher = encode_json_to_ciphertext(json_file, master_pass_file);
        stego = encode_to_image(cipher, cover_image);
        imwrite(uint8(stego), stego_output);
        fprintf('✓ Saved: %s\n', stego_output);
    catch ME
        fprintf('✗ Failed: %s\n', ME.message);
    end
end
```

---

## Security Best Practices

### 1. Protect Master Password File
```bash
# Set restrictive permissions (Unix/Linux/Mac)
chmod 600 Passwords/correctpass.txt

# Only owner can read/write
```

---

### 2. Don't Commit Sensitive Files
```gitignore
# Add to .gitignore
Passwords/*.txt
Passwords/*.json
**/correctpass.txt
images/*_stego.png
vaults/*.png
```

---

### 3. Use Strong Master Password
```
❌ Bad:  "password123"
❌ Bad:  "myname2024"
✅ Good: "Tr0ub4dor&3-MySecure-Pass2024!"
```

**Requirements**:
- At least 12 characters
- Mix of uppercase, lowercase, numbers, symbols
- Not a dictionary word
- Not personal information

---

### 4. Backup Your Vault Securely
```bash
# Encrypted backup
cp vaults/my_vault.png ~/secure_backup/
# Or use cloud storage with encryption

# NEVER lose your master password!
# Without it, data is unrecoverable
```

---

### 5. Keep Cover Images Separate
```bash
# Don't delete original cover images
# You might need them for comparison or re-embedding

mkdir -p images/originals
cp images/nature.jpg images/originals/
```

---

## Quality Indicators

### Excellent Quality (PSNR > 40 dB)
```
=== Quality Metrics ===
MSE:  0.12
PSNR: 47.3 dB
Quality: Excellent (imperceptible)
```
**Meaning**: Changes are invisible, perfect steganography

---

### Good Quality (PSNR > 30 dB)
```
=== Quality Metrics ===
MSE:  1.8
PSNR: 35.6 dB
Quality: Good (minor differences)
```
**Meaning**: Minor differences, still very good

---

### Poor Quality (PSNR < 30 dB)
```
=== Quality Metrics ===
MSE:  15.3
PSNR: 26.2 dB
Quality: Poor (visible differences)
```
**Meaning**: Visible artifacts, consider using:
- Larger image
- Less data
- More complex cover image

---

## Performance Benchmarks

### Small Password File (< 1 KB)
```
512×512 image:
- Encryption:  0.2 seconds
- Embedding:   1.2 seconds
- Total:       ~1.4 seconds
```

---

### Medium Password File (1-5 KB)
```
1024×1024 image:
- Encryption:  0.3 seconds
- Embedding:   4.5 seconds
- Total:       ~4.8 seconds
```

---

### Large Password File (5-20 KB)
```
2048×2048 image:
- Encryption:  0.5 seconds
- Embedding:   18 seconds
- Total:       ~18.5 seconds
```

---

## Testing Your Setup

### Quick Test
```octave
% Create minimal test files

% 1. Create test password
test_data = struct('entries', {{struct('title', 'Test', 'password', 'Pass123')}});
fid = fopen('test_passwords.json', 'w');
fprintf(fid, '%s', jsonencode(test_data));
fclose(fid);

% 2. Create test master password
fid = fopen('test_master.txt', 'w');
fprintf(fid, 'TestPassword123');
fclose(fid);

% 3. Update script configuration
json_file = 'test_passwords.json';
master_pass_file = 'test_master.txt';
cover_image = 'any_image.jpg';  % Use any photo
stego_output = 'test_vault.png';

% 4. Run
run('Password_saver.m')

% 5. Check output
if exist('test_vault.png', 'file')
    fprintf('✓ Test successful!\n');
end
```

---

## Troubleshooting Checklist

Before running the script, verify:

- [ ] All required files exist
  ```bash
  ls Passwords/secrets.json
  ls Passwords/correctpass.txt
  ls images/nature.jpg
  ```

- [ ] Modules folder exists
  ```bash
  ls modules/dct_transform.m
  ls modules/steganography.m
  ```

- [ ] OpenSSL is installed
  ```bash
  openssl version
  ```

- [ ] Output directory is writable
  ```bash
  touch images/test_write && rm images/test_write
  ```

- [ ] Image has enough capacity
  ```octave
  img = imread('images/nature.jpg');
  [h, w, ~] = size(img);
  capacity = floor((h/8) * (w/8) * 14 / 8);
  fprintf('Capacity: %d bytes\n', capacity);
  ```

---

## Summary

**What this script does**:
1. ✅ Reads your passwords from JSON
2. ✅ Encrypts with AES-256-CBC
3. ✅ Hides encrypted data in image using DCT
4. ✅ Saves secure vault as PNG

**Input files needed**:
- Password JSON file
- Master password file
- Cover image

**Output**:
- Stego image (vault) that looks normal but contains hidden encrypted passwords

**Security level**:
- Encryption: Military-grade (AES-256)
- Steganography: Invisible changes (PSNR > 40 dB typically)

**Use case**: Initial setup of password vault