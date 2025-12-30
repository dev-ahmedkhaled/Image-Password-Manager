# StegoVault: AES-256 & DCT Image Password Manager

StegoVault is a high-security password management system that combines **AES-256 encryption** with **Discrete Cosine Transform (DCT) Steganography**. Hide your encrypted password database inside a standard image file—making the data both unreadable and invisible to the naked eye.

## 🛠 Prerequisites

Before running the project, ensure you have the following installed:

1. **GNU Octave** (or MATLAB).
2. **Image Package**: In Octave, run `pkg install -forge image` then `pkg load image`.
3. **OpenSSL**: Ensure OpenSSL is installed on your system path (Type `openssl version` in your terminal to check).

---

## 📖 How to Use

### 1. Preparation

* **The Data**: Edit `Passwords/secrets.json` to include your accounts and passwords.
* **The Master Key**: Open `Passwords/correctpass.txt` and type your secret Master Password. This is the only key that can unlock your vault.
* **The Cover**: Place a JPEG image (e.g., `nature.jpg`) in the `images/` folder.

### 2. Hiding your Passwords (Encoding)

Run your main controller script (replace `your_renamed_file` with the actual name you gave it):

```matlab
>> your_renamed_file

```

* **What happens?** The script encrypts the JSON via OpenSSL, performs a DCT transform on your image, hides the bits in the frequency domain, and saves a new file: `images/nature_stego.png`.
* **Security Tip**: You can now safely delete `secrets.json`. Your data is now hidden inside the PNG.

### 3. Viewing your Passwords (Decoding)

To retrieve your passwords from the image:

```matlab
>> password_vault_viewer

```

* **What happens?** The script reads the pixels of the stego-image, extracts the encrypted string, and uses your Master Password to decrypt and display your credentials in the command window.

### 4. Using the Interactive GUI

For a user-friendly experience without using the command line:

```matlab
>> encryption_decryption_gui

```

This allows you to add, remove, and manage passwords through a visual interface.

---

## 📁 Project Structure

* **`your_renamed_file.m`**: The main encoder/locker script.
* **`password_vault_viewer.m`**: The main decoder/viewer script.
* **`encryption_decryption_gui.m`**: Interactive vault manager.
* **`/modules`**: Core logic for DCT (Discrete Cosine Transform) and steganography.
* **`/Passwords`**: Storage for your key and raw JSON data.
* **`/images`**: Storage for cover images and the final stego-vault.

---

## ⚠️ Troubleshooting

* **"Function Undefined"**: Ensure you are running the scripts from the **project root folder**. The scripts automatically add `/modules`, `/Encode`, and `/Decode` to your Octave path.
* **"OpenSSL not found"**: Ensure OpenSSL is installed. On Windows, you may need to add the OpenSSL `bin` folder to your System Environment Variables.
* **"Image not found"**: Verify that your cover image filename in the script matches the actual file in the `images/` folder.

---

## 📊 Security Stats

* **Encryption**: AES-256-CBC (Military Grade).
* **Steganography**: Mid-frequency DCT coefficient modification.
* **PSNR**: ~46.0 dB (Mathematically imperceptible changes).