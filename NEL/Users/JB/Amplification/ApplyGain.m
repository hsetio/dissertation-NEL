function output=ApplyGain(input,Fs,MaxSPL,atten,audiogram,freqs_Hz,strategy)
% output=ApplyGain(input,Fs,MaxSPL,atten,audiogram,freqs_Hz,strategy)
% strategy = 1 or 'linear' or
%         or 2 or 'nonlinear_quiet' or
%         or 3 or 'nonlinear_noise'

plotYes=0;
if nargin<1  % if no input, just test gain settings
    Fs=22e3;
    %input = 0.1*sin(2*pi*997*(0:1/Fs:1)); %1sec @ 997Hz
    input = randn(5*Fs,1); input=input/max(abs(input)); %white noise
%     calib = [120 120]; % SPLs
%     calib_freqs = [100 10e3]; % Freqs_Hz
    MaxSPL = 105;
    atten = 50;
    audiogram = [16   18   20    9    9]; % based on avg animal data (500OBN exposure)
    freqs_Hz = [500,1000,2000,4000,6000];
    strategy = 2; %'nonlinear_quiet';
    plotYes=1;
end

freqs_Hz_std=[250,500,1000,2000,3000,4000,6000];

dBLoss = abs(audiogram);
% interpolate/extrapolate audiogram at standard frequencies
dBLoss = interp1(freqs_Hz,dBLoss,freqs_Hz_std,'nearest','extrap');

switch strategy
    case {1,'linear'}
        % NAL equations
        % frequency shaping (250,500,1000,2000,3000,4000,6000Hz)
        k_NAL = [-17 -8 1 -1 -2 -2 -2]; % dB
        H_3FA = sum(dBLoss(2:4)) / 3; % sum up loss at 500Hz,1kHz,2kHz
        X = 0.15*H_3FA;
        R = 0.31; % NAL-R formula  (not quite half-gain rule)
        NAL_IG = X + R.*dBLoss + k_NAL; % insertion gain
        %NAL_IG = max(0,NAL_IG); % no negative gain

        output = FIRgain(input,NAL_IG,freqs_Hz_std,Fs);

    case {2,'nonlinear_quiet',3,'nonlinear_noise'}
        InputRMS = norm(input)/sqrt(length(input));

        % Estimate max SPL (only consider 100-4000Hz)
%         MaxSPL = mean(calib(calib_freqs>=100 & calib_freqs<=4000));

        % InputSPL = (maxSPL w/ atten) + (rms re fullscale tone)
        InputSPL = (MaxSPL-atten) + 20*log10(InputRMS/(1/sqrt(2)));

        % perhaps just use a simple crossover and set gain in each band?
        % Use 2 channels, with crossover frequency at 2.1kHz
        if all(dBLoss==[16,16,18,20,9,9,9])
            NormalThreshSPL = [22 22 9 12 16 16 10];
            ImpairedThreshSPL = NormalThreshSPL+dBLoss;

            % Get DSL Compression parameters
            % [in_quiet_band1,in_quiet_band2;
            %  in_noise_band1,in_noise_band2]
            [Gain, Thresh, Ratio, TargetREAR_60dBSPL] = readDSLfile('ChinchillaDSLtargets.csv');
            switch strategy
                case {2,'nonlinear_quiet'}, indx=1;
                case {3,'nonlinear_noise'}, indx=2;
            end

            % Initialize gains based on compression parameters
            PrescribedGain = Gain(indx,:) + ...
                max(0,(InputSPL-Thresh(indx,:))).*Ratio(indx,:) - ...
                max(0,(InputSPL-Thresh(indx,:)));
            %PrescribedGain = max(0,PrescribedGain); % minimum 0dB gain

            % Adjust gain to meet prescriptive targets
            % TargetREAR_60dBSPL is specified at 500Hz & 4kHz
            % calibSPL = interp1(calib_freqs,ThirdOctSmoothing(calib,calib_freqs),[500 4000]); % extract 1/3-octave averages at 500Hz & 4kHz
            LTASS_RMS = -12.49; % avg rms(dBFS) of LTASS
            LTASS_dBFS_sb = [-12.55, -33.21]; % avg subband levels (dBFS), fc=2.1kHz
            LTASS_dBFS_to = [-24.08, -42.37]; % 1/3-octave levels at 500Hz & 4kHz
            LTASS_dBSPL_sb = 60 + (LTASS_dBFS_sb-LTASS_RMS); % get subband SPL (total RMS=60dB SPL)
            LTASS_dBSPL_to = 60 + (LTASS_dBFS_to-LTASS_RMS);
            PrescribedGain2 = Gain(indx,:) + ...
                max(0,(LTASS_dBSPL_sb-Thresh(indx,:))).*Ratio(indx,:) - ...
                max(0,(LTASS_dBSPL_sb-Thresh(indx,:))); % get prescribed gain for LTASS
            %PrescribedGain2 = max(0,PrescribedGain2); % minimum 0dB gain
            PredictedREAR = LTASS_dBSPL_to + PrescribedGain2;
            adjustment = TargetREAR_60dBSPL(indx,:) - PredictedREAR;

            PrescribedGain = PrescribedGain + adjustment; % to reach REAR
            %PrescribedGain = max(0,PrescribedGain); % minimum 0dB gain

            % apply gain to 2 bands (fc=2.1kHz)
            output = TwoBandGain(input,2.1e3,Fs,PrescribedGain);

        else
            error('Nonlinear amplification not defined for this audiogram');
        end

    otherwise
        % No amplification
        output = input;
end

if plotYes
    % plot in/out spectra
    freqs = (1:length(input))/length(input)*Fs;
    inputFFT = abs(fft(input));
    inputFFT = ThirdOctSmoothing(inputFFT(1:end/2),freqs(1:end/2));
    outputFFT = abs(fft(output));
    outputFFT = ThirdOctSmoothing(outputFFT(1:end/2),freqs(1:end/2));
    figure,
    semilogx(freqs(1:end/2),20*log10(inputFFT),'b'); hold on
    loglog(freqs(1:end/2),20*log10(outputFFT),'r'); hold off;
    xlim([100 10e3]); xlabel('Frequency(Hz)'); ylabel('dB');
    legend('in','out');
end

end % function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [TKgain_out,TK_out,CR_out,Target_out] = readDSLfile(filename)  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [TKgain_out,TK_out,CR_out,Target_out] = readDSLfile(filename)
a = csvread(filename,0,1);
length = size(a,2);

% Program 1 (in quiet)
freqs(1,:) = a(1,1:length-1);
% Line 2: thresholds entered into the DSL m(I/O) v5.0a GUI
Thresh(1,:) = a(2,1:length-1);
% (note that line 9 was empty, so didn't get read)
% Line 10: thresholds in dB SPL (Line 2 will be the same if real ear SPL thresholds are entered)
ThreshSPL(1,:) = a(9,1:length-1);
% Line 15: Output at each compression threshold
CTout(1,:) = a(14,1:length-1);
% Line 17:  Channelized input at each compression threshold
TK(1,:) = a(16,1:length-1);
% Line 12: BOLT (Broadband Output Limiting Targets)
BOLT(1,:) = a(11,1:length-1);
% Line 19: Compression ratios
CR(1,:) = a(18,1:length-1);
% [The difference between lines 17 and 15 is used to initialize gain]
TKgain(1,:) = CTout(1,:) - TK(1,:);
% Lines 25: Real-ear aided response for low speech (52 dB SPL)
TargetLo(1,:) = a(23,1:length-1);
% Lines 25: Real-ear aided response for average speech (60 dB SPL)
TargetAvg(1,:) = a(24,1:length-1);
% Lines 25: Real-ear aided response for high speech (74 dB SPL)
TargetHi(1,:) = a(25,1:length-1);

% Program 2 (in noise)
freqs(2,:) = a(1,1:length-1);
% Line 2: thresholds entered into the DSL m(I/O) v5.0a GUI
Thresh(2,:) = a(2,1:length-1);
% (note that line 9 was empty, so didn't get read)
% Line 10: thresholds in dB SPL (Line 2 will be the same if real ear SPL thresholds are entered)
ThreshSPL(2,:) = a(9+23,1:length-1);
% Line 15: Output at each compression threshold
CTout(2,:) = a(14+23,1:length-1);
% Line 17:  Channelized input at each compression threshold
TK(2,:) = a(16+23,1:length-1);
% Line 12: BOLT (Broadband Output Limiting Targets)
BOLT(2,:) = a(11+23,1:length-1);
% Line 19: Compression ratios
CR(2,:) = a(18+23,1:length-1);
% [The difference between lines 17 and 15 is used to initialize gain]
TKgain(2,:) = CTout(2,:) - TK(2,:);
% Lines 25: Real-ear aided response for low speech (52 dB SPL)
TargetLo(2,:) = a(23+23,1:length-1);
% Lines 25: Real-ear aided response for average speech (60 dB SPL)
TargetAvg(2,:) = a(24+23,1:length-1);
% Lines 25: Real-ear aided response for high speech (74 dB SPL)
TargetHi(2,:) = a(25+23,1:length-1);


indices = [5,14]; %[500,4000]Hz
% Compression Parameters
% [in_quiet_band1,in_quiet_band2;
%  in_noise_band1,in_noise_band2;]
TKgain_out = [TKgain(1,indices(1)),TKgain(1,indices(end));...
    TKgain(2,indices(1)),TKgain(2,indices(end))];
TK_out = [TK(1,indices(1)),TK(1,indices(end));...
    TK(2,indices(1)),TK(2,indices(end))];
CR_out = [CR(1,indices(1)),CR(1,indices(end));...
    CR(2,indices(1)),CR(2,indices(end))];
% REAR Targets
Target_out = [TargetAvg(1,indices(1)),TargetAvg(1,indices(end));...
    TargetAvg(2,indices(1)),TargetAvg(2,indices(end))];

end %function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% spectrum_smoothed = ThirdOctSmoothing(spectrum_orig,freqs) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spectrum_smoothed = ThirdOctSmoothing(spectrum_orig,freqs)
% Applies 1/3-Octave smoothing to spectral coefficients

N=1/3; % smoothing factor (octaves)

isColMatrix = find(size(spectrum_orig)==min(size(spectrum_orig)))-1;
if ~isColMatrix
    spectrum_orig=spectrum_orig';
    freqs=freqs';
end

spectrum_smoothed = NaN*ones(size(spectrum_orig));
for m=1:size(spectrum_orig,2)
    for i=1:size(spectrum_orig,1)
        minIndex = max(1,find(freqs<=freqs(i)*2^-N,1,'last'));
        if isempty(minIndex), minIndex=1; end
        maxIndex = min(length(spectrum_orig(:,m)),find(freqs>=freqs(i)*2^N,1,'first'));
        if isempty(maxIndex), maxIndex=length(spectrum_orig(:,m)); end

        spectrum_smoothed(i,m) = mean(spectrum_orig(minIndex:maxIndex,m));
    end
end

if ~isColMatrix
    spectrum_smoothed=spectrum_smoothed';
end
end %function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% out = TwoBandGain(in,fc,fs,gains)      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = TwoBandGain(in,fc,fs,gains)

% design 8th-order Linkwitz-Riley crossover
[b,a] = butter(4,fc/(fs/2),'low');  % low-pass
Hd_lp = dfilt.df2(b,a);
Hd_lp = dfilt.cascade(Hd_lp,Hd_lp);

[b,a] = butter(4,fc/(fs/2),'high');  % high-pass
Hd_hp = dfilt.df2(b,a);
Hd_hp = dfilt.cascade(Hd_hp,Hd_hp);

out = 10^(gains(1)/20)*filter(Hd_lp,in) + ...
    10^(gains(2)/20)*filter(Hd_hp,in);
end %function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% out = FIRgain(in,gain_db,f_hz,Fs)      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = FIRgain(in,gain_db,f_hz,Fs)
f = f_hz/(Fs/2);
a = 10.^(gain_db/20);

%create freq pairs
f=[f(1:end-1) f(end-1)+eps f(end) f(end)+eps 1];
a=[a(1:end-1) a(end-1) a(end) a(end) 0];

% design 32-order filter
b = firpm(32,f,a);

out=filter(b,1,in);
end %function


