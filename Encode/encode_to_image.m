function [stego_image,stego_image_path] = encode_to_image(ciphertext, cover_image_path, output_path)
    % encode_to_image Embeds encrypted ciphertext into an image using DCT steganography.
    %
    % Usage:
    %   stego_path = encode_to_image(ciphertext, "images/nature.jpg", "output/stego.png")
    %   stego_path = encode_to_image(ciphertext, "images/nature.jpg")  % Auto-generates output name
    %
    % Input:
    %   ciphertext - Base64 encrypted string from encode_json_to_ciphertext
    %   cover_image_path - Path to the cover image
    %   output_path - (Optional) Path to save the stego image
    %
    % Output:
    %   stego_image_path - Path to the saved stego image

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
    % 2. Relative to Encode directory (../modules from Encode/)
    elseif exist(fullfile(current_dir, "..", "modules", "dct_transform.m"), "file")
        modules_dir = fullfile(current_dir, "..", "modules");
        modules_added = true;
    % 3. Try to find from cover_image_path location
    elseif exist(cover_image_path, "file")
        [img_path, ~, ~] = fileparts(cover_image_path);
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

    % 1. Handle default output path
    if nargin < 3 || isempty(output_path)
        [pathstr, name, ext] = fileparts(cover_image_path);
        output_path = fullfile(pathstr, [name, "_stego", ext]);
    end

    % 2. Validate inputs
    if ~exist(cover_image_path, 'file')
        error("Cover image not found at '%s'", cover_image_path);
    end

    if isempty(ciphertext)
        error("Ciphertext is empty!");
    end

    fprintf('\n=== Encoding Ciphertext into Image ===\n');
    fprintf('Cover image: %s\n', cover_image_path);

    % 3. Clean and convert ciphertext string to uint8 array
    % Remove any trailing newlines/whitespace from OpenSSL output
    ciphertext = strtrim(ciphertext);
    fprintf('Ciphertext length: %d characters\n', length(ciphertext));

    % Convert Base64 string to uint8 bytes (ASCII values)
    % This preserves the Base64 string for later decryption
    ciphertext_bytes = uint8(ciphertext(:));  % Ensure column vector

    fprintf('Ciphertext bytes: %d\n', length(ciphertext_bytes));

    % 4. Load and convert image to DCT domain
    fprintf('\nStep 1: Converting image to DCT domain...\n');

    % Find and ensure dct_transform.m is accessible
    path_list = strsplit(path(), pathsep());
    dct_file_path = "";
    modules_dir = "";

    % Find dct_transform.m file in path
    for i = 1:length(path_list)
        test_path = fullfile(path_list{i}, "dct_transform.m");
        if exist(test_path, "file")
            dct_file_path = test_path;
            modules_dir = path_list{i};
            break;
        end
    end

    % If not found in path, try to find it and add to path
    if isempty(dct_file_path)
        current_dir = pwd;
        if exist(fullfile(current_dir, "modules", "dct_transform.m"), "file")
            modules_dir = fullfile(current_dir, "modules");
            addpath(modules_dir);
            dct_file_path = fullfile(modules_dir, "dct_transform.m");
        elseif exist(fullfile(current_dir, "..", "modules", "dct_transform.m"), "file")
            modules_dir = fullfile(current_dir, "..", "modules");
            addpath(modules_dir);
            dct_file_path = fullfile(modules_dir, "dct_transform.m");
        end
    end

    if isempty(dct_file_path) || ~exist(dct_file_path, "file")
        error("Cannot find dct_transform.m file. Please ensure modules/dct_transform.m exists.");
    end

    % In Octave, functions in multi-function files sometimes need special handling
    % Convert cover_image_path to absolute path to avoid issues when changing directories
    if (ispc() && length(cover_image_path) >= 2 && cover_image_path(2) == ':') || ...
       (~ispc() && length(cover_image_path) >= 1 && cover_image_path(1) == '/')
        % Already absolute path
        abs_cover_path = cover_image_path;
    else
        % Relative path - make it absolute
        abs_cover_path = fullfile(pwd, cover_image_path);
    end

    % In Octave, multi-function files need special handling
    % The issue is that Octave doesn't always parse multi-function files correctly
    % We'll change to the modules directory and use eval to force parsing
    old_dir = pwd;
    cd(modules_dir);

    try
        % First, try to check if function exists (this sometimes triggers parsing)
        func_check = exist("imageToDCT");

        % Try calling the function
        if func_check > 0
            % Function exists in Octave's function cache
            dctCoeffs = imageToDCT(abs_cover_path);
        else
            % Function not found, try to force load by using eval with full path
            % This is a workaround for Octave's multi-function file parsing
            eval(sprintf("dctCoeffs = imageToDCT('%s');", abs_cover_path));
        end
    catch ME
        % If that failed, try one more thing: explicitly run the file
        % Note: This will execute test() at the end, but that's okay
        try
            % Temporarily disable test execution by commenting it out would require file modification
            % Instead, just try to run and catch any test errors
            run("dct_transform.m");
            % Now try calling the function
            dctCoeffs = imageToDCT(abs_cover_path);
        catch ME2
            cd(old_dir);
            % Provide helpful error with manual workaround
            fprintf("\n=== TROUBLESHOOTING ===\n");
            fprintf("Octave cannot find imageToDCT function.\n");
            fprintf("File location: %s\n", dct_file_path);
            fprintf("Current directory: %s\n", modules_dir);
            fprintf("\nTry this manual workaround:\n");
            fprintf("1. cd('%s')\n", modules_dir);
            fprintf("2. run('dct_transform.m')\n");
            fprintf("3. dctCoeffs = imageToDCT('%s')\n", abs_cover_path);
            fprintf("========================\n\n");
            error("imageToDCT function not accessible.\nError 1: %s\nError 2: %s", ME.message, ME2.message);
        end
    end

    % Return to original directory
    cd(old_dir);

    % 5. Embed ciphertext into DCT coefficients
    fprintf('\nStep 2: Embedding ciphertext into DCT coefficients...\n');

    % Ensure steganography functions are accessible
    % Use the same modules_dir we found earlier (from DCT processing)
    old_dir2 = pwd;
    if ~isempty(modules_dir) && exist(modules_dir, "dir")
        cd(modules_dir);
        try
            % Always try to run steganography.m to ensure functions are loaded
            run("steganography.m");
        catch
            % If run fails, continue anyway - function might still be available
        end
        cd(old_dir2);
    end

    % Now try calling embedData
    try
        modifiedDCT = embedData(dctCoeffs, ciphertext_bytes);
    catch ME
        if ~isempty(strfind(ME.message, "undefined")) || ~isempty(strfind(ME.message, "embedData"))
            % Try one more time from modules directory
            if ~isempty(modules_dir) && exist(modules_dir, "dir")
                cd(modules_dir);
                try
                    % Force run again and then call
                    run("steganography.m");
                    modifiedDCT = embedData(dctCoeffs, ciphertext_bytes);
                    cd(old_dir2);
                catch ME2
                    cd(old_dir2);
                    error("embedData function not found.\nModules dir: %s\nError 1: %s\nError 2: %s", ...
                          modules_dir, ME.message, ME2.message);
                end
            else
                cd(old_dir2);
                error("embedData function not found. Please ensure modules/steganography.m is in the path.\nError: %s", ME.message);
            end
        else
            cd(old_dir2);
            rethrow(ME);
        end
    end

    % 6. Reconstruct image from modified DCT
    fprintf('\nStep 3: Reconstructing stego image...\n');

    % dctToImage should be available from dct_transform.m (already loaded)
    try
        stego_image = dctToImage(modifiedDCT);
    catch ME
        if ~isempty(strfind(ME.message, "undefined")) || ~isempty(strfind(ME.message, "dctToImage"))
            % Try from modules directory
            if ~isempty(modules_dir) && exist(modules_dir, "dir")
                cd(modules_dir);
                try
                    stego_image = dctToImage(modifiedDCT);
                    cd(old_dir);
                catch ME2
                    cd(old_dir);
                    error("dctToImage function not found.\nError: %s", ME2.message);
                end
            else
                error("dctToImage function not found.\nError: %s", ME.message);
            end
        else
            rethrow(ME);
        end
    end

    % 7. Calculate quality metrics
    fprintf('\nStep 4: Calculating quality metrics...\n');
    %original_img = imread(cover_image_path);
    %if size(original_img, 3) == 3
        %original_img = rgb2gray(original_img);
    %end
    % Ensure same size for comparison
    %[orig_rows, orig_cols] = size(original_img);
    %[stego_rows, stego_cols] = size(stego_image);
    %min_rows = min(orig_rows, stego_rows);
    %min_cols = min(orig_cols, stego_cols);
    original_processed = dctCoeffs.originalImage;

    metrics = calculateQualityMetrics(...
        double(original_processed), ...
        double(stego_image));

    % 8. Save stego image
    fprintf('\nStep 5: Saving stego image...\n');


% Ensure output is PNG
    [~, ~, ext] = fileparts(output_path);
    if ~strcmpi(ext, '.png')
        warning('Output must be PNG for lossless storage. Changing extension to .png');
        output_path = strrep(output_path, ext, '.png');
    end

% Clamp and convert to uint8
    stego_image = max(0, min(255, stego_image));
    stego_image = uint8(stego_image);

    imwrite(stego_image, output_path, 'png');
    fprintf('Stego image saved to: %s\n', output_path);

    stego_image_path = output_path;
    fprintf('\n=== Encoding Complete ===\n');
end
