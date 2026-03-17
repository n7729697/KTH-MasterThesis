function [nrmse, R10, fig]=singleTest(norm, net, test_data)
% singleTest - Perform single-step predictions using a trained neural network.
%
% Syntax:
%   [nrmse, R10, fig] = singleTest(norm, net, test_data)
%
% Input:
%   norm - A cell array containing normalization parameters for input and output data.
%          It includes mean and standard deviation values for both input and output data.
%   net  - The trained neural network model for making predictions.
%   test_data - A cell array containing test data for prediction. Each cell in the array
%              corresponds to a different test case and contains input and output data.
%
% Output:
%   nrmse - Normalized Root Mean Square Error (NRMSE) for each test case. It measures
%           the prediction accuracy normalized by the range of the ground truth data.
%   R10   - Correlation coefficients (R) for each test case and each output dimension.
%           R is a measure of the linear relationship between predicted and actual values.
%   fig   - A MATLAB figure object displaying subplots of ground truth and predicted
%           data for each output dimension and each test case.
%
% Description:
%   The 'singleTest' function takes a set of test data and a trained neural network model
%   to perform single-step predictions. It calculates NRMSE and correlation coefficients
%   for evaluating the prediction accuracy and generates a figure displaying subplots
%   for visual inspection of the predictions.
%
%   The input data is normalized using the provided normalization parameters to ensure
%   consistent input to the neural network. The predictions are denormalized to the
%   original scale for comparison with the ground truth data.
%
%   The function also calculates correlation coefficients (R) for each output dimension,
%   providing insights into the quality of predictions for individual features.
%
%   The generated figure contains subplots for each output dimension, comparing the
%   ground truth and predicted data over time for each test case.
%
% Example:
%   % Load normalization parameters, a trained neural network, and test data.
%   load('normalization_parameters.mat', 'norm');
%   load('trained_neural_network.mat', 'net');
%   load('test_data.mat', 'test_data');
%
%   % Perform single-step predictions and evaluate the results.
%   [nrmse, R10, fig] = singleTest(norm, net, test_data);
%
%   % Display NRMSE values and correlation coefficients for analysis.
%   disp(nrmse);
%   disp(R10);
%
%   % Show the figure with comparison plots of ground truth and predictions.
%   figure(fig);
%
% See also:
%   predict, corrcoef, sqrt, mean, tiledlayout, nexttile, legend
% Author: NIU Xuezhi @ KTH Royal Institute of Technology, Mechatronics and
%         Embedded System Unit
%   The 'singleTest' function was developed by NIU Xuezhi and is part of a research
%   project aimed at improving the evaluation and interpretability of neural network
%   models in time-series prediction tasks. NIU Xuezhi can be contacted at
%   xuezhin@kth.se for inquiries and further collaboration related to this function.
%
% Copyright 2023 NIU Xuezhi
%   2023 NIU Xuezhi All rights reserved. This MATLAB function and its accompanying
%   documentation are protected by copyright law and may not be reproduced or distributed
%   without the written permission of NIU Xuezhi.

    % Define time step and simulation time
    Ts = 0.05;
    Tf = 10;

    % Calculate the number of test samples
    test_size=size(test_data,2)-1;

    % Create a time vector
    t = Ts:Ts:Tf;

    % Initialize cell arrays to store predicted outputs
    y_pred = cell(test_size,1);
    
    % Initialize arrays for NRMSE and correlation coefficients
    nrmse = zeros(1,test_size);
    R = zeros(1,test_size);
    R10 = zeros(test_size,10);
    
    % Define labels and titles for plots
    ylabelList = {'$\theta_x$', '$\theta_y$', '$\theta_z$', '$v_x$', '$v_y$', '$v_z$', '$f_{nFR}$', '$f_{nFL}$', '$f_{nRL}$', '$f_{nRR}$'};
    titleList = {'$\alpha_b=\pi/5, z_l=10e^{-3}$', '$\alpha_b=\pi/5, z_l=8e^{-3}$', '$\alpha_b=\pi/5, z_l=6e^{-3}$','$\alpha_b=\pi/5, z_l=6e^{-3}$'};

    % Set a margin for y-axis limits
    yMarginPercentage = 0.1;
    
    % Create a figure for plotting
    fig = figure('Position', [1, 1, 1920, 1080-80]);
    tcl = tiledlayout(10, test_size, 'TileSpacing', 'tight');
    
    % Loop through test samples
    for test_idx = 1:test_size
        % Normalize input and ground truth data
        x_test = (test_data{1, test_idx + 1} - norm{2}) ./ norm{1};
        y_test = (test_data{2, test_idx + 1} - norm{4}) ./ norm{3};

        % Predict the state
        y_pred{test_idx} = predict(net, x_test);
        
        % Calculate the correlation coefficient
        c = corrcoef(y_test, y_pred{test_idx});
        R(test_idx) =c(1,2);% this not R2 but R (correlation coefficient)
        
        % Denormalize the predicted output
        y_pred{test_idx} = y_pred{test_idx} .* norm{3} + norm{4};
        rangeTest = max(test_data{2, test_idx + 1}) - min(test_data{2, test_idx + 1}); % Calculate the range of the test data
        nrmse(test_idx) = sqrt(mean((y_pred{test_idx} - test_data{2, test_idx + 1}).^2)) / rangeTest; % Calculate NRMSE
        % Calculate R2 for each output dimension
%         SS_res = sum((y_pred{test_idx} - test_data{2, test_idx + 1}).^2);
%         SS_tot = sum((test_data{2, test_idx + 1} - mean(test_data{2, test_idx + 1})).^2);
%         rSquared{test_idx} = 1 - SS_res / SS_tot;
        
        % Calculate correlation coefficients for individual output dimensions
        Rtemp = zeros(1,10);
        for feature = 1:1:10
            cs = corrcoef(test_data{2, test_idx + 1}(:,feature), y_pred{test_idx}(:,feature));
            Rtemp(feature) = cs(1,2);
        end
        R10(test_idx,:) = Rtemp;
        
%       % Calculate adjusted R2
%         num_samples = 200;
%         num_predictors = 200;
%         rSquared{j} = 1 - ((1 - R2{j}) * (num_samples - 1)) / (num_samples - num_predictors - 1);
    end
    
    % Create subplots for each output dimension
    for i = 1:1:10
        for j = 1:test_size
            nexttile
            plot(t, test_data{2, j + 1}(:, i))
            hold on
            plot(t, y_pred{j}(:, i))
            

             % Set y-axis label for the first row
            if j == 1
                ylabel(ylabelList{i}, 'Interpreter', 'latex')
            end
            
            % Set title for the first column
            if i == 1
                title(titleList{j}, 'Interpreter', 'latex')
            end
            
            % Set x-axis label for the last row
            if i == 10
                xlabel('Time (s)')
            end
            
            % Calculate y-axis limits with 10% margin
            yMin = min(min(test_data{2, j + 1}(:, i)), min(y_pred{j}(:, i)));
            yMax = max(max(test_data{2, j + 1}(:, i)), max(y_pred{j}(:, i)));
            yMargin = (yMax - yMin) * yMarginPercentage;
            ylim([yMin - yMargin, yMax + yMargin]); % Set y-axis limits
            hold off
        end
        
    end
    
    % Set overall title, x-label, y-label, and legend
%     title(tcl, 'Single step predictions vs real high velocity tests')
    xlabel(tcl, 'Simulation time','FontSize', 16)
    ylabel(tcl, 'Observations(angle(radian), velocity(m/s),force(N))','FontSize', 16)
    legendHandle = legend('Ground Truth', 'Predicted');
    legendHandle.Layout.Tile = 'East';
end