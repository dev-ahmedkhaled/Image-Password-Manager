% ============================================
% STEGANOGRAPHY MODULE - FIXED VERSION
% Increased Q for robustness to rounding
% ============================================

% Magic number and constants
MAGIC_NUMBER = [80, 65, 83, 83];
HEADER_SIZE = 8;

% -------------------- MAIN FUNCTIONS --------------------

function modifiedDCT = embedData(dctCoeffs, encryptedData)
    fprintf('\n=== Starting Data Embedding ===\n');

    dataBits = bytesToBits(encryptedData);
    dataLength = length(encryptedData);

    fprintf('Data size: %d bytes (%d bits)\n', dataLength, length(dataBits));

    header = createHeader(dataLength);
    headerBits = bytesToBits(header);

    allBits = [headerBits, dataBits];
    totalBits = length(allBits);

    fprintf('Total bits to embed (header + data): %d\n', totalBits);

    midFreqPos = getMidFrequencyPositions();
    bitsPerBlock = size(midFreqPos, 1);

    totalBlocks = size(dctCoeffs.blocks, 3);
    capacity = totalBlocks * bitsPerBlock;

    fprintf('Image capacity: %d bits (%d bytes)\n', capacity, floor(capacity/8));

    if totalBits > capacity
        error('Data too large! Need %d bits but capacity is %d bits', totalBits, capacity);
    end

    modifiedBlocks = embedBitsIntoBlocks(dctCoeffs.blocks, allBits, midFreqPos);

    modifiedDCT = dctCoeffs;
    modifiedDCT.blocks = modifiedBlocks;

    fprintf('Embedding complete!\n');
end


function extractedData = extractData(dctCoeffs)
    MAGIC_NUMBER = [80, 65, 83, 83];
    HEADER_SIZE = 8;
    
    fprintf('\n=== Starting Data Extraction ===\n');

    midFreqPos = getMidFrequencyPositions();

    headerBits = extractBitsFromBlocks(dctCoeffs.blocks, 64, midFreqPos);
    header = bitsToBytes(headerBits);
    
    if size(header, 2) > size(header, 1)
        header = header';
    end

    extracted_magic = header(1:4);
    expected_magic = MAGIC_NUMBER(:);
    
    fprintf('Debug: Extracted magic: [%d %d %d %d]\n', extracted_magic);
    fprintf('Debug: Expected magic: [%d %d %d %d]\n', expected_magic);
    
    if ~isequal(extracted_magic, expected_magic)
        error('Magic number not found! This image may not contain hidden data.');
    end

    fprintf('Magic number verified!\n');

    dataLength = typecast(uint8(header(5:8)), 'uint32');
    fprintf('Data length: %d bytes\n', dataLength);

    totalBits = HEADER_SIZE * 8 + dataLength * 8;
    allBits = extractBitsFromBlocks(dctCoeffs.blocks, totalBits, midFreqPos);

    dataBits = allBits(HEADER_SIZE*8 + 1 : end);
    extractedData = bitsToBytes(dataBits);

    fprintf('Extraction complete! Extracted %d bytes\n', length(extractedData));
end


% -------------------- HELPER FUNCTIONS --------------------

function header = createHeader(dataLength)
    MAGIC_NUMBER = [80, 65, 83, 83];
    header = zeros(8, 1, 'uint8');
    header(1:4) = MAGIC_NUMBER';
    lengthBytes = typecast(uint32(dataLength), 'uint8');
    header(5:8) = lengthBytes';
end


function bits = bytesToBits(bytes)
    if size(bytes, 1) > size(bytes, 2)
        bytes = bytes';
    end
    
    numBytes = length(bytes);
    bits = false(1, numBytes * 8);
    
    for byteIdx = 1:numBytes
        byte_val = bytes(byteIdx);
        for bitPos = 7:-1:0
            bitIdx = (byteIdx - 1) * 8 + (8 - bitPos);
            bits(bitIdx) = bitget(byte_val, bitPos + 1);
        end
    end
end


function bytes = bitsToBytes(bits)
    numBits = length(bits);
    numBytes = floor(numBits / 8);
    bytes = zeros(1, numBytes, 'uint8');
    
    for byteIdx = 1:numBytes
        byte_val = uint8(0);
        for bitPos = 0:7
            bitIdx = (byteIdx - 1) * 8 + bitPos + 1;
            if bitIdx <= numBits && bits(bitIdx)
                byte_val = bitset(byte_val, 8 - bitPos);
            end
        end
        bytes(byteIdx) = byte_val;
    end
    
    if size(bytes, 2) > size(bytes, 1)
        bytes = bytes';
    end
end


function modifiedBlocks = embedBitsIntoBlocks(blocks, bits, midFreqPos)
    modifiedBlocks = blocks;
    numBlocks = size(blocks, 3);
    bitsPerBlock = size(midFreqPos, 1);
    totalBits = length(bits);
    
    % INCREASED Q from 10 to 20 for better robustness to rounding
    Q = 15;
    
    bitIdx = 1;
    for blockNum = 1:numBlocks
        if bitIdx > totalBits
            break;
        end

        block = blocks(:,:,blockNum);
        bitsToEmbed = min(bitsPerBlock, totalBits - bitIdx + 1);

        for i = 1:bitsToEmbed
            row = midFreqPos(i, 1);
            col = midFreqPos(i, 2);
            
            if row == 1 && col == 1
                bitIdx = bitIdx + 1;
                continue;
            end
            
            coeff = block(row, col);
            quantized = round(coeff / Q);
            
            if bits(bitIdx) == 1
                if mod(quantized, 2) == 0
                    quantized = quantized + 1;
                end
            else
                if mod(quantized, 2) == 1
                    quantized = quantized - 1;
                end
            end
            
            newCoeff = quantized * Q;
            
            % Increased limit from 50 to 100 for larger Q
            
           
            
            
            block(row, col) = newCoeff;
            bitIdx = bitIdx + 1;
        end

        modifiedBlocks(:,:,blockNum) = block;
    end
end


function bits = extractBitsFromBlocks(blocks, numBits, midFreqPos)
    bits = false(1, numBits);
    numBlocks = size(blocks, 3);
    bitsPerBlock = size(midFreqPos, 1);
    bitIdx = 1;
    
    % MUST match embedding Q value
    Q = 15;

    for blockNum = 1:numBlocks
        if bitIdx > numBits
            break;
        end

        block = blocks(:,:,blockNum);
        bitsToExtract = min(bitsPerBlock, numBits - bitIdx + 1);

        for i = 1:bitsToExtract
            row = midFreqPos(i, 1);
            col = midFreqPos(i, 2);
            
            if row == 1 && col == 1
                bits(bitIdx) = false;
                bitIdx = bitIdx + 1;
                continue;
            end
            
            coeff = block(row, col);
            quantized = round(coeff / Q);
            bits(bitIdx) = (mod(abs(quantized), 2) == 1);
            
            bitIdx = bitIdx + 1;
        end
    end
end