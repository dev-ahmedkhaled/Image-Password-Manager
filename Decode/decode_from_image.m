function ciphertext = decode_from_image(stego_image_path)
    % decode_from_image Extracts encrypted ciphertext from a stego image.
    %
    % Usage:
    %   ciphertext = decode_from_image("output/stego.png")
    %   ciphertext = decode_from_image("images/nature_stego.jpg")
    %
    % Input:
    %   stego_image_path - Path to the stego image containing hidden data
    %
    % Output:
    %   ciphertext - Base64 encrypted string (ready for decode_from_ciphertext)

    % Add necessary paths
    % Try to ensure modules directory is in path
    % (main.m should have already added it, but this is a safety check)
    current_dir = pwd;
    modules_dir = "";
    modules_added = false;
    
    % Check if modules/dct_transform.m exists in common locations
    % 1. Relative to current directory
    if exist(fullfile(current_dir, "modules", "dct_transform.m"), "file")
        modules_dir = fullfile(current_dir, "modules");
        modules_added = true;
    % 2. Relative to Decode directory (../modules from Decode/)
    elseif exist(fullfile(current_dir, "..", "modules", "dct_transform.m"), "file")
        modules_dir = fullfile(current_dir, "..", "modules");
        modules_added = true;
    % 3. Try to find from stego_image_path location
    elseif exist(stego_image_path, "file")
        [img_path, ~, ~] = fileparts(stego_image_path);
        if exist(fullfile(img_path, "..", "modules", "dct_transform.m"), "file")
            modules_dir = fullfile(img_path, "..", "modules");
            modules_added = true;
        end
    end
    
    if modules_added && exist(modules_dir, "dir")
        % Check if already in path
        path_cell = strsplit(path(), pathsep());
        if ~any(strcmp(path_cell, modules_dir))
            addpath(modules_dir);
            fprintf("Added modules path: %s\n", modules_dir);
        end
    end
    
    pkg load image;

    % 1. Validate input
    if ~exist(stego_image_path, 'file')
        error("Stego image not found at '%s'", stego_image_path);
    end

    fprintf('\n=== Extracting Ciphertext from Image ===\n');
    fprintf('Stego image: %s\n', stego_image_path);

    % 2. Load and convert stego image to DCT domain
    fprintf('\nStep 1: Converting stego image to DCT domain...\n');
    dctCoeffs = imageToDCT(stego_image_path);

    % 3. Extract embedded data from DCT coefficients
    fprintf('\nStep 2: Extracting embedded data from DCT coefficients...\n');
    extracted_bytes = extractData(dctCoeffs);
    fprintf('Debug: first 4 extracted bytes (magic):\n');
    fprintf('extracted magic: %d %d %d %d\n',extracted_bytes(1:4));

    % 4. Convert bytes back to string (ciphertext)
    % The extracted bytes represent the Base64 ciphertext string
    % Ensure it's a row vector for char conversion
    if size(extracted_bytes, 1) > size(extracted_bytes, 2)
        extracted_bytes = extracted_bytes';
    end
    ciphertext = char(extracted_bytes);
    ciphertext = strtrim(ciphertext);  % Remove any trailing nulls/whitespace

    fprintf('\nStep 3: Extraction complete!\n');
    fprintf('Extracted ciphertext length: %d characters\n', length(ciphertext));
    fprintf('\n=== Extraction Complete ===\n');
end

