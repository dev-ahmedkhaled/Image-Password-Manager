%% Octave AES-256 Encryption Script
% Location: Encode/encode_json_to_hash.m

function ciphertext = encode_json_to_hash(json_path, pass)
    % ENCODE_JSON_TO_HASH Encrypts a JSON file using AES-256-CBC via OpenSSL.
    %
    % Usage:
    %   out = encode_json_to_hash()                   % Uses defaults
    %   out = encode_json_to_hash("data.json", "key") % Manual paths/pass
    
    % 1. Handle Default Parameters
    if nargin < 1 || isempty(json_path)
        json_path = "../Passwords/secrets.json";
    end
    
    if nargin < 2 || isempty(pass)
        % Default to the correctpass.txt file if no password provided
        pass = "../Passwords/correctpass.txt";
    end

    % 2. Check if 'pass' is a path to a .txt file or a literal string
    master_key = "";
    if ischar(pass) && (exist(pass, 'file') == 2) && endsWith(pass, ".txt")
        % Read from file and trim whitespace/newlines
        master_key = strtrim(fileread(pass));
    else
        % Treat input as the literal password string
        master_key = pass;
    end

    % 3. Validate JSON file exists
    if exist(json_path, 'file') ~= 2
        error("Error: JSON file not found at '%s'", json_path);
    end

    % 4. Perform AES-256 Encryption via OpenSSL
    % -aes-256-cbc: The encryption algorithm
    % -a: Base64 encode the output (makes it a readable "hash-like" string)
    % -A: Ensure the Base64 output is on a single line
    % -salt: Standard security practice to prevent rainbow table attacks
    % -pbkdf2: Standard key derivation (modern security requirement)
    
    fprintf("Encrypting: %s\n", json_path);
    
    % We use temporary files to pass data to OpenSSL securely
    tmp_json = [tempname(), ".json"];
    copyfile(json_path, tmp_json);
    
    % Build the system command
    cmd = sprintf('openssl enc -aes-256-cbc -salt -pbkdf2 -a -A -in "%s" -pass pass:"%s"', ...
                  tmp_json, master_key);
    
    [status, ciphertext] = system(cmd);
    
    % Cleanup temp file
    delete(tmp_json);

    if status ~= 0
        error("Encryption failed. Check if OpenSSL is installed and the key is valid.");
    end

    % Display result
    fprintf("--- Encrypted Output ---\n%s\n------------------------\n", ciphertext);
end