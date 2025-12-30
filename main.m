%% ============================================
%% IMAGE-BASED PASSWORD MANAGER - ENCODER
%% ============================================

clear; clc;

%% ========== PATH SETUP ==========
project_root = pwd;
module_path = fullfile(project_root, 'modules');
encode_path = fullfile(project_root, 'Encode');
decode_path = fullfile(project_root, 'Decode');

if exist(module_path, 'dir'), addpath(module_path); end
if exist(encode_path, 'dir'), addpath(encode_path); end
if exist(decode_path, 'dir'), addpath(decode_path); end

fprintf('Project paths initialized.\n');
if exist(module_path, 'dir')
    addpath(module_path);
    fprintf('Added modules path: %s\n', module_path);
else
    error('Could not find modules folder!');
end

% Ensure the necessary packages are loaded
pkg load image;

fprintf('========================================\n');
fprintf('   VAULT ENCODER: SAVING PASSWORDS      \n');
fprintf('========================================\n\n');

%% --- Configuration ---
json_file = 'Passwords/secrets.json';
cover_image = 'images/nature.jpg';
stego_output = 'images/nature_stego.png';
master_pass_file = 'Passwords/correctpass.txt';

%% >>> PHASE 1: ENCRYPT AND EMBED <<<

% 1. Encrypt the JSON file
fprintf('Step 1: Encrypting %s...\n', json_file);
try
    ciphertext = encode_json_to_ciphertext(json_file, master_pass_file);
    fprintf('✓ Encryption successful! Ciphertext length: %d\n', length(ciphertext));
catch ME
    error('Encryption failed: %s', ME.message);
end

% 2. Embed into Image
fprintf('\nStep 2: Embedding data into %s...\n', cover_image);
try
    % This function handles the DCT conversion, embedding, and reconstruction
    stego_image = encode_to_image(ciphertext, cover_image);
    
    % 3. Save the final Stego Image
    imwrite(uint8(stego_image), stego_output);
    fprintf('✓ Success! Vault saved to: %s\n', stego_output);
    
catch ME
    error('Embedding failed: %s', ME.message);
end

fprintf('\n========================================\n');
fprintf('   VAULT UPDATED AND SECURED            \n');
fprintf('========================================\n');