%% NAG Plots

% levels = 100:-10:30;%10:10:100;
% gains = 20:-5:-20;%-40:5:40;

% NAL env (input level -vs- optimal gain)
% phones | levels | gains | numCFs | sponts
for i=1:size(Env,2) % for all levels
    for j=1:size(Env,3) % for all gain adjustments
        % average mean squared error across CF's
        sqerror(1,i,j) = mean(squeeze(abs(Rate(1,i,j,:,:)))-squeeze(abs(Rate_Normal(1,i,:,1))))^2;
        sqerror(2,i,j) = mean(min(1,squeeze(abs(Env(1,i,j,:,:))))-min(1,squeeze(abs(Env_Normal(1,i,:,1)))))^2;
        sqerror(3,i,j) = mean(squeeze(abs(Tfs(1,i,j,:,:)))-squeeze(abs(Tfs_Normal(1,i,:,1))))^2;
        
        RateCurve(1,i,j) = mean(squeeze(abs(Rate_Normal(1,i,:,1))));
        RateCurve(2,i,j) = mean(squeeze(abs(Rate(1,i,j,:,:))));
        EnvCurve(1,i,j) = min(1,mean(squeeze(abs(Env_Normal(1,i,:,1)))));
        EnvCurve(2,i,j) = min(1,mean(squeeze(abs(Env(1,i,j,:,:)))));
        TfsCurve(1,i,j) = mean(squeeze(abs(Tfs_Normal(1,i,:,1))));
        TfsCurve(2,i,j) = mean(squeeze(abs(Tfs(1,i,j,:,:))));
    end
    for k=1:3
        OptimalGain(i,k) = max(find(sqerror(k,i,:)==min(sqerror(k,i,:))));
    end
end
plot(levels,gains(OptimalGain)); legend('Rate','Env','Tfs');
xlabel('Input Level (dbSPL)'); ylabel('Optimal Gain Adjustment (dB from NAL)');
axis([min(levels) max(levels) min(gains) max(gains)]);

figure, plot(levels,squeeze(RateCurve(2,:,:))');
legend(num2str(gains'));
hold on; plot(levels,squeeze(RateCurve(1,:,:))','k.-'); hold off;
title(sprintf('Rate (Normal -vs- Aided)\nColored lines show variation from NAL'));

figure, plot(levels,squeeze(EnvCurve(2,:,:))');
legend(num2str(gains'));
hold on; plot(levels,squeeze(EnvCurve(1,:,:))','k.-'); hold off;
title(sprintf('ENV (Normal -vs- Aided)\nColored lines show variation from NAL'));

figure, plot(levels,squeeze(TfsCurve(2,:,:))');
legend(num2str(gains'));
hold on; plot(levels,squeeze(TfsCurve(1,:,:))','k.-'); hold off;
title(sprintf('TFS (Normal -vs- Aided)\nColored lines show variation from NAL'));