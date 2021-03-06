    

clear;  clc


%(0) Load data:
dataset = spm1d.data.uv1d.t2.PlantarArchAngle();
% dataset = spm1d.data.uv1d.t2.SimulatedTwoLocalMax();
[yA,yB] = deal(dataset.YA, dataset.YB);


%(1) Conduct normality test:
alpha     = 0.05;
spm       = spm1d.stats.normality.ttest2(yA, yB);
spmi      = spm.inference(0.05);
disp(spmi)


%(2) Plot:
close all
figure('position', [0 0  1200 300])
subplot(131);  plot(yA', 'k');  hold on;  plot(yB', 'r');  title('Data')
subplot(132);  plot(spm.residuals', 'k');  title('Residuals')
subplot(133);  spmi.plot();  title('Normality test')

















