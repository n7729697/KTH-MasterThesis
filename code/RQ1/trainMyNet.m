function [net,tr] = trainMyNet(x_norm, y_norm)

    % Split the data into training, validation
    val_ratio = 0.15;
    test_ratio = 0;
    numObs = size(x_norm,1);
    numFeatures = size(x_norm,2);
    numResponses = size(y_norm,2);
    % Define the neural network architecture
    % normal NN
    val_size = round(val_ratio * numObs);
    test_size = round(test_ratio * numObs);
    
    valInd = randperm(numObs, val_size);
    trainInd = setdiff(1:numObs, valInd);
    testInd = randperm(length(trainInd), test_size);
    trainInd = trainInd(setdiff(1:length(trainInd), testInd));
    
    layers = [
        featureInputLayer(numFeatures)
        fullyConnectedLayer(64)
        reluLayer
        fullyConnectedLayer(128)
        reluLayer
        fullyConnectedLayer(64)
        reluLayer
        fullyConnectedLayer(numResponses)
        regressionLayer];
%     layers = [
%         featureInputLayer(numFeatures)
%         fullyConnectedLayer(64)
%         reluLayer
%         fullyConnectedLayer(128)
%         reluLayer
%         fullyConnectedLayer(128)
%         reluLayer
%         fullyConnectedLayer(64)
%         reluLayer
%         fullyConnectedLayer(numResponses)
%         reluLayer
%         regressionLayer];
    options = trainingOptions('adam', ...
    'MaxEpochs',30, ...
    'MiniBatchSize',512, ...
    'GradientThreshold', inf, ...
    'ValidationData',{x_norm(valInd,:),y_norm(valInd,:)},...
    'ValidationFrequency',100, ...
    'Shuffle','every-epoch', ...
    'Plots','training-progress',...
    'Verbose',false);
    
    [net, tr] = trainNetwork(x_norm(trainInd,:),y_norm(trainInd,:),layers,options);
end