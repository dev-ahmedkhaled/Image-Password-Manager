%% ============================================
%% STEGO VAULT VIEWER
%% ============================================
% Use this script to read passwords directly from your stego image.

clear; clc;
addpath('modules'); % Ensure functions are accessible

% --- Configuration ---
STEGO_IMAGE = 'images/nature_stego.png'; % Path to your "vault"
MASTER_PASS_FILE = 'Passwords/correctpass.txt'; % Or type password as a string

fprintf('========================================\n');
fprintf('       STEGO VAULT: PASSWORD VIEWER     \n');
fprintf('========================================\n\n');

% 1. Check if image exists
if ~exist(STEGO_IMAGE, 'file')
    error('Error: Stego image "%s" not found!', STEGO_IMAGE);
end

try
    % 2. Extract the ciphertext from the image
    fprintf('Step 1: Extracting encrypted data from image...\n');
    ciphertext = decode_from_image(STEGO_IMAGE);

    % 3. Decrypt the ciphertext
    fprintf('Step 2: Decrypting with Master Password...\n');
    % This will prompt for password if MASTER_PASS_FILE is not a valid file
    json_str = decode_from_ciphertext(ciphertext, MASTER_PASS_FILE);

    % 4. Parse the JSON
% 4. Parse the JSON
    data = jsondecode(json_str);

    % 5. Display the results in a clean format
    fprintf('\n--- DECRYPTION SUCCESSFUL ---\n');

    % Check if 'version' exists before printing
    if isfield(data, 'version')
        fprintf('Version: %s\n', data.version);
    end
    fprintf('----------------------------------------\n');

    % Navigate to entries (Handles data.entries or data.password_manager.entries)
    if isfield(data, 'password_manager') && isfield(data.password_manager, 'entries')
        entries = data.password_manager.entries;
    elseif isfield(data, 'entries')
        entries = data.entries;
    else
        % If we can't find an 'entries' list, just print the whole structure
        disp(data);
        entries = [];
    end

    for i = 1:length(entries)
        e = entries(i);
        % Use 'Title' or 'title' (handles case sensitivity)
        title_str = "Entry " + num2str(i);
        if isfield(e, 'title'), title_str = e.title; end
        if isfield(e, 'Title'), title_str = e.Title; end

        category = "General";
        if isfield(e, 'category'), category = e.category; end

        fprintf('[%s] %s\n', category, title_str);

        % Print fields if they exist
        if isfield(e, 'username'), fprintf('  > Username: %s\n', e.username); end
        if isfield(e, 'password'), fprintf('  > Password: %s\n', e.password); end
        if isfield(e, 'url'),      fprintf('  > URL:      %s\n', e.url); end
        if isfield(e, 'notes'),    fprintf('  > Notes:    %s\n', e.notes); end
        fprintf('----------------------------------------\n');
    end
catch ME
    fprintf('\nx access denied: %s\n', ME.message);
    fprintf('Please check your stego image and master password.\n');
end

fprintf('\n=== END OF VAULT VIEWER ===\n');