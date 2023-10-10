clear
clc
close all

dataDir = append(pwd,'/Results/rq2/MFRL/');
w_time = 0.2;
w_rotation = 1;
w_y = 1;
% List all dataset files in the specified directory
fileList = dir(fullfile(dataDir, '*.mat'));
results = zeros(9,3);
rotz=[];
for i = 1:numel(fileList)
        % Construct full path to the dataset file
        datasetPath = fullfile(append(dataDir,fileList(i).name));
         disp(['Loaded file: ', datasetPath]);
        load(datasetPath);
        rotz(i)= max(abs(simout.wz.Data));
        t=find(simout.vx.Data>0.01);
        results(i,1) = w_time*(simout.rot.Time(t(end))-simout.rot.Time(t(1))) - w_rotation*max(abs(simout.wz.Data)) ...
        - w_y*max(abs(simout.vy.Data(end)));
        results(i,2) = (simout.x.Data(end)-simout.x.Data(1))/(simout.x.Time(end)-simout.x.Time(1));
        results(i,3) = mean(simout.COT.Data);
end
%%
data = readtable('ancova_data.csv');
Method = zeros(18,1);
Method(1:9)=1;
Methods=data.Method;
velocitys = data.velocity;
stabilitys = data.stability;
speeds = data.speed;
COTs = data.COT;
cov = data.convergence;


subplot('Position', [0.12, 0.55, 0.35, 0.4])
boxplot(stabilitys,Methods)
xlabel('Method','FontSize',12)
ylabel('Stability','FontSize',12)
annotation('textbox', [0.025,0.73,0.05,0.05], 'String', '(a)', 'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'none')

subplot('Position', [0.6, 0.55, 0.35, 0.4])
boxplot(speeds,Methods)
xlabel('Method','FontSize',12)
ylabel('Resultant walking speed (m/s)','FontSize',12)
annotation('textbox', [0.5, 0.73, 0.05, 0.05], 'String', '(b)', 'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'none')

subplot('Position', [0.12, 0.08, 0.35, 0.4])
boxplot(COTs,Methods)
xlabel('Method','FontSize',12)
ylabel('Cost-of-Transport (J/kg/m)','FontSize',12)
annotation('textbox', [0.025, 0.25, 0.05, 0.05], 'String', '(c)', 'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'none')

subplot('Position', [0.6, 0.08, 0.35, 0.4])
boxplot(cov(1:end-1), Methods(1:end-1))
xlabel('Method','FontSize',12)
ylabel('Training Time(hrs)','FontSize',12)
annotation('textbox', [0.51, 0.25, 0.05, 0.05], 'String', '(d)', 'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'none')

set(gcf,'Position', [431,233,949,727])
stability = data.stability(1:end-1);
velocity = data.velocity(1:end-1);
speed = data.speed(1:end-1);
COT = data.COT(1:end-1);
cov = data.convergence(1:end-1);
% [h,atab,ctab,stats] = aoctool(Method, stability, velocity);