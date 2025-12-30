# StegoVault: AES-256 & DCT Image Password Manager

StegoVault is a high-security password management system that combines **AES-256 encryption** with **Discrete Cosine Transform (DCT) Steganography**. It allows you to hide your encrypted password database inside a standard image file, making the data both unreadable and invisible.



## 🚀 Features
* **Double-Layer Security**: Data is first encrypted with military-grade AES-256-CBC, then hidden in the frequency domain of an image.
* **Imperceptible Hiding**: Uses DCT-based steganography (Mid-Frequency) to ensure high image quality (PSNR > 45dB).
* **Lossless Storage**: Outputs as PNG to prevent data corruption common in lossy JPEG formats.
* **Master Key Protection**: PBKDF2 key derivation ensures that even if the data is extracted, it cannot be decrypted without the Master Password.

## 🛠 Prerequisites
* **MATLAB** or **GNU Octave** (with `image` package installed).
* **OpenSSL**: Required for the cryptographic backend.

## 📁 Project Structure
* `main.m`: The **Encoder**. Encrypts your JSON data and embeds it into a cover image.
* `password_vault_viewer.m`: The **Decoder**. Extracts and decrypts the passwords for viewing.
* `/modules`: Contains the core logic for DCT transformations and bit embedding.
* `/Passwords`: Stores your `secrets.json` (source) and `correctpass.txt` (master key).
* `/images`: Contains the original cover image and the final `nature_stego.png` vault.

## 📖 How to Use

### 1. Setup Your Data
Place your passwords in `Passwords/secrets.json` following the standard JSON format and set your master password in `Passwords/correctpass.txt`.

### 2. Lock the Vault (Encode)
Run the `main.m` script in Octave/MATLAB:
```matlab
>> main