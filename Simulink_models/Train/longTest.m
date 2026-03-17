function [R_values, nrmse_list]=longTest(norm, net, test_data)
% longTest - Perform long-term predictions and evaluate prediction performance.
%
% Syntax:
%   [R_values, nrmse_list] = longTest(norm, net, test_data)
%
% Input:
%   norm - A cell array containing normalization parameters for input and output data.
%          It includes mean and standard deviation values for both input and output data.
%   net  - The trained neural network model for making predictions.
%   test_data - A cell array containing test data for prediction. Each cell in the array
%              corresponds to different observations and responses.
%
% Output:
%   R_values - List of correlation coefficients (R) for different prediction periods.
%              R measures the linear relationship between predicted and actual values.
%   nrmse_list - List of Normalized Root Mean Square Error (NRMSE) values for different
%                prediction periods. NRMSE quantifies prediction accuracy normalized by
%                the range of the ground truth data.
%
% Description:
%   The 'longTest' function performs long-term predictions using a trained neural network
%   model and evaluates the prediction performance over different prediction periods.
%
%   It iteratively predicts future values for a given test case and measures the
%   prediction accuracy using both correlation coefficients (R) and NRMSE. The function
%   calculates these metrics for various prediction periods by adjusting the number of
%   prediction steps.
%
%   The resulting R_values and nrmse_list provide insights into how the prediction
%   performance changes over time, helping to assess the model's suitability for
%   long-term forecasting.
%
% Example:
%   % Load normalization parameters, a trained neural network, and test data.
%   load('normalization_parameters.mat', 'norm');
%   load('trained_neural_network.mat', 'net');
%   load('test_data.mat', 'test_data');
%
%   % Perform long-term predictions and evaluate the results.
%   [R_values, nrmse_list] = longTest(norm, net, test_data);
%
%   % Display correlation coefficients and NRMSE values for analysis.
%   disp(R_values);
%   disp(nrmse_list);
%
%   % Plot the correlation coefficients and NRMSE over different prediction periods.
%   % ...
%
% See also:
%   predict, corrcoef, sqrt, mean, plot, xlabel, ylabel

    Ts = 0.05; % Second
    Tf = 10;
%     test_size=size(test_data,2)-1;
%     R_values = zeros(1,3);
%     r2Values = []; % Initialize R2 values matrix
    predictionWindowSize = 1;
    pred_steps_list = 1:predictionWindowSize:Tf/Ts - 14;
    nrmse_list = [];
    r2_list = [];
    
    rangeTest = max(test_data{2, 3}) - min(test_data{2, 3});

    for pred_steps = pred_steps_list
        x_test = test_data{1,3}; % continuous observations and responses only pi/5_8 used
        y_test = test_data{2,3};
        x_test_norm = (x_test - norm{2}) ./ norm{1};
        y_test_norm = (y_test - norm{4}) ./ norm{3};
        
        nrmse = 0;
        for i = 1:1:pred_steps
            y_pred_norm = predict(net, x_test_norm);
            
            y_pred = y_pred_norm .* norm{3} + norm{4};
            nrmse = nrmse + sqrt(mean((y_pred - y_test(i:end,:)).^2)) / rangeTest;

            x_test_norm = x_test_norm(2:end, :);
            x_test_norm(:,1:size(y_pred_norm,2)) = y_pred_norm(1:end-1,:);
        end
        
        nrmse_list = [nrmse_list; nrmse/pred_steps];

        y_test_norm = y_test_norm(pred_steps:end,:);
        
        c = corrcoef(y_test_norm, y_pred_norm);
        r2 = c(1,2);
        r2_list = [r2_list, r2];
    end
    R_values = r2_list;

    figure
    plot(pred_steps_list*Ts, R_values, 'LineWidth',2)
    xlabel('Prediction period (second)','FontSize', 14)
    ylabel('R','FontSize', 14)

    figure
    plot(pred_steps_list*Ts, nrmse_list, 'LineWidth',2)
    xlabel('Prediction period (second)','FontSize', 14)
    ylabel('NRMSE','FontSize', 14)
end