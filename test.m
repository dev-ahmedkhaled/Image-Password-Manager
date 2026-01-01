%% ========================================================================
%  SIMPLE INDIVIDUAL TEST SCRIPTS
%  Use these for quick, focused testing of specific functionality
%% ========================================================================

%% ========================================================================
%  TEST_ENCRYPTION.m - Test just encryption/decryption
%% ========================================================================

% File: test_encryption.m
clear; clc;
fprintf('\n=== Testing Encryption/Decryption ===\n\n');

pkg load image;
addpath('Encode');
addpath('Decode');

% Create simple test JSON
data.service = 'TestService';
data.password = 'TestPassword123!';
fid = fopen('test_data.json', 'w');
fprintf(fid, '%s', jsonencode(data));
fclose(fid);

% Create master password
fid = fopen('master.txt', 'w');
fprintf(fid, 'MyMasterPass');
fclose(fid);

try
    % Encrypt
    fprintf('Encrypting...\n');
    cipher = encode_json_to_ciphertext('test_data.json', 'master.txt');
    fprintf('✓ Encrypted! Length: %d\n\n', length(cipher));
    
    % Decrypt
    fprintf('Decrypting...\n');
    json_str = decode_from_ciphertext(cipher, 'master.txt');
    result = jsondecode(json_str);
    fprintf('✓ Decrypted! Password: %s\n\n', result.password);
    
    % Verify
    if strcmp(result.password, 'TestPassword123!')
        fprintf('✓✓✓ TEST PASSED ✓✓✓\n');
    else
        fprintf('✗✗✗ TEST FAILED ✗✗✗\n');
    end
    
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
end

% Cleanup
delete('test_data.json');
delete('master.txt');

%% ========================================================================
%  TEST_STEGANOGRAPHY.m - Test just image embedding/extraction
%% ========================================================================

% File: test_steganography.m
clear; clc;
fprintf('\n=== Testing Steganography ===\n\n');

pkg load image;
addpath('modules');
addpath('Encode');
addpath('Decode');

try
    % Create test image
    fprintf('Creating test image...\n');
    test_img = uint8(randi([0, 255], 256, 256, 3));
    imwrite(test_img, 'test_cover.png');
    
    % Create test message
    test_message = 'This is a secret message that should be hidden!';
    fprintf('Message: "%s"\n\n', test_message);
    
    % Embed
    fprintf('Embedding message...\n');
    [stego, stego_path] = encode_to_image(test_message, 'test_cover.png', 'test_stego.png');
    fprintf('✓ Embedded into: %s\n\n', stego_path);
    
    % Extract
    fprintf('Extracting message...\n');
    extracted = decode_from_image(stego_path);
    fprintf('✓ Extracted: "%s"\n\n', extracted);
    
    % Verify
    if strcmp(strtrim(extracted), strtrim(test_message))
        fprintf('✓✓✓ TEST PASSED ✓✓✓\n');
    else
        fprintf('✗✗✗ TEST FAILED ✗✗✗\n');
        fprintf('Expected: "%s"\n', test_message);
        fprintf('Got: "%s"\n', extracted);
    end
    
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
end

% Cleanup
if exist('test_cover.png', 'file'), delete('test_cover.png'); end
if exist('test_stego.png', 'file'), delete('test_stego.png'); end

%% ========================================================================
%  TEST_FULL_CYCLE.m - Test complete encrypt→embed→extract→decrypt
%% ========================================================================

% File: test_full_cycle.m
clear; clc;
fprintf('\n=== Testing Full Cycle ===\n\n');

pkg load image;
addpath('modules');
addpath('Encode');
addpath('Decode');

try
    % 1. Create test data
    fprintf('[1/5] Creating test data...\n');
    data.title = 'Bank Account';
    data.username = 'john_doe';
    data.password = 'SuperSecret123!';
    
    fid = fopen('cycle_test.json', 'w');
    fprintf(fid, '%s', jsonencode(data));
    fclose(fid);
    
    fid = fopen('cycle_pass.txt', 'w');
    fprintf(fid, 'MasterPassword');
    fclose(fid);
    
    % Create cover image
    cover = uint8(randi([0, 255], 512, 512, 3));
    imwrite(cover, 'cycle_cover.png');
    fprintf('      ✓ Test files created\n\n');
    
    % 2. Encrypt
    fprintf('[2/5] Encrypting JSON...\n');
    cipher = encode_json_to_ciphertext('cycle_test.json', 'cycle_pass.txt');
    fprintf('      ✓ Ciphertext: %d chars\n\n', length(cipher));
    
    % 3. Embed
    fprintf('[3/5] Embedding into image...\n');
    [~, stego_path] = encode_to_image(cipher, 'cycle_cover.png', 'cycle_stego.png');
    fprintf('      ✓ Stego image: %s\n\n', stego_path);
    
    % 4. Extract
    fprintf('[4/5] Extracting from image...\n');
    extracted = decode_from_image(stego_path);
    fprintf('      ✓ Extracted: %d chars\n\n', length(extracted));
    
    % 5. Decrypt
    fprintf('[5/5] Decrypting...\n');
    json_str = decode_from_ciphertext(extracted, 'cycle_pass.txt');
    result = jsondecode(json_str);
    fprintf('      ✓ Recovered password: %s\n\n', result.password);
    
    % Verify
    fprintf('=== VERIFICATION ===\n');
    fprintf('Original:  %s\n', data.password);
    fprintf('Recovered: %s\n', result.password);
    
    if strcmp(result.password, data.password) && ...
       strcmp(result.username, data.username) && ...
       strcmp(result.title, data.title)
        fprintf('\n✓✓✓ ALL DATA MATCHED - TEST PASSED ✓✓✓\n');
    else
        fprintf('\n✗✗✗ DATA MISMATCH - TEST FAILED ✗✗✗\n');
    end
    
catch ME
    fprintf('\n✗ ERROR: %s\n', ME.message);
    disp(ME.stack);
end

% Cleanup
if exist('cycle_test.json', 'file'), delete('cycle_test.json'); end
if exist('cycle_pass.txt', 'file'), delete('cycle_pass.txt'); end
if exist('cycle_cover.png', 'file'), delete('cycle_cover.png'); end
if exist('cycle_stego.png', 'file'), delete('cycle_stego.png'); end

%% ========================================================================
%  TEST_IMAGE_QUALITY.m - Test image quality after embedding
%% ========================================================================

% File: test_image_quality.m
clear; clc;
fprintf('\n=== Testing Image Quality ===\n\n');

pkg load image;
addpath('modules');
addpath('Encode');

try
    % Create test image
    fprintf('Creating test image...\n');
    original = uint8(randi([0, 255], 512, 512, 3));
    imwrite(original, 'quality_original.png');
    
    % Create test message
    message = repmat('X', 1, 1000);  % Long message
    
    % Embed
    fprintf('Embedding data...\n');
    [stego, stego_path] = encode_to_image(message, 'quality_original.png', ...
                                         'quality_stego.png');
    
    % Load images for comparison
    original_img = imread('quality_original.png');
    stego_img = imread(stego_path);
    
    % Convert to grayscale for metrics
    if size(original_img, 3) == 3
        orig_gray = rgb2gray(original_img);
    else
        orig_gray = original_img;
    end
    
    if size(stego_img, 3) == 3
        stego_gray = rgb2gray(stego_img);
    else
        stego_gray = stego_img;
    end
    
    % Ensure same dimensions
    [r1, c1] = size(orig_gray);
    [r2, c2] = size(stego_gray);
    min_r = min(r1, r2);
    min_c = min(c1, c2);
    orig_gray = orig_gray(1:min_r, 1:min_c);
    stego_gray = stego_gray(1:min_r, 1:min_c);
    
    % Calculate metrics
    fprintf('\n=== Quality Metrics ===\n');
    
    % MSE
    mse = mean((double(orig_gray(:)) - double(stego_gray(:))).^2);
    fprintf('MSE:  %.4f\n', mse);
    
    % PSNR
    if mse == 0
        psnr_val = Inf;
    else
        psnr_val = 10 * log10(255^2 / mse);
    end
    fprintf('PSNR: %.2f dB\n', psnr_val);
    
    % Max absolute difference
    max_diff = max(abs(double(orig_gray(:)) - double(stego_gray(:))));
    fprintf('Max Pixel Difference: %d\n', max_diff);
    
    % Percentage of changed pixels
    changed_pixels = sum(orig_gray(:) ~= stego_gray(:));
    total_pixels = numel(orig_gray);
    change_pct = 100 * changed_pixels / total_pixels;
    fprintf('Changed Pixels: %.2f%%\n', change_pct);
    
    % Interpretation
    fprintf('\n=== Assessment ===\n');
    if psnr_val > 40
        fprintf('✓ EXCELLENT - Image quality is virtually identical\n');
    elseif psnr_val > 30
        fprintf('✓ GOOD - Image quality is acceptable\n');
    elseif psnr_val > 20
        fprintf('⚠ FAIR - Some degradation visible\n');
    else
        fprintf('✗ POOR - Significant quality loss\n');
    end
    
    % Visual comparison
    fprintf('\nCreating side-by-side comparison...\n');
    figure;
    subplot(1,2,1); imshow(original_img); title('Original');
    subplot(1,2,2); imshow(stego_img); title('Stego');
    
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
end

% Cleanup (optional - keep images to view)
% if exist('quality_original.png', 'file'), delete('quality_original.png'); end
% if exist('quality_stego.png', 'file'), delete('quality_stego.png'); end

%% ========================================================================
%  TEST_WRONG_PASSWORD.m - Test security with wrong password
%% ========================================================================

% File: test_wrong_password.m
clear; clc;
fprintf('\n=== Testing Wrong Password Security ===\n\n');

pkg load image;
addpath('Encode');
addpath('Decode');

try
    % Create test data
    data.secret = 'TopSecret123!';
    fid = fopen('secret.json', 'w');
    fprintf(fid, '%s', jsonencode(data));
    fclose(fid);
    
    % Create passwords
    fid = fopen('correct.txt', 'w');
    fprintf(fid, 'CorrectPassword');
    fclose(fid);
    
    fid = fopen('wrong.txt', 'w');
    fprintf(fid, 'WrongPassword');
    fclose(fid);
    
    % Encrypt with correct password
    fprintf('[1] Encrypting with correct password...\n');
    cipher = encode_json_to_ciphertext('secret.json', 'correct.txt');
    fprintf('    ✓ Encrypted\n\n');
    
    % Try with wrong password
    fprintf('[2] Attempting decryption with WRONG password...\n');
    wrong_failed = false;
    try
        json_str = decode_from_ciphertext(cipher, 'wrong.txt');
        fprintf('    ✗ SECURITY FAIL - Wrong password should not work!\n');
    catch ME
        fprintf('    ✓ Wrong password correctly rejected\n');
        fprintf('    Error: %s\n', ME.message);
        wrong_failed = true;
    end
    
    fprintf('\n[3] Attempting decryption with CORRECT password...\n');
    json_str = decode_from_ciphertext(cipher, 'correct.txt');
    result = jsondecode(json_str);
    fprintf('    ✓ Correct password works\n');
    fprintf('    Recovered: %s\n', result.secret);
    
    % Final verdict
    fprintf('\n=== SECURITY TEST ===\n');
    if wrong_failed && strcmp(result.secret, 'TopSecret123!')
        fprintf('✓✓✓ PASSED - System properly secured ✓✓✓\n');
    else
        fprintf('✗✗✗ FAILED - Security issue detected ✗✗✗\n');
    end
    
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
end

% Cleanup
if exist('secret.json', 'file'), delete('secret.json'); end
if exist('correct.txt', 'file'), delete('correct.txt'); end
if exist('wrong.txt', 'file'), delete('wrong.txt'); end

%% ========================================================================
%  TEST_PERFORMANCE.m - Quick performance check
%% ========================================================================

% File: test_performance.m
clear; clc;
fprintf('\n=== Performance Test ===\n\n');

pkg load image;
addpath('modules');
addpath('Encode');
addpath('Decode');

try
    % Setup
    data.test = 'performance';
    data.password = 'TestPass123';
    fid = fopen('perf.json', 'w');
    fprintf(fid, '%s', jsonencode(data));
    fclose(fid);
    
    fid = fopen('perf_pass.txt', 'w');
    fprintf(fid, 'MasterPass');
    fclose(fid);
    
    img = uint8(randi([0, 255], 512, 512, 3));
    imwrite(img, 'perf_cover.png');
    
    iterations = 3;
    fprintf('Running %d iterations...\n\n', iterations);
    
    encrypt_times = zeros(1, iterations);
    embed_times = zeros(1, iterations);
    extract_times = zeros(1, iterations);
    decrypt_times = zeros(1, iterations);
    
    for i = 1:iterations
        fprintf('Iteration %d...\n', i);
        
        % Encryption
        tic;
        cipher = encode_json_to_ciphertext('perf.json', 'perf_pass.txt');
        encrypt_times(i) = toc;
        
        % Embedding
        tic;
        [~, stego_path] = encode_to_image(cipher, 'perf_cover.png', 'perf_stego.png');
        embed_times(i) = toc;
        
        % Extraction
        tic;
        extracted = decode_from_image(stego_path);
        extract_times(i) = toc;
        
        % Decryption
        tic;
        json_str = decode_from_ciphertext(extracted, 'perf_pass.txt');
        decrypt_times(i) = toc;
    end
    
    % Results
    fprintf('\n=== Performance Results (512x512 image) ===\n');
    fprintf('Encryption:  %.4f ± %.4f seconds\n', mean(encrypt_times), std(encrypt_times));
    fprintf('Embedding:   %.4f ± %.4f seconds\n', mean(embed_times), std(embed_times));
    fprintf('Extraction:  %.4f ± %.4f seconds\n', mean(extract_times), std(extract_times));
    fprintf('Decryption:  %.4f ± %.4f seconds\n', mean(decrypt_times), std(decrypt_times));
    fprintf('\nTotal Time:  %.4f seconds\n', mean(encrypt_times + embed_times + extract_times + decrypt_times));
    
catch ME
    fprintf('✗ ERROR: %s\n', ME.message);
end

% Cleanup
if exist('perf.json', 'file'), delete('perf.json'); end
if exist('perf_pass.txt', 'file'), delete('perf_pass.txt'); end
if exist('perf_cover.png', 'file'), delete('perf_cover.png'); end
if exist('perf_stego.png', 'file'), delete('perf_stego.png'); end

%% ========================================================================
%  RUN_ALL_SIMPLE_TESTS.m - Run all simple tests at once
%% ========================================================================

% File: run_all_simple_tests.m
clear; clc;

fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║         RUNNING ALL SIMPLE TESTS                       ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n');

tests_passed = 0;
tests_total = 6;

fprintf('\n[Test 1/6] Encryption/Decryption\n');
try
    test_encryption();
    tests_passed = tests_passed + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

fprintf('\n[Test 2/6] Steganography\n');
try
    test_steganography();
    tests_passed = tests_passed + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

fprintf('\n[Test 3/6] Full Cycle\n');
try
    test_full_cycle();
    tests_passed = tests_passed + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

fprintf('\n[Test 4/6] Image Quality\n');
try
    test_image_quality();
    tests_passed = tests_passed + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

fprintf('\n[Test 5/6] Wrong Password\n');
try
    test_wrong_password();
    tests_passed = tests_passed + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

fprintf('\n[Test 6/6] Performance\n');
try
    test_performance();
    tests_passed = tests_passed + 1;
catch ME
    fprintf('FAILED: %s\n', ME.message);
end

fprintf('\n\n');
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║                  FINAL RESULTS                         ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n');
fprintf('Tests Passed: %d/%d (%.1f%%)\n', tests_passed, tests_total, 100*tests_passed/tests_total);

if tests_passed == tests_total
    fprintf('\n🎉 ALL TESTS PASSED! 🎉\n');
else
    fprintf('\n⚠ Some tests failed - review output above\n');
end
