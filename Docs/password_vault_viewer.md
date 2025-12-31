# password_vault_viewer Documentation

## Overview
This script **reads and displays your passwords** directly from a stego vault image. It's the complete extraction and decryption workflow in one easy-to-use script.

---

## What This Script Does

**In simple terms**: Takes your vault image (which looks like a normal photo), extracts the hidden data, decrypts it with your master password, and shows you all your passwords in a readable format.

**Analogy**: Like using a special decoder to reveal the secret message hidden in invisible ink on a postcard.

---

## Complete Workflow

```
Stego vault → Extract hidden data → Decrypt → Parse JSON → Display passwords
```

### Visual Flow
```
nature_stego.png    DCT Extraction      AES-256 Decryption    JSON Parsing      Display
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────┐
│ Vault Image  │ →  │ Ciphertext   │ →  │ Decrypted    │ →  │ Data        │ →  │ Readable │
│ (looks normal)│    │ (extracted)  │    │ JSON         │    │ Structure   │    │ Passwords│
└──────────────┘    └──────────────┘    └──────────────┘    └─────────────┘    └──────────┘
```

---

## Script Structure

### Configuration Section
```octave
STEGO_IMAGE = 'images/nature_stego.png';           % Your vault
MASTER_PASS_FILE = 'Passwords/correctpass.txt';   % Your master password
```

**What to customize**:
- `STEGO_IMAGE`: Path to your vault image (created by Password_saver.m)
- `MASTER_PASS_FILE`: Path to your master password file

---

## Step-by-Step Process

### Step 0: Setup
```octave
clear; clc;
addpath('modules');  % Ensure functions are accessible
```

**Why clear the workspace?**
- Starts fresh (no old variables)
- Prevents conflicts
- Ensures clean execution

---

### Step 1: Validate Image
```octave
if ~exist(STEGO_IMAGE, 'file')
    error('Error: Stego image "%s" not found!', STEGO_IMAGE);
end
```

**Check**: Vault image exists before attempting extraction

---

### Step 2: Extract Ciphertext
```octave
fprintf('Step 1: Extracting encrypted data from image...\n');
ciphertext = decode_from_image(STEGO_IMAGE);
```

**What happens**:
1. Load stego image
2. Convert to DCT domain
3. Extract bits from mid-frequency coefficients
4. Verify magic number (header validation)
5. Convert bits to bytes
6. Convert bytes to Base64 string

**Output example**:
```
Step 1: Extracting encrypted data from image...

=== Extracting Ciphertext from Image ===
Stego image: images/nature_stego.png

Step 1: Converting stego image to DCT domain...
Image size: 512x512
DCT transformation complete. Blocks: 64x64

Step 2: Extracting embedded data from DCT coefficients...

=== Starting Data Extraction ===
Magic number verified!
Data length: 1456 bytes
Extraction complete! Extracted 1456 bytes

=== Extraction Complete ===
```

---

### Step 3: Decrypt with Master Password
```octave
fprintf('Step 2: Decrypting with Master Password...\n');
json_str = decode_from_ciphertext(ciphertext, MASTER_PASS_FILE);
```

**What happens**:
1. Read master password from file
2. OpenSSL decrypts ciphertext using AES-256-CBC
3. Returns plaintext JSON string

**Output example**:
```
Step 2: Decrypting with Master Password...
--- Decryption Successful ---
```

---

### Step 4: Parse JSON
```octave
data = jsondecode(json_str);
```

**Converts**:
```
JSON string → Octave structure

From: '{"password_manager":{"entries":[...]}}'
To:   data.password_manager.entries(1).title = "Gmail"
```

---

### Step 5: Display Passwords
```octave
fprintf('\n--- DECRYPTION SUCCESSFUL ---\n');

% Check for version field
if isfield(data, 'version')
    fprintf('Version: %s\n', data.version);
end

% Navigate to entries
if isfield(data, 'password_manager')
    entries = data.password_manager.entries;
elseif isfield(data, 'entries')
    entries = data.entries;
else
    disp(data);  % Print entire structure
    entries = [];
end

% Display each entry
for i = 1:length(entries)
    e = entries(i);
    
    % Get title
    if isfield(e, 'title')
        title_str = e.title;
    elseif isfield(e, 'Title')
        title_str = e.Title;
    else
        title_str = sprintf("Entry %d", i);
    end
    
    % Get category
    category = "General";
    if isfield(e, 'category')
        category = e.category;
    end
    
    fprintf('[%s] %s\n', category, title_str);
    
    % Print fields if they exist
    if isfield(e, 'username')
        fprintf('  > Username: %s\n', e.username);
    end
    if isfield(e, 'password')
        fprintf('  > Password: %s\n', e.password);
    end
    if isfield(e, 'url')
        fprintf('  > URL:      %s\n', e.url);
    end
    if isfield(e, 'notes')
        fprintf('  > Notes:    %s\n', e.notes);
    end
    
    fprintf('----------------------------------------\n');
end
```

---

## Example Output

### Complete Session
```
========================================
       STEGO VAULT: PASSWORD VIEWER     
========================================

Step 1: Extracting encrypted data from image...

=== Extracting Ciphertext from Image ===
Stego image: images/nature_stego.png
[DCT and extraction details...]
=== Extraction Complete ===

Step 2: Decrypting with Master Password...
--- Decryption Successful ---

--- DECRYPTION SUCCESSFUL ---
Version: 1.0
----------------------------------------
[Email] Gmail
  > Username: myemail@gmail.com
  > Password: MySecretPass123
  > URL:      https://gmail.com
  > Notes:    Personal email account
----------------------------------------
[Banking] Chase Bank
  > Username: user12345
  > Password: BankPass456!
  > URL:      https://chase.com
  > Notes:    Checking account
----------------------------------------
[Social] Twitter
  > Username: @myhandle
  > Password: TwitterPass789
  > URL:      https://twitter.com
  > Notes:    Main account
----------------------------------------

=== END OF VAULT VIEWER ===
```

---

## Error Handling

### Try-Catch Block
```octave
try
    % Extraction
    ciphertext = decode_from_image(STEGO_IMAGE);
    
    % Decryption
    json_str = decode_from_ciphertext(ciphertext, MASTER_PASS_FILE);
    
    % Parsing and display
    data = jsondecode(json_str);
    % ... display code ...
    
catch ME
    fprintf('\n✗ Access denied: %s\n', ME.message);
    fprintf('Please check your stego image and master password.\n');
end
```

**Benefits**:
- Graceful error handling
- Clear error messages
- Script doesn't crash unexpectedly

---

## Common Errors and Solutions

### Error 1: "Stego image not found"
```
Error: Stego image "images/vault.png" not found!
```

**Solutions**:
1. Check file exists:
   ```bash
   ls images/vault.png
   ```

2. Fix path in script:
   ```octave
   STEGO_IMAGE = 'correct/path/to/vault.png';
   ```

3. Ensure you've run `Password_saver.m` first

---

### Error 2: "Magic number not found"
```
✗ Access denied: Magic number not found! This image may not contain hidden data.
```

**Causes**:
- Image doesn't contain hidden data
- Image is not from Password_saver.m
- Image was modified (compressed, resized, etc.)

**Solutions**:
1. Verify it's the correct stego image
2. Check if image was modified:
   ```bash
   file images/nature_stego.png
   # Should show: PNG image data
   ```

3. Re-run Password_saver.m to create fresh vault

---

### Error 3: "Decryption failed! Wrong password"
```
✗ Access denied: Decryption failed! Likely causes: Wrong password or corrupted ciphertext.
```

**Causes**:
- Wrong master password
- Password file has typos or extra whitespace
- Different password than used for encryption

**Solutions**:
1. Check password file:
   ```octave
   pass = strtrim(fileread('Passwords/correctpass.txt'));
   fprintf('Password: [%s]\n', pass);
   ```

2. Ensure no trailing newlines:
   ```bash
   cat -A Passwords/correctpass.txt
   # Should show: MyPassword123 (no $ at end)
   ```

3. Try direct password:
   ```octave
   json_str = decode_from_ciphertext(ciphertext, 'YourActualPassword');
   ```

---

### Error 4: "JSON parsing error"
```
✗ Access denied: parse error...
```

**Causes**:
- Corrupted ciphertext extraction
- Image was modified after creation
- Decryption produced invalid output

**Solutions**:
1. Check extracted ciphertext:
   ```octave
   fprintf('Ciphertext: %s...\n', ciphertext(1:50));
   % Should start with Base64 characters
   ```

2. Verify decrypted JSON:
   ```octave
   fprintf('JSON: %s...\n', json_str(1:100));
   % Should look like: {"password_manager":...
   ```

---

## Flexible JSON Structure Handling

The script handles different JSON structures:

### Structure 1: password_manager wrapper
```json
{
  "password_manager": {
    "version": "1.0",
    "entries": [...]
  }
}
```
**Access**: `data.password_manager.entries`

---

### Structure 2: Direct entries
```json
{
  "entries": [...]
}
```
**Access**: `data.entries`

---

### Structure 3: Unknown structure
```json
{
  "some_other_format": [...]
}
```
**Fallback**: `disp(data)` - Prints entire structure

---

## Field Handling

### Required vs Optional Fields

**The script safely handles missing fields**:

```octave
% Title (with fallback)
if isfield(e, 'title')
    title_str = e.title;
else
    title_str = "Entry " + num2str(i);
end

% Optional fields (only print if exist)
if isfield(e, 'username')
    fprintf('  > Username: %s\n', e.username);
end
```

**Supported fields**:
- `title` or `Title` (auto-detects case)
- `username` (optional)
- `password` (optional)
- `url` (optional)
- `notes` (optional)
- `category` (optional, defaults to "General")

---

## Usage Examples

### Example 1: Basic Viewing
```octave
% Simply run the script
run('password_vault_viewer.m')

% Your passwords will be displayed
```

---

### Example 2: Multiple Vaults
```octave
% View different vaults by editing STEGO_IMAGE

% Work vault
STEGO_IMAGE = 'vaults/work_vault.png';
run('password_vault_viewer.m')

% Personal vault
STEGO_IMAGE = 'vaults/personal_vault.png';
run('password_vault_viewer.m')
```

---

### Example 3: Save Output to File
```octave
% Redirect output to file
diary('extracted_passwords.txt');
run('password_vault_viewer.m');
diary off;

% Now you can read passwords from the text file
```

---

### Example 4: Programmatic Access
```octave
% Extract and use programmatically
STEGO_IMAGE = 'vault.png';
MASTER_PASS_FILE = 'master.txt';

try
    cipher = decode_from_image(STEGO_IMAGE);
    json_str = decode_from_ciphertext(cipher, MASTER_PASS_FILE);
    data = jsondecode(json_str);
    
    % Find specific password
    entries = data.password_manager.entries;
    for i = 1:length(entries)
        if strcmp(entries(i).title, 'Gmail')
            fprintf('Gmail password: %s\n', entries(i).password);
            break;
        end
    end
catch ME
    fprintf('Error: %s\n', ME.message);
end
```

---

### Example 5: Export to CSV
```octave
function export_to_csv(stego_image, master_pass, output_csv)
    try
        % Extract and decrypt
        cipher = decode_from_image(stego_image);
        json_str = decode_from_ciphertext(cipher, master_pass);
        data = jsondecode(json_str);
        
        % Open CSV file
        fid = fopen(output_csv, 'w');
        fprintf(fid, 'Title,Username,Password,URL,Notes\n');
        
        % Write entries
        entries = data.password_manager.entries;
        for i = 1:length(entries)
            e = entries(i);
            fprintf(fid, '"%s","%s","%s","%s","%s"\n', ...
                    e.title, e.username, e.password, ...
                    e.url, e.notes);
        end
        
        fclose(fid);
        fprintf('✓ Exported to: %s\n', output_csv);
    catch ME
        fprintf('✗ Export failed: %s\n', ME.message);
    end
end

% Usage
export_to_csv('vault.png', 'master.txt', 'passwords.csv');
```

---

## Security Considerations

### What This Script Does
- ✓ Decrypts only with correct password
- ✓ Verifies data integrity (magic number)
- ✓ Handles errors gracefully

### What This Script Doesn't Do
- ✗ Doesn't store passwords anywhere
- ✗ Doesn't send data over network
- ✗ Doesn't log sensitive information

---

### Security Best Practices

**1. Clear terminal after viewing**
```bash
clear  # Unix/Linux/Mac
cls    # Windows
```

**2. Don't save output to unencrypted files**
```octave
% BAD:
diary('passwords.txt');  % Unencrypted!
run('password_vault_viewer.m');
diary off;

% GOOD:
% View in terminal only, don't save
```

**3. Lock computer when leaving**
```
Always lock screen after viewing passwords!
```

**4. Use secure password entry**
```octave
% Instead of password file, prompt user:
master_pass = input('Enter master password: ', 's');
json_str = decode_from_ciphertext(ciphertext, master_pass);
clear master_pass;  % Clear from memory
```

---

## Performance

### Typical Execution Time

For a vault with 20 passwords (512×512 image):
```
Extraction:   0.6 seconds
Decryption:   0.2 seconds
Parsing:      0.01 seconds
Display:      0.05 seconds
──────────────────────────
Total:        ~0.9 seconds
```

**Scaling**:
- Extraction time depends on image size
- Decryption time depends on data size
- Display time depends on number of entries

---

## Troubleshooting Checklist

Before running, verify:

- [ ] Stego vault image exists and is PNG
  ```bash
  file images/vault.png
  # Should show: PNG image data
  ```

- [ ] Master password file exists
  ```bash
  cat Passwords/correctpass.txt
  # Should show your password
  ```

- [ ] Password file has no extra whitespace
  ```bash
  wc -l Passwords/correctpass.txt
  # Should show: 1 (single line)
  ```

- [ ] Modules are accessible
  ```bash
  ls modules/dct_transform.m
  ls modules/steganography.m
  ```

- [ ] OpenSSL is installed
  ```bash
  openssl version
  ```

---

## Advanced: Custom Output Format

### Create Your Own Viewer

```octave
function custom_viewer(stego_image, master_pass)
    % Extract and decrypt
    cipher = decode_from_image(stego_image);
    json_str = decode_from_ciphertext(cipher, master_pass);
    data = jsondecode(json_str);
    
    % Custom display format
    fprintf('\n╔════════════════════════════════╗\n');
    fprintf('║     PASSWORD VAULT VIEWER      ║\n');
    fprintf('╚════════════════════════════════╝\n\n');
    
    entries = data.password_manager.entries;
    
    for i = 1:length(entries)
        e = entries(i);
        fprintf('┌─ %s\n', e.title);
        fprintf('│  👤 %s\n', e.username);
        fprintf('│  🔒 %s\n', e.password);
        if isfield(e, 'url') && ~isempty(e.url)
            fprintf('│  🌐 %s\n', e.url);
        end
        fprintf('└─────────────────────────\n\n');
    end
end
```

---

## Comparison: Password_saver vs vault_viewer

| Aspect | Password_saver | vault_viewer |
|--------|----------------|--------------|
| Purpose | Encode (save) | Decode (read) |
| Input | JSON + Image | Stego image |
| Process | Encrypt → Embed | Extract → Decrypt |
| Output | Stego PNG | Display passwords |
| Use case | Initial setup | Daily viewing |
| Speed | ~1.4 sec | ~0.9 sec |

---

## Summary

**What this script does**:
1. ✅ Extracts hidden data from stego image
2. ✅ Decrypts with master password
3. ✅ Parses JSON structure
4. ✅ Displays passwords in readable format
5. ✅ Handles errors gracefully
6. ✅ Supports flexible JSON structures

**Requirements**:
- Stego vault image (PNG from Password_saver.m)
- Master password file (same as used for encoding)
- Modules folder with required functions

**Output**: All your passwords displayed in the terminal

**Use case**: Retrieve passwords from your secure image vault