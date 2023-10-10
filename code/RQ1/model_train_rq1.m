clear
clc
close all

% Specify the directory containing data files
dataDir = 'rawdata/';

% List all dataset files in the specified directory
datasetNames = dir(dataDir);

for i = 7:7 %numel(datasetNames)-1
    dataDird = append(dataDir,datasetNames(i).name);
    datasetNamesit = dir(dataDird);
    % Split the string using '/' as the delimiter
    splitDird = strsplit(dataDird, '/');
    ab = splitDird{end}(end-3:end);
    
    % Initialize cell arrays to store raw data
    x_raw_cell = cell(1, 10);
    y_raw_cell = cell(1, 10);
    
    % Load the data
    for j = 3:numel(datasetNamesit)
        % Construct full path to the dataset file
        datasetPath = fullfile(dataDird, datasetNamesit(j).name);
        
        load(datasetPath);
        maxZl = round(max(dataset{1,2}(:,14))*1000);
        x_raw_cell{maxZl} = dataset{1, 2};
        y_raw_cell{maxZl} = dataset{2, 2};
    end
    fprintf(ab,'\n');
%% ANN training
    clear sizeD i maxZl dataset dataset_names datasets splitDir
    load('test_experts.mat')
    avgSteps_cell = cell(1,10);
    norm_cell = cell(1,10);
    nrmse_cell = cell(1,10);
    rSquared_cell = cell(1,10);
    long_cell = cell(2,10);
    for k = 1:10
        data2use = 100*(15500/size(x_raw_cell{k}, 1));
        [x_norm, y_norm, avgSteps_cell{k}, norm_cell{k}] = preprocessData(x_raw_cell{k}, y_raw_cell{k}, data2use);
        [net,tr] = trainMyNet(x_norm, y_norm);
        [nrmse_cell{k},rSquared_cell{k},fig]=singleTest(norm_cell{k}, net, test_data);
        [long_cell{1,k}, long_cell{2,k}]=longTest(norm_cell{k}, net, test_data);
        storeNet = append('Results\Net_rq1\trainingNet', ab,'_');
        singleTestid = append('rq1_',ab,'_',num2str(k));
        save(append(storeNet,num2str(k),'.mat'),'tr', 'net');
        savefig(fig,append('SavedFigure\prediction\',singleTestid,'.fig'))
%         print(fig, append('SavedFigure\prediction\',singleTestid,'.eps'), '-fillpage', '-r300'); % Adjust resolution as needed
        close all
        delete(findall(0));
    end
    
    save(append('Results\rq1\',singleTestid,'.mat'),"avgSteps_cell","rSquared_cell","nrmse_cell","long_cell")

end