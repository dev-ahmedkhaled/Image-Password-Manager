function plaintext = decode_from_hash(ciphertext, pass)
    % DECODE_FROM_HASH Decrypts an AES-256-CBC string back to JSON.
    %
    % Usage:
    %   json_str = decode_from_hash(ciphertext, "mykey")
    %   json_str = decode_from_hash(ciphertext, "../Passwords/correctpass.txt")

    % 1. Handle Default Password if not provided
    if nargin < 2 || isempty(pass)
        pass = "../Passwords/correctpass.txt";
    end

    % 2. Extract Key (File vs String)
    master_key = "";
    if ischar(pass) && (exist(pass, 'file') == 2) && endsWith(pass, ".txt")
        master_key = strtrim(fileread(pass));
    else
        master_key = pass;
    end

    % 3. Prepare Ciphertext for OpenSSL
    % We write the ciphertext to a temp file to avoid shell command length limits
    tmp_cipher = [tempname(), ".enc"];
    fid = fopen(tmp_cipher, 'w');
    fprintf(fid, "%s", ciphertext);
    fclose(fid);

    % 4. Perform AES-256 Decryption
    % -d: Decrypt flag
    % -a -A: Tell OpenSSL the input is a single-line Base64 string
    % 2>/dev/null: Suppress error messages from the terminal for a cleaner Octave experience
    
    cmd = sprintf('openssl enc -aes-256-cbc -d -salt -pbkdf2 -a -A -in "%s" -pass pass:"%s" 2>/dev/null', ...
                  tmp_cipher, master_key);
    
    [status, plaintext] = system(cmd);
    
    % Cleanup temp file
    if exist(tmp_cipher, 'file')
        delete(tmp_cipher);
    end

    % 5. Error Handling
    if status ~= 0 || isempty(plaintext)
        % If decryption fails (wrong password), status is usually non-zero
        error("Decryption failed! Likely causes: Wrong password or corrupted ciphertext.");
    end

    fprintf("--- Decryption Successful ---\n");
end