
figure;
x=subplot(1,2,1);
plot(trainingStats.EpisodeIndex, trainingStats.EpisodeReward,Color='#b0e2ff')
hold on
plot(trainingStats.EpisodeIndex, trainingStats.AverageReward,Color='#0072bd',LineWidth=2)
plot(EpisodeIndex1,EpisodeReward1,Color='#ECBA9B')
plot(EpisodeIndex1, AverageReward1, Color='#D85419',LineWidth=2)
xlim([0 round(1.05*size(EpisodeIndex1,1))]);
xlabel('Training Epiode')
ylabel('Cumulative Reward')
title('Cumulative reward vs the training episodes','FontSize',13)
p=get(x, 'Position');
text(-55.5,52.15, '(a)', 'FontSize', 12, 'FontWeight', 'bold');

x1=subplot(2,2,2);
Nonzero_entropy_idx = EntropyList ~= 0;
Nonzero_entropy = EntropyList(Nonzero_entropy_idx);
plot(Nonzero_entropy)
hold on
plot(Nonzero_entropy1)
ylabel('Entropy')
% ylabel('Training Steps')
title('The entropy and temperature coefficients during the training process','FontSize',13)
xlim([0 round(1.05*size(Nonzero_entropy1,1))]);
ylim([-5 0.5]);
set(gca,'xTickLabel',[]);
yticks(-4:1:0);

x2=subplot(2,2,4);
Nonzero_t_idx = EntropyWeightList ~= 0;
Nonzero_t = EntropyWeightList(1:25977);
plot(Nonzero_t)
hold on
plot(Nonzero_t1)
ylabel('Temperature')
xlabel('Training Steps','FontSize',11)
xlim([0 round(1.05*size(Nonzero_entropy1,1))]);
ylim([-0.2 1.2]);
yticks(0:0.5:1);
text(-7579,1.25, '(b)', 'FontSize', 12, 'FontWeight', 'bold');

p1 = get(x1, 'Position');
p2 = get(x2, 'Position');
p1(4) = p(4)/2;
p2(4) = p(4)/2;
p1(2) = p2(2)+p2(4);
p(3) = p(3)*1.1;
p(1) = p(1)-p(3)*0.1;
set(x, 'pos', p)
set(x1, 'pos', p1);
set(x2, 'pos', p2);
set(gcf, 'Position', [351,318,1221,503]);
%%
figure('Name','Robot body information','NumberTitle','off')
% set(gcf,'Visible','on')
subplot(4,1,1)
plot(simout.COT.Time, simout.COT.Data,'LineWidth',2)
xlabel('Time (s)')
ylabel('COT')
text(-0.586021505376344,2703.291406976949, '(a)', 'FontSize', 12, 'FontWeight', 'bold');
hold off
stability = max(abs(simout.rot.Data(:,3)))
mean_v = (simout.x.Data(end)-simout.x.Data(1))/(simout.x.Time(end)-simout.x.Time(1))
COT = mean(simout.COT.Data)
subplot(4,1,2)
hold on
plot(simout.x.Time, simout.x.Data,'LineWidth',2)
plot(simout.y.Time, simout.y.Data,'LineWidth',2)
plot(simout.z.Time, simout.z.Data,'LineWidth',2)
legend('x','y','z')
xlabel('Time (s)')
ylabel('position (m)')
text(-0.5, 1, '(b)', 'FontSize', 12, 'FontWeight', 'bold');
hold off

subplot(4,1,3)
hold on
plot(simout.vx.Time, simout.vx.Data,'LineWidth',2)
plot(simout.vy.Time, simout.vy.Data,'LineWidth',2)
plot(simout.vz.Time, simout.vz.Data,'LineWidth',2)
legend('vx','vy','vz')
xlabel('Time (s)')
ylabel('Speed (m/s)')
hold off

subplot(4,1,4)

% rotData = reshape(out.Observations.rot.Data,size(out.Observations.rot.Data,[1,3]));
hold on
plot(simout.rot.Time, simout.rot.Data(:,1),'LineWidth',2)
plot(simout.rot.Time, simout.rot.Data(:,2),'LineWidth',2)
plot(simout.rot.Time, simout.rot.Data(:,3),'LineWidth',2)
legend('rotX','rotY','rotZ')
xlabel('Time (s)')
ylabel('Rotate (rad)')
hold off

superTitle = sgtitle('Robot body information'); %
set(superTitle,'FontSize', 16);
% set(gcf, 'Position', [680,558,720,420]);


