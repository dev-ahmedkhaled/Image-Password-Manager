# Image-Based Password Manager

**Description:**  
An image-based password manager implemented in MATLAB that securely stores multiple passwords inside an image using **LSB (Least Significant Bit)** and **DCT (Discrete Cosine Transform)** steganography techniques with optional encryption.

This project allows users to hide encrypted passwords in images, extract them later, and evaluate image quality using **PSNR** and **MSE** metrics. It also supports multiple password entries in a single image.

---

## Features

- Store **multiple passwords** in a single image  
- **Encryption** for added security (XOR-based or optional)  
- **LSB steganography**: simple, fast, works in spatial domain  
- **DCT steganography**: hides data in frequency domain for robustness  
- **Image quality evaluation** using PSNR and MSE  
- MATLAB implementation, easy to run and reproduce  

---

## How It Works

1. **Password Encryption**  
   - Each password is encrypted using a simple XOR cipher (optional).  

2. **Binary Conversion**  
   - Passwords are converted into binary form for embedding.  

3. **Embedding in Image**  
   - **LSB:** Each bit is embedded into the least significant bit of pixels.  
   - **DCT:** Image is divided into 8×8 blocks, DCT is applied, and bits are embedded in mid-frequency coefficients.  

4. **Extraction**  
   - The embedded data is extracted from the image, converted back to text, and decrypted.  

5. **Image Evaluation**  
   - PSNR and MSE metrics measure distortion between original and encoded images.  

---

## Usage

1. Open MATLAB and load the `main.m` script (or similar script in your repo).  
2. Choose an image to store passwords in:  
   ```matlab
   img = imread('input.png');
