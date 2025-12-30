function PasswordManagerGUI()
    % Ensure we are using the correct toolkit
    graphics_toolkit('qt');

    % 1. Setup paths and variables
    addpath("Encode");
    addpath("Decode");
    
    json_file        = "Passwords/secrets.json";
    wrong_key_file   = "Passwords/wrongpass.txt";
    correct_key_file = "Passwords/correctpass.txt";
    ciphertext       = "";

    % 2. Create the Main Figure
    f = figure('position', [300, 300, 500, 450], ...
               'name', 'Octave Password Manager', ...
               'menubar', 'none', ...
               'numbertitle', 'off');

    % 3. UI Components
    uicontrol('style', 'text', 'string', 'Password Manager Operations', ...
              'position', [50, 400, 400, 30], 'fontsize', 14, 'fontweight', 'bold');

    % Status Log Area
    log_box = uicontrol('style', 'edit', 'max', 2, ...
                        'position', [50, 50, 400, 200], ...
                        'horizontalalignment', 'left', ...
                        'backgroundcolor', [0.95, 0.95, 0.95], ...
                        'enable', 'inactive');

    % Buttons
    btn_encrypt = uicontrol('style', 'pushbutton', 'string', 'Step 1: Encrypt JSON', ...
                            'position', [50, 330, 400, 40], ...
                            'callback', @encrypt_callback);

    btn_fail = uicontrol('style', 'pushbutton', 'string', 'Step 2: Decrypt (Wrong Key)', ...
                         'position', [50, 280, 195, 40], ...
                         'callback', @fail_callback);

    btn_success = uicontrol('style', 'pushbutton', 'string', 'Step 3: Decrypt (Correct Key)', ...
                            'position', [255, 280, 195, 40], ...
                            'callback', @success_callback);

    % --- Callback Functions ---

    function encrypt_callback(src, event)
        try
            ciphertext = encode_json_to_ciphertext(json_file, correct_key_file);
            update_log("Encryption successful.");
        catch ME
            update_log(sprintf("Critical Error: %s", ME.message));
        end
    end

    function fail_callback(src, event)
        if isempty(ciphertext)
            update_log("Error: Encrypt first!");
            return;
        end
        update_log("Attempting Decryption with WRONG password...");
        try
            decode_from_ciphertext(ciphertext, wrong_key_file);
        catch ME
            update_log(sprintf("[HANDLED ERROR] %s", ME.message));
        end
    end

    function success_callback(src, event)
        if isempty(ciphertext)
            update_log("Error: Encrypt first!");
            return;
        end
        update_log("Attempting Decryption with CORRECT password...");
        try
            decrypted_json = decode_from_ciphertext(ciphertext, correct_key_file);
            % Display result in log
            update_log("Decryption successful! Data:");
            update_log(decrypted_json);
        catch ME
            update_log(sprintf("[SYSTEM NOTE] Unexpected failure: %s", ME.message));
        end
    end

    function update_log(msg)
        current_text = get(log_box, 'string');
        new_text = [current_text; {msg}];
        set(log_box, 'string', new_text);
    end

end