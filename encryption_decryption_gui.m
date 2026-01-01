function encryption_decryption_gui()
    graphics_toolkit('qt');

    % 1. Setup paths and variables
    project_root = pwd;
    addpath(fullfile(project_root, 'modules'));
    addpath(fullfile(project_root, 'Encode'));
    addpath(fullfile(project_root, 'Decode'));

    % Internal State: This holds your list of passwords in memory
    vault_data = struct('entries', []);
    ciphertext = "";

    stego_output = "images/nature_stego.png";
    cover_image  = "images/nature.jpg";
    key_file     = "Passwords/correctpass.txt";

    % 2. Main Figure
    f = figure('Units', 'normalized', 'position', [0.1, 0.1, 0.8, 0.8], ...
               'name', 'StegoVault Professional: Database Editor', 'menubar', 'none');

    % --- LEFT PANEL: Database Editor ---
    uicontrol('style', 'text', 'Units', 'normalized', 'position', [0.05, 0.85, 0.4, 0.05], ...
              'string', 'Vault Editor', 'fontsize', 12, 'fontweight', 'bold');

    uicontrol('style', 'text', 'Units', 'normalized', 'position', [0.05, 0.78, 0.1, 0.03], 'string', 'Title:');
    edit_title = uicontrol('style', 'edit', 'Units', 'normalized', 'position', [0.15, 0.78, 0.3, 0.04], 'backgroundcolor', 'white');

    uicontrol('style', 'text', 'Units', 'normalized', 'position', [0.05, 0.72, 0.1, 0.03], 'string', 'Password:');
    edit_pass = uicontrol('style', 'edit', 'Units', 'normalized', 'position', [0.15, 0.72, 0.3, 0.04], 'backgroundcolor', 'white');

    uicontrol('style', 'pushbutton', 'Units', 'normalized', 'position', [0.05, 0.65, 0.2, 0.05], ...
              'string', 'Add to Vault', 'callback', @add_entry);

    uicontrol('style', 'pushbutton', 'Units', 'normalized', 'position', [0.26, 0.65, 0.19, 0.05], ...
              'string', 'Remove Selected', 'callback', @remove_entry);

    % The Listbox shows current items in memory
    list_ui = uicontrol('style', 'listbox', 'Units', 'normalized', 'position', [0.05, 0.1, 0.4, 0.53]);

    % --- RIGHT PANEL: Stego Operations ---
    uicontrol('style', 'pushbutton', 'Units', 'normalized', 'position', [0.5, 0.75, 0.45, 0.1], ...
              'string', 'STEP 1: Encrypt & Save to Image', 'callback', @save_to_image);

    uicontrol('style', 'pushbutton', 'Units', 'normalized', 'position', [0.5, 0.62, 0.45, 0.1], ...
              'string', 'STEP 2: Load & Decrypt from Image', 'callback', @load_from_image);

    log_box = uicontrol('style', 'edit', 'Units', 'normalized', 'max', 2, ...
                        'position', [0.5, 0.1, 0.45, 0.48], 'enable', 'inactive', 'string', {'--- Log ---'});

    % --- LOGIC FUNCTIONS ---

    function add_entry(~, ~)
        t = get(edit_title, 'string');
        p = get(edit_pass, 'string');
        if isempty(t) || isempty(p), return; end

        % Add to the struct
        new_idx = length(vault_data.entries) + 1;
        vault_data.entries(new_idx).title = t;
        vault_data.entries(new_idx).password = p;

        update_ui_list();
        set(edit_title, 'string', ''); set(edit_pass, 'string', '');
        update_log("Added: " + t);
    end

    function remove_entry(~, ~)
        val = get(list_ui, 'value');
        if isempty(vault_data.entries), return; end
        vault_data.entries(val) = [];
        update_ui_list();
        update_log("Removed entry.");
    end

    function update_ui_list()
        if isempty(vault_data.entries)
            set(list_ui, 'string', {});
        else
            % Display titles in the listbox
            set(list_ui, 'string', {vault_data.entries.title});
        end
    end

    function save_to_image(~, ~)
        if isempty(vault_data.entries), update_log("Vault is empty!"); return; end
        try
            % 1. Convert struct to JSON string
            json_str = jsonencode(vault_data);

            % 2. Save temporary JSON to encrypt it
            temp_json = 'Passwords/temp_gui.json';
            fid = fopen(temp_json, 'w'); fprintf(fid, '%s', json_str); fclose(fid);

            % 3. Encrypt and Embed
            ciphertext = encode_json_to_ciphertext(temp_json, key_file);
            stego_img = encode_to_image(ciphertext, cover_image);
            imwrite(uint8(stego_img), stego_output);

            delete(temp_json);
            update_log("VAULT LOCKED: Data hidden in " + stego_output);
        catch ME, update_log("ERROR: " + ME.message); end
    end

    function load_from_image(~, ~)
        try
            update_log("Extracting from image...");
            extracted_cipher = decode_from_image(stego_output);
            json_str = decode_from_ciphertext(extracted_cipher, key_file);

            % Sync memory with extracted data
            vault_data = jsondecode(json_str);
            update_ui_list();
            update_log("VAULT UNLOCKED: Data loaded into editor.");
        catch ME, update_log("ERROR: " + ME.message); end
    end

    function update_log(msg)
        set(log_box, 'string', [get(log_box, 'string'); {char(msg)}]);
        set(log_box, 'listboxtop', length(get(log_box, 'string')));
    end
end