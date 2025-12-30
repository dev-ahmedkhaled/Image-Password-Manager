%% Main Password Manager Controller
clear; clc;

addpath("Encode");
addpath("Decode");

json_file        = "Passwords/secrets.json";
wrong_key_file   = "Passwords/wrongpass.txt";
correct_key_file = "Passwords/correctpass.txt";

%% PHASE 1: ENCRYPTION
try
    ciphertext = encode_json_to_hash(json_file, correct_key_file);
    fprintf("Encryption successful.\n");
catch ME
    fprintf("Critical Error during encryption: %s\n", ME.message);
end

%% PHASE 2: DECRYPTION (Fail Case)
fprintf("\n--- Attempting Decryption with WRONG password ---\n");
try
    % This will fail, jump to catch, but the script will CONTINUE after
    decrypted_json = decode_from_hash(ciphertext, wrong_key_file);
catch ME
    fprintf("[HANDLED ERROR] %s\n", ME.message);
end

%% PHASE 3: DECRYPTION (Success Case)
fprintf("\n--- Attempting Decryption with CORRECT password ---\n");
try
    decrypted_json = decode_from_hash(ciphertext, correct_key_file);

    % Convert JSON string to Octave Struct
    data = jsondecode(decrypted_json);

    % FIX: Use (1) instead of {1}
    disp(decrypted_json); % This prints the raw string
    # fprintf("Entry 1 Title: %s\n", data.password_manager.entries(1).title);

    fprintf("Decryption successful!\n");
catch ME
    fprintf("[SYSTEM NOTE] Unexpected failure: %s\n", ME.message);
end

% Cleanup
rmpath("Encode");
rmpath("Decode");