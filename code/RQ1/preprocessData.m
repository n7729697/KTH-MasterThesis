function [x_norm, y_norm, avgSteps, norm]=preprocessData(x_raw, y_raw, data2use)
% preprocessData - Preprocesses raw input and output data for neural network training.
%
% Syntax:
%   [x_norm, y_norm, avgSteps, norm] = preprocessData(x_raw, y_raw, data2use)
%
% Input:
%   x_raw   - Raw input data matrix, where each row represents a data point, and columns
%             correspond to features.
%   y_raw   - Raw output data matrix, where each row represents a data point, and columns
%             correspond to response variables.
%   data2use - Percentage of data to use for training. If set to 100, all data is used;
%              otherwise, a random subset is selected for training.
%
% Output:
%   x_norm  - Normalized input data matrix suitable for neural network training.
%   y_norm  - Normalized output data matrix suitable for neural network training.
%   avgSteps - Average sequence length of the data.
%   norm    - A cell array containing normalization parameters for both input and output
%             data. It includes the range and minimum values for normalization.
%
% Author: NIU Xuezhi
%   The 'preprocessData' function was developed by NIU Xuezhi and is part of a research
%   project focused on preprocessing data for neural network training. NIU Xuezhi can
%   be contacted at xuezhin@kth.se for inquiries and further collaboration related to
%   this function.
%
% Copyright 2023 NIU Xuezhi
%   2023 NIU Xuezhi All rights reserved. This MATLAB function and its accompanying
%   documentation are protected by copyright law and may not be reproduced or distributed
%   without the written permission of NIU Xuezhi.
%
% Description:
%   The 'preprocessData' function takes raw input and output data and performs several
%   preprocessing steps to prepare the data for neural network training. These steps
%   include:
%
%   1. Identifying and filtering out sequences based on a specified threshold.
%   2. Removing outliers from the output data using a moving mean approach.
%   3. Normalizing both input and output data to ensure consistent input to the neural
%      network.
%   4. Optionally, selecting a subset of the data for training based on the 'data2use'
%      percentage.
%
%   The function also calculates the average sequence length of the data and provides
%   normalization parameters for later denormalization of predictions.
%
% Example:
%   % Load raw input and output data and specify the percentage of data to use for training.
%   load('raw_data.mat', 'x_raw', 'y_raw');
%   data2use = 70; % Use 70% of the data for training
%
%   % Preprocess the data for neural network training.
%   [x_norm, y_norm, avgSteps, norm] = preprocessData(x_raw, y_raw, data2use);
%
%   % Display the average sequence length and normalization parameters.
%   disp(avgSteps);
%   disp(norm);
%
%   % Train a neural network using the preprocessed data.
%   % ...
%
% See also:
%   rmoutliers, mean

%     filtered out observations by iterations and percentage
    numFeatures = size(x_raw, 2);
    numResponses = size(y_raw, 2);
    numObs = size(x_raw, 1);
    % Initialize variables
    num_sequences = 0;
    sequence_lengths = [];
    threshold = 0; 
   
% Iterate over the dataset to determine the number of sequences and their lengths
    current_sequence_length = 0;
    for i = 1:numObs
        if x_raw(i,1:10) == x_raw(1,1:10)
            if current_sequence_length > 1
                num_sequences = num_sequences + 1;
                sequence_lengths(num_sequences) = current_sequence_length;
                current_sequence_length = 1;
            else
                current_sequence_length = current_sequence_length + 1;
            end
        else
            current_sequence_length = current_sequence_length + 1;
        end
    end
    % If the last sequence continues until the end of the dataset, add it to the sequence lengths
    if current_sequence_length > 0
        num_sequences = num_sequences + 1;
        sequence_lengths(num_sequences) = current_sequence_length;
    end
    avgSteps = mean(sequence_lengths);

    current_row = 1;
    j=1;
    x_raw_reliable=zeros(numObs,numFeatures);
    y_raw_reliable=zeros(numObs,numResponses);
    for i = 1:num_sequences
        sequence_length = sequence_lengths(i);
        if sequence_length >= threshold
            x_raw_reliable(j:j+sequence_length-1,:) = x_raw(current_row:current_row+sequence_length-1, :);
            y_raw_reliable(j:j+sequence_length-1,:) = y_raw(current_row:current_row+sequence_length-1, :);
            j = j + sequence_length;
        end
        current_row = current_row + sequence_length;
    end
    x_raw = x_raw_reliable(1:j-1,:);
    y_raw = y_raw_reliable(1:j-1,:);

    if any(sequence_lengths>200)
        idx=find(sequence_lengths>200);
        disp(idx);
        error('some iterations are wrong');
    end


    % remove outliers
    TFs = zeros(size(y_raw,1),1);
%     nOutlierList = [];
    for feature = 1:1:size(y_raw,2)
        [~,TF] = rmoutliers(y_raw(:,feature),'movmean',size(y_raw,2));% detects and removes outliers from the data 
        TFs = TFs + TF;
%         nOutlierList = [nOutlierList; nnz(TFs)];
    end
%     plot(nOutlierList)
    x = x_raw;
    y = y_raw;
    x(any(TFs,2),:) = [];
    y(any(TFs,2),:) = [];
    
    x_norm_range = max(x,[],1) - min(x,[],1);
    x_norm_min = min(x,[],1);
    y_norm_range = max(y,[],1) - min(y,[],1);
    y_norm_min = min(y,[],1);
    x_norm = (x - x_norm_min)./x_norm_range;
    y_norm = (y - y_norm_min)./y_norm_range;
    
    numObs = size(x_norm,1);
    % Initialize variables
    num_sequences = 0;
    sequence_lengths = [];
    
    % Iterate over the dataset to determine the number of sequences and their lengths
    current_sequence_length = 0;
    for i = 1:numObs
        if x_raw(i,1:10) == x_raw(1,1:10)
            if current_sequence_length > 1
                num_sequences = num_sequences + 1;
                sequence_lengths(num_sequences) = current_sequence_length;
                current_sequence_length = 1;
            else
                current_sequence_length = current_sequence_length + 1;
            end
        else
            current_sequence_length = current_sequence_length + 1;
        end
    end
    % If the last sequence continues until the end of the dataset, add it to the sequence lengths
    if current_sequence_length > 0
        num_sequences = num_sequences + 1;
        sequence_lengths(num_sequences) = current_sequence_length;
    end
    
    if data2use ==  100
        fprintf('Number of sequence %d and sum %d\n', num_sequences, sum(sequence_lengths))
    else
        % Split the dataset into sequences based on the feature index and sequence lengths
        x_seq = cell(num_sequences, 1);
        y_seq = cell(num_sequences, 1);
        current_row = 1;
        for i = 1:num_sequences
            sequence_length = sequence_lengths(i);
            x_new_sequence = x_norm(current_row:current_row+sequence_length-1, :)';
            x_seq{i} = x_new_sequence;
            y_new_sequence = y_norm(current_row:current_row+sequence_length-1, :)';
            y_seq{i} = y_new_sequence;
            current_row = current_row + sequence_length;
        end
        
        % use part of the data to train the network
        sort_size = round(data2use * size(sequence_lengths,2)/100);
        sortInd = randperm(size(sequence_lengths,2), sort_size);
        % sortInd = sort(sortInd);
        x_sort = [];
        y_sort = [];
        for sort_i = sortInd
            x_sort = [x_sort; x_seq{sort_i}'];
            y_sort = [y_sort; y_seq{sort_i}'];
        end
        x_norm = x_sort;
        y_norm = y_sort;
        fprintf('Number of sequence chosen %d and sum %d\n',size(sortInd,2), sum(sequence_lengths(sortInd)))
    end

    norm = {x_norm_range;x_norm_min; y_norm_range; y_norm_min};

end