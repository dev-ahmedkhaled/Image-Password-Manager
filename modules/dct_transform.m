% ============================================
% DCT TRANSFORM MODULE
% ============================================

pkg load image;

% -------------------- MAIN FUNCTIONS --------------------
function T = manual_dctmtx(n)
    % Manual implementation of the DCT-II matrix
    [cols, rows] = meshgrid(0:n-1, 0:n-1);
    T = sqrt(2/n) * cos(pi * (2*cols + 1) .* rows / (2*n));
    T(1,:) = T(1,:) / sqrt(2);
end

function dctCoeffs = imageToDCT(imagePath)
    % Load and convert image to DCT coefficients
    img = imread(imagePath);

    % Convert to grayscale if needed
    if size(img, 3) == 3
        img = rgb2gray(img);
        fprintf('Converted RGB to grayscale\n');
    end

    img = double(img);
    [rows, cols] = size(img);

    % Ensure dimensions are multiples of 8
    newRows = floor(rows/8) * 8;
    newCols = floor(cols/8) * 8;
    img = img(1:newRows, 1:newCols);

    fprintf('Image size: %dx%d\n', newRows, newCols);

    % Apply DCT to 8x8 blocks
    dctBlocks = blockDCT(img);

    % Store in structure
    dctCoeffs.blocks = dctBlocks;
    dctCoeffs.rows = newRows;
    dctCoeffs.cols = newCols;
    dctCoeffs.originalImage = img;

    fprintf('DCT transformation complete. Blocks: %dx%d\n', newRows/8, newCols/8);
end


function dctBlocks = blockDCT(img)
    [rows, cols] = size(img);
    numBlocksRow = rows/8;
    numBlocksCol = cols/8;
    dctBlocks = zeros(8, 8, numBlocksRow*numBlocksCol);
    
    % Use the manual function we created below
    T = manual_dctmtx(8); 

    blockIndex = 1;
    for i = 1:numBlocksRow
        for j = 1:numBlocksCol
            rowStart = (i-1)*8+1;
            colStart = (j-1)*8+1;
            block = img(rowStart:rowStart+7, colStart:colStart+7);
            
            % Standard 2D DCT formula
            dctBlocks(:,:,blockIndex) = T * double(block) * T';
            blockIndex = blockIndex + 1;
        end
    end
end

function img = blockIDCT(dctBlocks, rows, cols)
    numBlocksRow = rows / 8;
    numBlocksCol = cols / 8;
    img = zeros(rows, cols);
    
    T = manual_dctmtx(8);

    blockIndex = 1;
    for i = 1:numBlocksRow
        for j = 1:numBlocksCol
            % Standard 2D Inverse DCT formula
            block = T' * double(dctBlocks(:,:,blockIndex)) * T;
            
            rowStart = (i - 1) * 8 + 1;
            colStart = (j - 1) * 8 + 1;
            img(rowStart:rowStart + 7, colStart:colStart + 7) = block;
            blockIndex = blockIndex + 1;
        end
    end
end


function img = dctToImage(dctCoeffs)
    % Reconstruct image from DCT coefficients
    dctBlocks = dctCoeffs.blocks;
    rows = dctCoeffs.rows;
    cols = dctCoeffs.cols;

    img = blockIDCT(dctBlocks, rows, cols);
    img = min(max(img, 0), 255);

    fprintf('Image reconstruction complete\n');
end


function [midFreqPos] = getMidFrequencyPositions()
    % Returns mid-frequency positions for embedding
    midFreqPos = [
        1, 2;
        2, 1;
        3, 1;
        2, 2;
        1, 3;
        1, 4;
        2, 3;
        3, 2;
        4, 1;
        5, 1;
        4, 2;
        3, 3;
        2, 4;
        1, 5;
    ];
end


function metrics = calculateQualityMetrics(original, modified)
    % Calculate PSNR and MSE
    original = double(original);
    modified = double(modified);

    mse = mean((original(:) - modified(:)).^2);

    if mse == 0
        psnr_val = Inf;
    else
        maxPixel = 255;
        psnr_val = 10 * log10(maxPixel^2 / mse);
    end

    metrics.MSE = mse;
    metrics.PSNR = psnr_val;

    fprintf('\n=== Quality Metrics ===\n');
    fprintf('MSE:  %.4f\n', mse);
    fprintf('PSNR: %.2f dB\n', psnr_val);

    if psnr_val > 40
        fprintf('Quality: Excellent (imperceptible)\n');
    elseif psnr_val > 30
        fprintf('Quality: Good (minor differences)\n');
    else
        fprintf('Quality: Poor (visible differences)\n');
    end
end


