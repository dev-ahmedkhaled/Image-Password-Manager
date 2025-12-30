function encryption_decryption_gui()
    % Ensure we are using the correct toolkit for GUI rendering
    graphics_toolkit('qt');

    % 1. Setup paths and variables
    addpath("Encode");
    addpath("Decode");

    json_file        = "Passwords/secrets.json";
    wrong_key_file   = "Passwords/wrongpass.txt";
    correct_key_file = "Passwords/correctpass.txt";
    ciphertext       = ""; % Stores the encrypted string in memory

    % 2. Create the Main Figure
    % 'Units', 'normalized' makes the window and its contents scale-aware
    f = figure('Units', 'normalized', ...
               'position', [0.3, 0.3, 0.4, 0.5], ...
               'name', 'Octave Password Manager', ...
               'menubar', 'none', ...
               'numbertitle', 'off');

    % 3. UI Components (Positions are [x, y, width, height] from 0 to 1)

    % Header
    uicontrol('style', 'text', 'Units', 'normalized', ...
              'string', 'Password Manager Operations', ...
              'position', [0.1, 0.9, 0.8, 0.05], ...
              'fontsize', 12, 'fontweight', 'bold');

    % Status Log Area
    log_box = uicontrol('style', 'edit', 'Units', 'normalized', ...
                        'max', 2, ...
                        'position', [0.1, 0.05, 0.8, 0.5], ...
                        'horizontalalignment', 'left', ...
                        'backgroundcolor', [0.98, 0.98, 0.98], ...
                        'enable', 'inactive', ...
                        'string', {'--- System Log Ready ---'});

    % Buttons
    btn_encrypt = uicontrol('style', 'pushbutton', 'Units', 'normalized', ...
                            'string', 'Step 1: Encrypt JSON', ...
                            'position', [0.1, 0.75, 0.8, 0.1], ...
                            'callback', @encrypt_callback);

    btn_fail = uicontrol('style', 'pushbutton', 'Units', 'normalized', ...
                         'string', 'Step 2: Decrypt (Wrong Key)', ...
                         'position', [0.1, 0.62, 0.38, 0.1], ...
                         'callback', @fail_callback);

    btn_success = uicontrol('style', 'pushbutton', 'Units', 'normalized', ...
                            'string', 'Step 3: Decrypt (Correct Key)', ...
                            'position', [0.52, 0.62, 0.38, 0.1], ...
                            'callback', @success_callback);

    % --- Callback Functions ---

    function encrypt_callback(src, event)
        update_log("Starting encryption...");
        try
            % Calls your external function from the 'Encode' folder
            ciphertext = encode_json_to_ciphertext(json_file, correct_key_file);
            update_log("SUCCESS: JSON encrypted into memory.");
        catch ME
            update_log(sprintf("ENCRYPTION ERROR: %s", ME.message));
        end
    end

    function fail_callback(src, event)
        if isempty(ciphertext)
            update_log("ABORT: Please run Step 1 (Encrypt) first.");
            return;
        end
        update_log("Attempting decryption with WRONG key...");
        try
            % Calls your external function from the 'Decode' folder
            decode_from_ciphertext(ciphertext, wrong_key_file);
        catch ME
            % This is intended to fail; we catch and display the error message
            update_log(sprintf("[EXPECTED ERROR]: %s", ME.message));
        end
    end

    function success_callback(src, event)
        if isempty(ciphertext)
            update_log("ABORT: Please run Step 1 (Encrypt) first.");
            return;
        end
        update_log("Attempting decryption with CORRECT key...");
        try
            % Calls your external function from the 'Decode' folder
            decrypted_json = decode_from_ciphertext(ciphertext, correct_key_file);
            update_log("SUCCESS! Decrypted Data:");
            update_log(decrypted_json);
        catch ME
            update_log(sprintf("[UNEXPECTED ERROR]: %s", ME.message));
        end
    end

    function update_log(msg)
        % Get current content
        current_text = get(log_box, 'string');

        % Handle cases where current_text might be a single string or cell array
        if ischar(current_text)
            current_text = {current_text};
        end

        % Append new message and update the box
        new_text = [current_text; {char(msg)}];
        set(log_box, 'string', new_text);

        % Auto-scroll to the bottom
        set(log_box, 'listboxtop', length(new_text));
    end

end