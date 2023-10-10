function heatmap(metric_values)
    % Define the values for a_b and z_l (replace with your actual values)
    a_b = [pi/4, pi/4-pi/40, pi/5:-pi/100:pi/10];
    z_l = 1:1:10;
    
    [Z_L, A_B] = meshgrid(z_l, a_b);
    titleList = {'Average Steps before Failure','Validation Dataset RMSE','Validation Dataset Loss','Single Step Prediction R',...
        'Average R of Long-term Prediction','Full Horizon Prediction R','Single Step NRMSE','Average NRMSE of Long-term Prediction','Full Horizon Prediction NRMSE'};
    captions ={'(a)','(b)','(c)','(d)','(e)','(f)','(g)','(h)','(i)'};
    % Create a 3x3 subplot grid
    gcp=tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    for i = 1:min(9, numel(metric_values))
        a(i)=nexttile;
        contourf(Z_L, A_B, metric_values{i}, 'Fill', 'on');
        title(titleList{i},'Interpreter', 'latex');
        colorbar;
        c=colormap;

        % Add caption below the x-axis
        xLimits = xlim;
        yLimits = ylim;
        xPosition = xLimits(1) + (xLimits(2) - xLimits(1)) * 0.5;
        
        if i >= 7
            xlabel('z_l (mm)')
            colormap(a(i),flipud(c));
            yPosition = yLimits(1) - (yLimits(2) - yLimits(1)) * 0.05; % Adjust vertical position
        else
            yPosition = yLimits(1) - (yLimits(2) - yLimits(1)) * 0.1; % Adjust vertical position
        end
        if i >1 && i<4
            colormap(a(i),flipud(c));
        end
        if mod(i,3) ==1 
            ylabel('a_b (rad)');
        end
        text(xPosition, yPosition, captions{i}, 'HorizontalAlignment', 'center');

        hold off
    end
    
    
    % Adjust the layout
    superTitle = sgtitle('Color Heatmaps of Various Metrics to Assess Surrogate Model Performance'); %
%     set(gcp,'Position',[370,255,1198,723])
    set(superTitle,'FontSize', 16); % Change the font size
end