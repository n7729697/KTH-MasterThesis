Ts=0.05;
pred_steps_list = 1:1:10/Ts - 14;

subplot(1,2,1)
% R_dnn_mean = movmean(R_dnn,20);
for i = 1:size(R_values,1)
    plot(pred_steps_list*Ts, R_values(i,:))
    hold on
end

xlabel('Prediction period (second)','FontSize', 14)
ylabel('R','FontSize', 14)

legend('28 sequence', '100 sequence', '130 sequence', '160 sequence', '180 sequence', '220 sequence', '280 sequence', '300 sequence', '3000 sequence', 'Location', 'best');
title('R vs. Prediction Period');
hold off

subplot(1,2,2)
for i = 1:size(nrmse_list,1)
    plot(pred_steps_list*Ts, nrmse_list(i,:))
    hold on
end

xlabel('Prediction period (second)','FontSize', 14)
ylabel('NRMSE','FontSize', 14)

legend('28 sequence', '100 sequence', '130 sequence', '160 sequence', '180 sequence', '220 sequence', '280 sequence', '300 sequence', '3000 sequence', 'Location', 'best');
title('NRMSE vs. Prediction Period');
hold off