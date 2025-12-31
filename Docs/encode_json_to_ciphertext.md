# Encryption Function

## File: `encode_json_to_ciphertext.m`

### What Does This Function Do?

Takes a JSON file and encrypts it using **AES-256-CBC encryption** via OpenSSL, returning a secure ciphertext string.

**Simple Analogy**: Like putting your passwords in a high-security vault that only opens with the correct key.

---

## Function Signature

```matlab
function ciphertext = encode_json_to_ciphertext(json_path, pass)
```

**Inputs**:
- `json_path` - Path to your JSON file (e.g., "secrets.json")
- `pass` - Either a password string OR a path to a text file containing the password

**Output**:
- `ciphertext` - Encrypted string (Base64 encoded)

---

## Step-by-Step Process

### Step 1: Handle Default Parameters
```matlab
if nargin < 1 || isempty(json_path)
    json_path = "../Passwords/secrets.json";
end

if nargin < 2 || isempty(pass)
    pass = "../Passwords/correctpass.txt";
end
```

**What this does**: If you don't provide inputs, it uses default file paths.

**nargin**: Counts how many arguments were passed to the function
- `nargin < 1` means "no arguments provided"
- Allows flexible usage:
  ```matlab
  encode_json_to_ciphertext()                    % Uses all defaults
  encode_json_to_ciphertext("mydata.json")       % Custom file, default password
  encode_json_to_ciphertext("data.json", "pwd")  % Both custom
  ```

---

### Step 2: Read Password (Smart Detection)
```matlab
master_key = "";
if ischar(pass) && (exist(pass, 'file') == 2) && endsWith(pass, ".txt")
    master_key = strtrim(fileread(pass));
else
    master_key = pass;
end
```

**This is clever!** The function checks:
1. Is `pass` a string? (`ischar`)
2. Does that string point to a real file? (`exist(pass, 'file')`)
3. Does it end with ".txt"? (`endsWith`)

**Two modes of operation**:
- **File mode**: `pass = "correctpass.txt"` → Reads password from file
- **Direct mode**: `pass = "MySecretPassword123"` → Uses string directly

**strtrim()**: Removes extra spaces and newlines (files often have hidden whitespace)

---

### Step 3: Validate JSON File
```matlab
if exist(json_path, 'file') ~= 2
    error("Error: JSON file not found at '%s'", json_path);
end
```

**Safety check**: Makes sure your JSON file actually exists before trying to encrypt it.

**exist() return values**:
- `2` = File exists
- `7` = Directory exists
- `0` = Doesn't exist

---

### Step 4: Encryption via OpenSSL
```matlab
tmp_json = [tempname(), ".json"];
copyfile(json_path, tmp_json);

cmd = sprintf('openssl enc -aes-256-cbc -salt -pbkdf2 -a -A -in "%s" -pass pass:"%s"', ...
              tmp_json, master_key);

[status, ciphertext] = system(cmd);

delete(tmp_json);
```

**What's happening here**:

1. **Creates temporary copy**: Makes a temp file to protect your original
2. **Builds OpenSSL command**: Creates the encryption command
3. **Executes command**: Runs OpenSSL to encrypt the file
4. **Cleans up**: Deletes the temporary file

**Why temporary file?**: Security! Prevents exposing your original data to the system command directly.

---

## Understanding the OpenSSL Command

```bash
openssl enc -aes-256-cbc -salt -pbkdf2 -a -A -in "file.json" -pass pass:"password"
```

Let's break down each part:

### `-aes-256-cbc`
**What it is**: The encryption algorithm

**Explained**:
- **AES** = Advanced Encryption Standard (the gold standard for encryption)
- **256** = Key size in bits (longer = more secure)
- **CBC** = Cipher Block Chaining (how blocks of data are connected)

**Security level**: Military-grade encryption. Would take billions of years to crack with current computers.

---

### `-salt`
**What it is**: Adds random data to your password before encryption

**Why it matters**: Prevents **rainbow table attacks**

**Example**:
```
Without salt:
Password "hello123" always → Same hash "ABC123..."

With salt:
Password "hello123" + random salt "XyZ" → Hash "DEF456..."
Password "hello123" + random salt "PqR" → Hash "GHI789..."
```

**Result**: Same password produces different encrypted output each time = harder to crack!

---

### `-pbkdf2`
**What it is**: PBKDF2 (Password-Based Key Derivation Function 2)

**What it does**: Converts your human-readable password into a proper encryption key

**How it works**:
1. Takes your password
2. Runs it through a hashing function **many times** (thousands of iterations)
3. Produces a 256-bit key suitable for AES-256

**Why slow is good**: Makes brute-force attacks impractical. If someone tries millions of passwords:
- Without PBKDF2: Tests 1,000,000 passwords/second
- With PBKDF2: Tests 10 passwords/second (much slower!)

**The Math**:
```
DerivedKey = PBKDF2(password, salt, iterations, keyLength)
```
Where:
- `iterations` = Usually 10,000+ (deliberately slow)
- `keyLength` = 256 bits (for AES-256)

---

### `-a` and `-A`
**What they do**:
- `-a` = Base64 encode the output
- `-A` = Put everything on a single line (no line breaks)

**Why Base64?**: Converts binary data into text that's safe to store/transmit

**Example**:
```
Binary:  10110101 01001010 11110000
Base64:  tULw
```

**Result**: Your ciphertext looks like:
```
U2FsdGVkX1+jKLm3PqM8vN7tQxdEw...
```
Instead of unprintable binary garbage.

---

### `-in` and `-pass`
- `-in "file.json"` = Input file to encrypt
- `-pass pass:"password"` = Provides the password

**Note**: The format `pass:` tells OpenSSL the password is provided directly (not from a file)

---

## Security Features Explained

### 1. AES-256 Encryption
**Strength**: 2^256 possible keys (that's 115,792,089,237,316,195,423,570,985,008,687,907,853,269,984,665,640,564,039,457,584,007,913,129,639,936 possibilities!)

**Time to crack**: With current technology, would take longer than the age of the universe.

---

### 2. Salt
**Purpose**: Prevents pre-computed attacks

**How it works**:
```
User 1: Password "hello" + Salt "abc123" → Ciphertext A
User 2: Password "hello" + Salt "xyz789" → Ciphertext B
```
Even with same password, different salts create completely different encrypted output!

---

### 3. PBKDF2 Key Derivation
**Purpose**: Slows down brute-force attacks

**The Math**:
```
For i = 1 to 10,000:
    key = hash(key + password + salt)
```
This means every password attempt takes 10,000x longer to test.

**Real-world impact**:
- Direct hash: Attacker tries 1 billion passwords/second
- With PBKDF2: Attacker tries 100,000 passwords/second (10,000x slower)

---

### 4. CBC Mode (Cipher Block Chaining)
**How it works**: Each block's encryption depends on the previous block

**Visual**:
```
Block 1: Encrypt(Data1 ⊕ IV) → Cipher1
Block 2: Encrypt(Data2 ⊕ Cipher1) → Cipher2
Block 3: Encrypt(Data3 ⊕ Cipher2) → Cipher3
```

**⊕ = XOR operation** (exclusive OR)

**Why this matters**: 
- If you change one character in your data, ALL subsequent blocks change
- Makes pattern analysis impossible
- Prevents attackers from seeing repeated patterns

---

## Error Handling

```matlab
if status ~= 0
    error("Encryption failed. Check if OpenSSL is installed and the key is valid.");
end
```

**What this checks**: 
- `status = 0` means success
- `status ≠ 0` means something went wrong

**Common reasons for failure**:
1. OpenSSL not installed
2. Invalid file paths
3. Permissions issues
4. Corrupted input file

---

## The Output

```matlab
ciphertext = strtrim(ciphertext);
fprintf("--- Encrypted Output ---\n%s\n------------------------\n", ciphertext);
```

**What you get**: A Base64-encoded string like:
```
U2FsdGVkX1+jKLm3PqM8vN7tQxdEw2pLkN5Z8x...
```

**This string contains**:
1. The word "Salted" (in Base64)
2. The random salt used
3. Your encrypted data

**Fun fact**: The prefix `U2FsdGVkX1` always appears because "Salted__" in Base64 is always the same!

---

## Security Best Practices

### ✅ What This Code Does Right:

1. **Uses strong encryption** (AES-256)
2. **Implements salt** (prevents rainbow tables)
3. **Uses PBKDF2** (slows down brute-force)
4. **Base64 encoding** (makes output safe to store)
5. **Temporary files** (doesn't expose original data)
6. **Cleans up** (deletes temp files)
7. **Error handling** (fails safely)

### 🔒 Additional Recommendations:

1. **Never hardcode passwords** in your code (use files like this does!)
2. **Use strong passwords**: 
   - At least 12 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Example: `Tr0ub4dor&3` (strong) vs `password123` (weak)
3. **Protect your key files**: 
   - Keep `correctpass.txt` secure
   - Never commit to Git
   - Consider using file permissions: `chmod 600 correctpass.txt`

---

## Common Questions

### Q: Why use OpenSSL instead of MATLAB's built-in encryption?

**A**: OpenSSL is:
- Industry standard
- Well-tested by security experts
- Compatible with other systems
- Constantly updated for security
- Free and open-source

### Q: What's the difference between encoding and encryption?

**A**: 
- **Encoding** (like Base64): Just converts format, anyone can decode
- **Encryption**: Requires a key/password, only authorized parties can decrypt

### Q: Can I decrypt this with other programs?

**A**: Yes! Since it uses standard OpenSSL encryption, you can decrypt with:
- Command line: `openssl enc -d -aes-256-cbc -pbkdf2 -a -in encrypted.txt`
- Python: `cryptography` library
- Node.js: `crypto` module
- Any program supporting AES-256-CBC

### Q: How secure is this really?

**A**: Very secure! AES-256 with PBKDF2 is:
- Used by governments
- Used by banks
- Used by military
- Approved by NSA for TOP SECRET data

**However**: Security is only as strong as your password! A weak password defeats strong encryption.

### Q: What if I forget my password?

**A**: **You're locked out forever.** There's no "password recovery" with proper encryption. This is by design—if you could recover it, so could an attacker!

---

## Usage Examples

### Basic Usage
```matlab
% Encrypt with defaults
ciphertext = encode_json_to_ciphertext();
```

### Custom File
```matlab
% Encrypt specific file
ciphertext = encode_json_to_ciphertext("mydata.json", "MyPassword123!");
```

### Password from File
```matlab
% Use password stored in file
ciphertext = encode_json_to_ciphertext("data.json", "keys/master.txt");
```

### Save Encrypted Output
```matlab
% Encrypt and save to file
ciphertext = encode_json_to_ciphertext("secrets.json", "pass.txt");
fid = fopen("encrypted_output.txt", "w");
fprintf(fid, "%s", ciphertext);
fclose(fid);
```

---

## Technical Summary

| Feature | Implementation | Security Level |
|---------|---------------|----------------|
| Algorithm | AES-256-CBC | Military-grade |
| Key Derivation | PBKDF2 | Industry standard |
| Salt | Random, per-encryption | Prevents rainbow tables |
| Encoding | Base64 | Safe for text storage |
| Key Size | 256 bits | Would take longer than age of universe to crack |

**Overall Security Rating**: 🔒🔒🔒🔒🔒 (5/5) - Excellent when used with strong passwords!