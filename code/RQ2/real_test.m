startT = 27;
endT = 41;
plotT1 = find(vel1.time > startT, 1);
plotT2 = find(vel1.time > endT, 1);
m=zeros(258+23,1);
m(24:end)=movmean(vel1.signals(1).values(plotT1+23:plotT2),60);

figure;
hold on
plot(vel1.time(plotT1:plotT2), movmean(vel1.signals(1).values(plotT1:plotT2),3),'LineWidth',1,Color='#b0e2ff')
plot(vel1.time(plotT1:plotT2), movmean(vel1.signals(2).values(plotT1:plotT2),3),'LineWidth',1)
% plot(vel1.time(plotT1:plotT2), vel1.signals(2).values(plotT1:plotT2),'LineWidth',1)
plot(vel1.time(plotT1:plotT2), movmean(vel1.signals(3).values(plotT1:plotT2),3),'LineWidth',1)
plot(vel1.time(plotT1:plotT2), m,'-.','LineWidth',2,Color='#0072bd')

legend('Real vx','vy','vz','Average vx') % 
xlabel('Time (s)')
ylabel('Speed (m/s)')
hold off

%%
figure;
hold on
plot(vel.time, movmean(vel.signals(1).values,3),'LineWidth',1)
plot(vel.time, movmean(vel.signals(2).values,3),'LineWidth',1)
plot(vel.time, movmean(vel.signals(3).values,3),'LineWidth',1)

legend('Real vx','vy','vz') % 
xlabel('Time (s)')
ylabel('Speed (m/s)')
hold off