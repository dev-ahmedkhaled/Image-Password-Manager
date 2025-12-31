# decode_from_ciphertext Documentation

## Overview
This function **decrypts AES-256-CBC encrypted text** back to its original JSON format. It's the reverse of `encode_json_to_ciphertext` and requires the exact same password that was used for encryption.

---

## What This Function Does

**In simple terms**: Takes scrambled encrypted text and turns it back into readable JSON, but only if you have the correct password.

**Analogy**: Like opening a locked safe - you need the exact combination (password) to get your data back.

---

## Function Signature

```octave
function plaintext = decode_from_ciphertext(ciphertext, pass)
```

### Parameters

**`ciphertext`** (string, required)
- The encrypted Base64 string from `encode_json_to_ciphertext`
- Example: `"U2FsdGVkX1+8vN2Ks8QfG..."`
- Must be complete and unmodified

**`pass`** (string, optional)
- Master password OR path to password file
- Default: `"../Passwords/correctpass.txt"`
- Must match the password used for encryption

### Returns
**`plaintext`** (string)
- Decrypted JSON text
- Example: `{"username":"user@email.com",...}`
- Ready to be parsed with `jsondecode()`

---

## How It Works: Step by Step

### Step 1: Handle Default Password
```octave
if nargin < 2 || isempty(pass)
    pass = "../Passwords/correctpass.txt";
end
```

**Translation**: If no password provided, use the default file.

---

### Step 2: Extract Master Key
```octave
master_key = "";
if ischar(pass) && exist(pass, 'file') == 2 && endsWith(pass, ".txt")
    master_key = strtrim(fileread(pass));  % Read from file
else
    master_key = pass;  % Use as literal password
end
```

**Logic**:
```
Is 'pass' a .txt file that exists?
├─ YES → Read password from file and remove whitespace
└─ NO  → Use 'pass' directly as the password
```

**Example**:
```octave
% Direct password
plaintext = decode_from_ciphertext(ciphertext, "MyPassword123");

% Or from file
plaintext = decode_from_ciphertext(ciphertext, "keys/master.txt");
```

---

### Step 3: Prepare Temporary Ciphertext File
```octave
tmp_cipher = [tempname(), ".enc"];
fid = fopen(tmp_cipher, 'w');
fprintf(fid, "%s", ciphertext);
fclose(fid);
```

**Why write to a file?**
- Shell commands have length limits (~8KB on some systems)
- Large ciphertext might exceed this limit
- Files are more reliable for passing data to OpenSSL

**What it does**:
1. Creates a unique temporary filename (e.g., `/tmp/oct_abc123.enc`)
2. Writes the ciphertext to this file
3. OpenSSL will read from this file
4. File is deleted after decryption

---

### Step 4: Build OpenSSL Decryption Command
```octave
cmd = sprintf('openssl enc -aes-256-cbc -d -salt -pbkdf2 -a -A -in "%s" -pass pass:"%s" 2>/dev/null',
              tmp_cipher, master_key);
```

**OpenSSL flags explained**:

| Flag | What It Does |
|------|--------------|
| `enc` | Encryption/decryption mode |
| `-aes-256-cbc` | Use AES-256 in CBC mode |
| `-d` | **Decrypt** (instead of encrypt) |
| `-salt` | Expect salted input |
| `-pbkdf2` | Use PBKDF2 key derivation |
| `-a` | Input is Base64 encoded |
| `-A` | Single-line Base64 (no line breaks) |
| `-in` | Input file (our temp file) |
| `-pass pass:` | Password follows |
| `2>/dev/null` | Hide error messages from terminal |

**The `-d` flag is crucial!** Without it, OpenSSL would try to encrypt instead of decrypt.

---

### Step 5: Execute Decryption
```octave
[status, plaintext] = system(cmd);
```

**What happens**:
1. Octave runs OpenSSL command in system shell
2. OpenSSL reads encrypted file
3. OpenSSL derives key from password using PBKDF2
4. OpenSSL decrypts data
5. Returns plaintext (or empty string if wrong password)

**Status codes**:
- `status = 0` → Success ✅ (correct password)
- `status ≠ 0` → Failure ❌ (wrong password or corrupted data)

---

### Step 6: Cleanup and Validation
```octave
if exist(tmp_cipher, 'file')
    delete(tmp_cipher);  % Remove temporary file
end

if status ~= 0 || isempty(plaintext)
    error("Decryption failed! Likely causes: Wrong password or corrupted ciphertext.");
end

fprintf("--- Decryption Successful ---\n");
```

**Error conditions**:
1. **Wrong password**: OpenSSL returns non-zero status
2. **Corrupted ciphertext**: OpenSSL returns empty result
3. **Invalid Base64**: OpenSSL fails to decode

---

## The Decryption Process

### Step-by-Step Breakdown

**Input** (ciphertext):
```
U2FsdGVkX1+8vN2Ks8QfGhyZm1vLmnB3Q...
```

**Step 1: Base64 Decode**
```
Ciphertext → [Salted__][8-byte salt][encrypted data...]
            Binary bytes
```

**Step 2: Extract Salt**
```
First 8 bytes after "Salted__" header = Salt value
Example: [0xA7, 0xB3, 0x5C, 0x9F, 0x2E, 0x8D, 0x4A, 0x6B]
```

**Step 3: Derive Key from Password**
```
Key = PBKDF2(
    password = "MyPassword123",
    salt = [0xA7, 0xB3, ...],
    iterations = 10000,
    key_length = 32 bytes
)

Result: [0x4F, 0x8A, 0x2B, ...] (256-bit key)
```

**Step 4: AES Decrypt Each Block**
```
Encrypted Block 1 → AES Decrypt → XOR with IV → Plaintext Block 1
Encrypted Block 2 → AES Decrypt → XOR with Block 1 → Plaintext Block 2
...
```

**Output** (plaintext):
```json
{"password_manager":{"entries":[{"title":"Gmail",...}]}}
```

---

## The Math Behind Decryption

### PBKDF2 Key Derivation
```
Same as encryption:
Key = PBKDF2(password, salt, iterations, length)

Must use:
- Same password ✓
- Same salt (extracted from ciphertext) ✓
- Same iterations (PBKDF2 default) ✓
```

**Why it matters**:
```
Wrong password → Different key → Garbage output
Correct password → Correct key → Valid plaintext
```

---

### AES-CBC Decryption

**CBC Mode** (Cipher Block Chaining):
```
Decryption formula for each block:
Plaintext[i] = AES_Decrypt(Ciphertext[i], Key) XOR Ciphertext[i-1]

For first block:
Plaintext[0] = AES_Decrypt(Ciphertext[0], Key) XOR IV
```

**Visual representation**:
```
Ciphertext Block 1 → [AES Decrypt] → XOR with IV → Plaintext Block 1
Ciphertext Block 2 → [AES Decrypt] → XOR with CT1 → Plaintext Block 2
Ciphertext Block 3 → [AES Decrypt] → XOR with CT2 → Plaintext Block 3
```

**Key property**: Each block needs the previous ciphertext block for decryption.

---

## Usage Examples

### Example 1: Basic Decryption
```octave
% Assuming you have encrypted text
ciphertext = "U2FsdGVkX1+8vN2Ks8QfGhyZm1...";

% Decrypt with password file
plaintext = decode_from_ciphertext(ciphertext, "Passwords/master.txt");

% Parse JSON
data = jsondecode(plaintext);
fprintf("Username: %s\n", data.username);
```

---

### Example 2: Direct Password
```octave
ciphertext = "U2FsdGVkX1...";
plaintext = decode_from_ciphertext(ciphertext, "MySecretPassword");
```

---

### Example 3: Error Handling
```octave
try
    plaintext = decode_from_ciphertext(ciphertext, "WrongPassword");
    data = jsondecode(plaintext);
catch ME
    fprintf("Error: %s\n", ME.message);
    % Output: "Decryption failed! Likely causes: Wrong password..."
end
```

---

### Example 4: Full Encrypt-Decrypt Cycle
```octave
% Create test data
test_data = struct('name', 'John', 'secret', 'Password123');
json_str = jsonencode(test_data);

% Write to file
fid = fopen('test.json', 'w');
fprintf(fid, '%s', json_str);
fclose(fid);

% Encrypt
ciphertext = encode_json_to_ciphertext('test.json', 'MasterPass');
fprintf('Encrypted: %s\n', ciphertext);

% Decrypt
plaintext = decode_from_ciphertext(ciphertext, 'MasterPass');
fprintf('Decrypted: %s\n', plaintext);

% Parse
recovered_data = jsondecode(plaintext);
assert(strcmp(recovered_data.name, 'John'));
fprintf('✓ Round-trip successful!\n');
```

---

## Error Handling

### Common Errors and Solutions

**1. "Decryption failed! Wrong password"**
```octave
Error: Decryption failed! Likely causes: Wrong password or corrupted ciphertext.
```

**Causes**:
- Password doesn't match encryption password
- Password file contains extra whitespace/newlines
- Typo in password

**Solutions**:
```octave
% Check password file content
master_key = strtrim(fileread('master.txt'));
fprintf('Password: [%s]\n', master_key);

% Try manual password
plaintext = decode_from_ciphertext(ciphertext, "YourActualPassword");
```

---

**2. "bad decrypt" from OpenSSL**
```
Error message (in stderr): 
bad decrypt
140736724801856:error:06065064:digital envelope routines:EVP_DecryptFinal_ex:bad decrypt
```

**Meaning**: 
- Wrong password definitely
- OpenSSL detected padding mismatch
- Decryption completed but output is invalid

**What's happening**:
```
With wrong password:
Decrypted bytes = random garbage
Last block padding = invalid
OpenSSL detects this → Error
```

---

**3. Corrupted Ciphertext**
```octave
% If someone modified the ciphertext
ciphertext = "U2FsdGVkX1CORRUPTED...";
plaintext = decode_from_ciphertext(ciphertext, "CorrectPass");
% Error: Decryption failed!
```

**Causes**:
- Text was truncated
- Characters were changed
- File was corrupted during transfer

---

**4. Empty or Invalid Base64**
```octave
ciphertext = "Not valid Base64!@#$";
% OpenSSL error: invalid base64 encoding
```

---

## Security Considerations

### What Makes This Secure?

**1. Password is never stored**
```octave
master_key = ...;  % Exists only in memory
% After function ends, master_key is destroyed
```

**2. Temporary file cleanup**
```octave
delete(tmp_cipher);  % Ciphertext file removed immediately
```

**3. Error suppression**
```octave
2>/dev/null  % Prevents password leaks in error messages
```

---

### What Could Go Wrong?

**1. Password in command history**
```bash
# Shell history might contain:
openssl enc ... -pass pass:MySecretPassword
```
**Mitigation**: Use password files instead of direct passwords

**2. Temporary file interception**
```
/tmp/oct_abc123.enc exists briefly
```
**Mitigation**: OS-level temp directory permissions

**3. Memory dumps**
```
master_key variable exists in memory
```
**Mitigation**: Clear sensitive variables after use

---

## Testing Decryption

### Test 1: Correct Password
```octave
function test_correct_password()
    cipher = encode_json_to_ciphertext('test.json', 'TestPass');
    plain = decode_from_ciphertext(cipher, 'TestPass');
    assert(~isempty(plain), 'Decryption failed!');
    fprintf('✓ Correct password works\n');
end
```

---

### Test 2: Wrong Password
```octave
function test_wrong_password()
    cipher = encode_json_to_ciphertext('test.json', 'CorrectPass');
    try
        plain = decode_from_ciphertext(cipher, 'WrongPass');
        error('Should have failed!');
    catch ME
        assert(contains(ME.message, 'Decryption failed'));
        fprintf('✓ Wrong password correctly rejected\n');
    end
end
```

---

### Test 3: Password File with Whitespace
```octave
function test_password_whitespace()
    % Create password file with trailing newline
    fid = fopen('test_pass.txt', 'w');
    fprintf(fid, 'MyPassword123\n\n');  % Extra newlines
    fclose(fid);
    
    % Encrypt
    cipher = encode_json_to_ciphertext('test.json', 'test_pass.txt');
    
    % Decrypt should still work (strtrim removes whitespace)
    plain = decode_from_ciphertext(cipher, 'test_pass.txt');
    assert(~isempty(plain));
    fprintf('✓ Whitespace handling works\n');
end
```

---

## Performance

### Decryption Speed

**Factors affecting speed**:
1. **PBKDF2 iterations** (~0.1 seconds per decryption)
   - Security feature (intentionally slow)
   - Makes brute-force attacks impractical

2. **Data size**
   - Small files (< 1KB): < 0.2 seconds
   - Large files (> 100KB): 1-2 seconds

3. **System overhead**
   - Starting OpenSSL process: ~0.05 seconds
   - File I/O: ~0.01 seconds

**Total typical time**: 0.2-0.3 seconds for small files

---

## Comparison with Encryption

| Aspect | Encryption | Decryption |
|--------|-----------|------------|
| Speed | Fast | Fast (same) |
| Key derivation | PBKDF2 (~0.1s) | PBKDF2 (~0.1s) |
| Salt | Generated randomly | Extracted from ciphertext |
| Output | Always different | Always same (if correct password) |
| Failure mode | Rare (file errors) | Common (wrong password) |

---

## Advanced Usage

### Extracting Salt from Ciphertext

```octave
function salt = extract_salt(ciphertext)
    % Decode Base64
    decoded = base64decode(ciphertext);
    
    % Check "Salted__" header (8 bytes)
    header = char(decoded(1:8));
    assert(strcmp(header, 'Salted__'), 'Not a salted ciphertext!');
    
    % Extract salt (next 8 bytes)
    salt = decoded(9:16);
    fprintf('Salt (hex): ');
    fprintf('%02X ', salt);
    fprintf('\n');
end
```

---

### Manual Key Derivation (for debugging)

```octave
function key = derive_key_manual(password, salt)
    % Note: This is pseudocode, actual implementation needs crypto library
    key = pbkdf2(password, salt, 10000, 32, 'SHA256');
    fprintf('Derived key: ');
    fprintf('%02X ', key);
    fprintf('\n');
end
```

---

## Troubleshooting Guide

### Problem: "command not found: openssl"

**Solution**:
```bash
# Check if OpenSSL is installed
which openssl

# Install if missing
# Ubuntu/Debian:
sudo apt-get install openssl

# macOS:
brew install openssl

# Windows:
# Download from https://slproweb.com/products/Win32OpenSSL.html
```

---

### Problem: Decryption returns garbage

**Possible causes**:
1. Wrong password (most common)
2. Different encryption algorithm
3. Corrupted ciphertext

**Debug steps**:
```octave
% 1. Verify ciphertext starts correctly
assert(startsWith(ciphertext, 'U2FsdGVk'), 'Invalid ciphertext format');

% 2. Check password
fprintf('Password: [%s]\n', master_key);

% 3. Try command manually in shell
cmd = sprintf('echo "%s" | openssl enc -aes-256-cbc -d -a -A -pass pass:"%s"',
              ciphertext, master_key);
system(cmd);
```

---

### Problem: "bad magic number" error

**Meaning**: Ciphertext is not in OpenSSL format

**Causes**:
- Not encrypted with OpenSSL
- Encrypted with different algorithm
- Corrupted during transfer

---

## Summary

**What this function does**:
1. ✅ Takes encrypted Base64 string
2. ✅ Extracts salt from ciphertext
3. ✅ Derives key from password using PBKDF2
4. ✅ Decrypts using AES-256-CBC
5. ✅ Returns original JSON text
6. ✅ Handles errors gracefully

**Security**: Military-grade decryption (AES-256)

**Use case**: Recovering data encrypted with `encode_json_to_ciphertext`

**Key requirement**: Must have exact same password used for encryption!