clear
clc
close all

% Specify the offset percentage
offsetPercentage = 0.1;

% Calculate the button width and height with the offset
buttonWidth = 0.2;
buttonHeight = 0.1;
offsetX = buttonWidth * offsetPercentage;
offsetY = buttonHeight * offsetPercentage;

% Calculate the figure size based on the button dimensions and offset
figureWidth = buttonWidth + 2 * offsetX;
figureHeight = buttonHeight + 2 * offsetY;

% Create the figure with the calculated size
fig = figure('Units', 'normalized', 'Position', [0.5 - figureWidth/2, 0.5 - figureHeight/2, figureWidth, figureHeight],'MenuBar','none');

% Calculate the button position with respect to the figure size
buttonX = offsetX / figureWidth;
buttonY = offsetY / figureHeight;
%% Generate dataset
mdl = 'robotModeltrot';
% robot animation on/off
set_param(mdl,'SimMechanicsOpenEditorOnUpdate','off', 'FastRestart','on') 
isCheckDone = 1;

Tf = 10;
Ts = 0.05;
ang = 6; %3

alpha_r_gain = 0;
alpha_b_gain = pi/5+pi/40; %pi/10 - pi/5  -ang*pi/10/10
z_low = 5e-3; %6
z_high = 5e-3;
% z_l_gain_arr = [5e-3,7e-3,8e-3,9e-3]; % 1e-3 - 8e-3
ButtonHandle = uicontrol('Style', 'PushButton', ...
                         'String', 'Stop loop', ...
                         'Units', 'normalized', ...
                         'Position', [buttonX, buttonY, buttonWidth/figureWidth, buttonHeight/figureHeight],...
                         'Callback', 'delete(gcbf)');
clear buttonY buttonX buttonHeight buttonWidth figureWidth figureHeight ...
    offsetPercentage offsetY offsetX 
% movegui(fig,'center');
% breakLoopFigure = figure('color','w','Name','Plotter');
% breakLoopFigure.Position = [0 612 560 420];
% breakLoopFigure.Visible = "on";
% breakLoopFigure.Units = "normalized";
% ButtonHandle = uicontrol(breakLoopFigure,...
%     'Style','pushbutton',...
%     'String', 'Stop loop', ...
%     'Callback', 'delete(gcbf)');
% ButtonHandle.Units = "normalized";
% ButtonHandle.Position = [.1 .1 .8 .8];
% drawnow
%% Simulation Loop
% b_low = pi/10;
% b_high = pi/5;
% z_low = 1e-3;
% z_high = 8e-3;
% n=1;
% alpha_b_gain = b_low:0.01:b_high;
% for alpha_b_gain = alpha_b_gain(22:28)
% 
%     X = [];
%     Y = [];
%     
%     for z_l_gain = z_low:1e-4:z_high
%         action_seeds = randi(4,4,1);
%         fprintf('Round: %d, Dataset size now: %d, ',n, size(X,1))
%         simout = sim(mdl);
%         if size(simout.observation.signals.values,1)>0
%             for i = 1:1:(size(simout.action.signals.values, 1)-1)
%                 X = [X; [simout.observation.signals.values(i,:) simout.action.signals.values(i,:)]];
%                 Y = [Y; simout.observation.signals.values(i+1,:)];
%             end
%             fprintf('the simulation finishes at step %d, Dataset size now: %d \n',...
%                 size(simout.action.signals.values, 1)-1, size(X,1));
%         else
%             fprintf('the simulation fails at steps %d \n', size(simout.action.signals.values, 1)-1)
%         end
%         n=n+1;
%     end
% end
% dataset = {'X' X;'Y' Y};
% currentTimestr = datestr(now,'yyyy_mmmm_dd_HH_MM');
% save(append('datasets\dataset_', currentTimestr,'.mat'),'dataset');
n=0;
for z_l_gain=z_low:1e-3:z_high
    X = [];
    Y = [];
    next = 0;
    n_round = 0;
    while size(X,1) < 5000
        rng(n_round);
        action_seeds = randi(4,4,1);
        fprintf('Round: %d, Dataset size now: %d, ', n, size(X,1))
        try
            if ~ishandle(ButtonHandle)
                disp('Loop stopped by user');
                return;
            end
            if next <= 10
                simout = sim(mdl);
            else 
                n_round=n_round+1;
            end
        catch
            warning('Problem simulation.');
            next=next+1;
            continue
        end
        if next > 10
            next = 0;
        end
        for i = 1:1:(size(simout.action.signals.values, 1)-1)
            X = [X; [simout.observation.signals.values(i,:) simout.action.signals.values(i,:)]];
            Y = [Y; simout.observation.signals.values(i+1,:)];
        end
        fprintf('the simulation finishes at step %d, Dataset size now: %d \n',...
            size(simout.action.signals.values, 1)-1, size(X,1));
        n_round = n_round + 1;
        n = n + 1;
    end
    
    dataset = {'X' X;'Y' Y};
    currentTimestr = datestr(now,'yyyy_mmmm_dd_HH_MM');
    save(append('rawdata\datapi50\dataset_', currentTimestr,'.mat'),'dataset');
end
close all