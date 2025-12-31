

### **What PBKDF2 Actually Does** (RFC 2898 / PKCS#5)

PBKDF2 is a standardized key derivation function designed to securely derive cryptographic keys from passwords, using:

- A **password** (low-entropy input),
- A **salt** (random, unique per user),
- An **iteration count** (e.g., 10,000 or more),
- A **pseudorandom function (PRF)** — typically HMAC-SHA256 (not raw SHA-1/SHA-256).

#### 🔧 Correct Algorithm (simplified):
```
DK = PBKDF2(PRF, Password, Salt, c, dkLen)
```

Where:

- `PRF` = HMAC-SHA256 (most common; **not just hash(key + pw + salt)**),
- `c` = iteration count (e.g., 10,000+),
- `dkLen` = desired key length.

Internally, PBKDF2 computes:
```
DK = T₁ || T₂ || ... || Tₖ       (until desired key length)
Tᵢ = U₁ ⊕ U₂ ⊕ ... ⊕ U_c
U₁ = PRF(Password, Salt || INT₃₂_BE(i))
U₂ = PRF(Password, U₁)
U₃ = PRF(Password, U₂)
...
U_c = PRF(Password, U_{c−1})
```
 Each block `Tᵢ` requires **c iterations** of the PRF (HMAC), and each iteration depends on the previous one — **no parallelization within a single PBKDF2 computation**, making brute-force expensive.

---

### ❌ Why the Given Pseudocode Is Misleading

> ```
> For i = 1 to 10,000:
>     key = hash(key + password + salt)
> ```

This is **not** how PBKDF2 works. Problems with this simplification:

1. **No HMAC**: PBKDF2 uses HMAC (keyed hash), not a bare hash. `hash(key + password + salt)` is vulnerable to length-extension attacks and is cryptographically weak.
2. **Incorrect chaining**: PBKDF2 doesn’t mutate a single `key` variable like that; it uses structured chaining with XOR of iterated HMACs.
3. **No salt integration per iteration**: In PBKDF2, the salt is only used in the *first* iteration of each block (as `Salt || INT₃₂_BE(i)`), not recombined every round.

A better (still simplified) analogy:
```text
U = HMAC(password, salt || 0x00000001)
T = U
for i = 2 to 10,000:
    U = HMAC(password, U)
    T = T XOR U
key = first 32 bytes of T
```

---

### OpenSSL Usage Example

In OpenSSL, you can use PBKDF2 via command line or API:

#### 🔐 Command line (OpenSSL 1.1.1+):
```bash
openssl passwd -pbkdf2 -iter 10000
# Interactive: prompts for password, outputs $pbkdf2-sha256$...
```

Or derive a key explicitly:
```bash
openssl pkeyutl -derive -kdf pbkdf2 \
  -kdflen 32 \
  -passin pass:"mypassword" \
  -pkeyopt salt:$(openssl rand -hex 8) \
  -pkeyopt pbkdf2_iter:10000 \
  -pkeyopt digest:sha256
```
⚠️ Note: OpenSSL’s `pkeyutl -derive` with PBKDF2 is limited; better to use `EVP_PBE_scrypt` or `PKCS5_PBKDF2_HMAC()` in code.

#### 💻 C API (recommended):
```c
#include <openssl/evp.h>

unsigned char key[32];
unsigned char salt[16];
RAND_bytes(salt, sizeof(salt));

PKCS5_PBKDF2_HMAC("mypassword", -1,         // password
                  salt, sizeof(salt),       // salt
                  10000,                    // iterations
                  EVP_sha256(),             // PRF: HMAC-SHA256
                  32, key);                 // output key length
```

---

### 📉 Real-World Impact 

Let’s refine the performance comparison:

| Method                | Time per Try | Example Speed (GPU) | Why? |
|-----------------------|--------------|---------------------|------|
| Raw SHA-256(password) | ~0.1 ns      | ~10⁹ / sec          | Highly parallelizable |
| PBKDF2-HMAC-SHA256, 10k iters | ~100 µs | ~10⁴ / sec | Sequential iterations; memory-light but time-hardened |
| **PBKDF2 with 600k iters** (e.g., iOS) | ~6 ms | ~170 / sec | Much stronger |
| **Argon2/scrypt**     | ~100 ms      | ~10 / sec           | Also memory-hard → resists ASICs/GPUs better |

> 🔔 Modern best practice: **Use ≥ 600,000 iterations for PBKDF2-HMAC-SHA256** (NIST SP 800-63B, 2023), or prefer **Argon2id** (memory-hard).

---

### ✅ Summary

- ✅ PBKDF2 *does* slow brute-force attacks via **many iterations**.
- ✅ It requires a **salt** and uses **HMAC**, not raw hashing.
- ❌ The pseudocode oversimplifies and misrepresents the actual algorithm.
- In OpenSSL: use `PKCS5_PBKDF2_HMAC()` with high iteration counts.
- Prefer **Argon2** for new systems (winner of Password Hashing Competition), but PBKDF2 is still FIPS-approved and widely supported.
