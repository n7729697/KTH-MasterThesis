clear
clc
close all
load('dataset.mat')
load('test_experts.mat')

% Define a range of dataset size factors to explore (logarithmic scale)
squence = [100 130 160 180 220 300 3000];
dataset_size_factors = squence/28603;
R_values=zeros(7,186);
nrmse_list = zeros(7,186);
i=0;
for data2use = dataset_size_factors*100
    i=i+1;
    [x_norm, y_norm, avgSteps, norm] = preprocessData(x_raw, y_raw, data2use);
    [net,tr] = trainMyNet(x_norm, y_norm);
    [nrmse, R10, fig]=singleTest(norm, net, test_data);
    [R_values(i,:), nrmse_list(i,:)]=longTest(norm, net, test_data);
    save(append('Results\datasize\trainingNet_', num2str(data2use),'.mat'), 'tr', 'net', 'avgSteps', 'R10', 'nrmse');
    savefig(fig, append('Results\datasize\singleTest_',num2str(data2use),'.fig')); % Adjust resolution as needed
    close all
    delete(findall(0));
end

save('Results\datasize\data2.mat', 'R_values', 'nrmse_list');
[x_norm, y_norm, avgSteps, norm] = preprocessData(x_raw, y_raw, data2use);