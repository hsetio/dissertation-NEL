function PopPlot_SpatTemp(ExpDate,UnitNames)
% File: PopPlot_SpatTemp.m 
% From: UnitPlot_SpatTemp.m
% Modified Date: 10Feb2005 (M Heinz)
% Plots a population of different units to the same stimulus (based on ANmodel)
%
% Modified Date: 07Jan2005 (M Heinz)
% Modified From:  UnitPlot_SpatTemp.m and UnitPlot_SpatTemp.m to use either Interleaved Data or regular in 1 file
% 
% Date: 01Nov2004 (M. Heinz) (Modified from UnitPlot_EHrBF_simFF.m)
% For: NOHR Experiments
%
% ExpDate: e.g., '080204' (converted later)
% UnitName: '1.29' (converted later)
%
% Plots Simulated spatio-temporal response pattern (ala Shamma 1985) from EH_reBF_simFF and/or T_reBF_simFF data 
% for a given experiment and unit.  Loads 'UNITSdata/unit.T.U.mat' file.
% UnitAnal_EHrBF_simFF.m and/or UnitAnal_TonerBF_simFF.m performs the relevant analysis.
%
% 11/2/04 TO DO
% 1) only plots Fn/Tn{1,1} for now, need to add rest later
% *2) Separate Calcs and Plots, to allow smart plotting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% close all

global NOHR_dir NOHR_ExpList
global SavedPICS SavedPICnums SavedPICSuse
global FeaturesText FormsAtHarmonicsText InvertPolarityText
SavedPICSuse=1; SavedPICS=[]; SavedPICnums=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Verify parameters and experiment, unit are valid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Verify in passed parameters if needed
if ~exist('ExpDate','var')
   %%% HARD CODE FOR NOW
   ExpDate='021005'
   while ~ischar(ExpDate)
      ExpDate=input('Enter Experiment Date (e.g., ''080204''): ');
   end
end
if ~exist('UnitNames','var')
   
   %%% HARD CODE FOR NOW
   UnitNames={'2.01','2.02','2.03','2.04','2.05'};
   %    while ~ischar(UnitNames)
   %       UnitNames=input('Enter Unit Name (e.g., ''1.29''): ');
   %    end
end

%%%% Find the full Experiment Name 
ExpDateText=strcat('20',ExpDate(end-1:end),'_',ExpDate(1:2),'_',ExpDate(3:4));
for i=1:length(NOHR_ExpList)
   if ~isempty(strfind(NOHR_ExpList{i},ExpDateText))
      ExpName=NOHR_ExpList{i};
      break;
   end
end
if ~exist('ExpName','var')
   disp(sprintf('***ERROR***:  Experiment: %s not found\n   Experiment List:',ExpDate))
   disp(strvcat(NOHR_ExpList))
   beep
   break
end

%%%% Parse out the Track and Unit Number 
clear TrackNums UnitNums
for i=1:length(UnitNames)
   TrackNums(i)=str2num(UnitNames{i}(1:strfind(UnitNames{i},'.')-1));
   UnitNums(i)=str2num(UnitNames{i}(strfind(UnitNames{i},'.')+1:end));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data_dir=fullfile(NOHR_dir,'ExpData');
anal_dir=fullfile(NOHR_dir,'Data Analysis');
stim_dir=fullfile(NOHR_dir,'Stimuli');

eval(['cd ''' fullfile(data_dir,ExpName) ''''])
disp(sprintf('Plotting Spatio-Temporal Patterns for:  Experiment: ''%s''; Unit: %d.%02d - Unit: %d.%02d',ExpName,TrackNums(1),UnitNums(1),TrackNums(end),UnitNums(end)))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Verify UNITSdata/unit analyses are all done ahead of time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for UNITind=1:length(UnitNames) 
   
   %%%% Load unit structure for this unit
   UnitFileName=sprintf('unit.%d.%02d.mat',TrackNums(UNITind),UnitNums(UNITind));
   eval(['ddd=dir(''' fullfile('UNITSdata',UnitFileName) ''');'])
   % If UNITSdata file does not exist, load DataList to see if interleaved or not, and then run necessary analyses
   if isempty(ddd)
      FileName=strcat('DataList_',ExpDateText,'.mat');
      disp(['   *** Loading file: "' FileName '" because UNITSdata/unit does not exist yet'])
      eval(['load ' FileName])
      
      if isfield(DataList.Units{TrackNums(UNITind),UnitNums(UNITind)},'Tone_reBF')   
         UnitAnal_TrBF(ExpDate,UnitNames{UNITind},0);
         UnitAnal_TrBF_simFF(ExpDate,UnitNames{UNITind},0);
      end
      if isfield(DataList.Units{TrackNums(UNITind),UnitNums(UNITind)},'EH_reBF')   
         UnitAnal_EHrBF(ExpDate,UnitNames{UNITind},0);
         UnitAnal_EHrBF_simFF(ExpDate,UnitNames{UNITind},0);
      end
%       % Verify TC
%       UnitVerify_TC(ExpDate,UnitName);   
      % Estimate SR
      UnitCalc_SR(ExpDate,UnitNames{UNITind});   
      
   end
   eval(['load ''' fullfile('UNITSdata',UnitFileName) ''''])
   
   % Make sure there is either Tone_reBF or EH_reBF data
   if (~isfield(unit,'EH_reBF'))&(~isfield(unit,'Tone_reBF'))
      disp(sprintf('*** No Tone_reBF or EH_reBF data for this unit!!!'))
      beep
      return;
   end
   
   % If EH_reBF_simFF analysis is not completed, run here
   if isfield(unit,'EH_reBF')&~isfield(unit,'EH_reBF_simFF')
      UnitAnal_EHrBF_simFF(ExpDate,UnitNames{UNITind},0);   
      eval(['load ''' fullfile('UNITSdata',UnitFileName) ''''])
   end
   
   % If Tone_reBF_simFF analysis is not completed, run here
   if isfield(unit,'Tone_reBF')&~isfield(unit,'Tone_reBF_simFF')
      UnitAnal_TrBF_simFF(ExpDate,UnitNames{UNITind},0);
      eval(['load ''' fullfile('UNITSdata',UnitFileName) ''''])
   end
   
%    % Make sure TC is verified (i.e., Q10 known)
%    if isempty(unit.Info.Q10)
%       UnitVerify_TC(ExpDate,UnitNames{UNITind});
%       eval(['load ''' fullfile('UNITSdata',UnitFileName) ''''])
%    end
   
   % Make sure SR is estimated
   if isempty(unit.Info.SR_sps)
      UnitCalc_SR(ExpDate,UnitNames{UNITind});   
      eval(['load ''' fullfile('UNITSdata',UnitFileName) ''''])
   end

   units{UNITind}=unit;
end  % Nunits
clear unit

%%%%%%%%%%%%%%% REBUILD unit based on FF  - Quicker than re-writing all code
for UNITind=1:length(UnitNames)
   if round(units{UNITind}.EH_reBF.F1{1,1}.freqs_kHz*1000)==round(units{UNITind}.Info.BF_kHz*1000)
      BFunitIND=UNITind;
      break;
   end
end
unit=units{BFunitIND};
unit=rmfield(unit,'EH_reBF_simFF');

EHfeats=fieldnames(unit.EH_reBF);
EHfeats=EHfeats(~strcmp(EHfeats,'interleaved'));  %% 010705: M Heinz; takes out newly added "interleaved" field
for FeatIND=1:length(EHfeats)
   FeatINDs(FeatIND)=find(strcmp(FeaturesText,EHfeats{FeatIND}));
end

for FeatIND=FeatINDs
   eval(['unit.EH_reFF.' FeaturesText{FeatIND} '=cell(2,2);'])
   for HarmonicsIND=1:2
      for PolarityIND=1:2
         eval(['yTEMP=unit.EH_reBF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
         if ~isempty(yTEMP)
            zTEMP.BFs_kHz=NaN*ones(size(units));
            zTEMP.levels_dBSPL=unit.EH_reBF.F1{1,1}.levels_dBSPL;
            zTEMP.picNums=cell(size(units));
            zTEMP.excludeLines=cell(size(units));
            zTEMP.rate=NaN*ones(size(units));
            zTEMP.FeatureFreqs_Hz=cell(size(units));
            zTEMP.FeatureLevels_dB=unit.EH_reBF.F1{1,1}.FeatureLevels_dB;
            zTEMP.synch=cell(size(units));
            zTEMP.phase=cell(size(units));
            zTEMP.RaySig=cell(size(units));
            
            for UNITind=1:length(units)
               eval(['xTEMP=units{UNITind}.EH_reBF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
                        
               zTEMP.BFs_kHz(UNITind)=units{UNITind}.Info.BF_kHz;
               %                zTEMP.levels_dBSPL=unit.EH_reBF.F1{1,1}.levels_dBSPL;
               zTEMP.picNums{UNITind}=xTEMP.picNums{1};
               zTEMP.excludeLines{UNITind}=xTEMP.excludeLines{1};
               zTEMP.rate(UNITind)=xTEMP.rate;
               zTEMP.FeatureFreqs_Hz{UNITind}=xTEMP.FeatureFreqs_Hz{1};
               %                zTEMP.FeatureLevels_dB=unit.EH_reBF.F1{1,1}.FeatureLevels_dB;
               zTEMP.synch{UNITind}=xTEMP.synch{1};
               zTEMP.phase{UNITind}=xTEMP.phase{1};
               zTEMP.RaySig{UNITind}=xTEMP.RaySig{1};
               
            end
            
            %%%%%%%%%% THIS REALLY SHOULD BE EH_reFF, and then we DONT DO ANY SHIFTING!!!!!!
            eval(['unit.EH_reFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND}=zTEMP;'])
            
         end
      end
   end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Get general parameters for this unit, e.g., all BFs, levels, ...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Find number of features to plot (tone, F1, T1, ...)
%%%% Find all levels and BFs to plot
NUMcols=4;
NUMrows=0;
levels_dBSPL=[]; BFsTEMP_kHz=[];
if isfield(unit,'Tone_reFF')
   NUMrows=NUMrows+1;
   levels_dBSPL=union(levels_dBSPL,unit.Tone_reFF.levels_dBSPL);
   BFsTEMP_kHz=union(BFsTEMP_kHz,unit.Tone_reFF.BFs_kHz);
end
if isfield(unit,'EH_reFF')
   EHfeats=fieldnames(unit.EH_reFF);
   NUMrows=NUMrows+length(EHfeats);
   %    clear FeatINDs
   for FeatIND=1:length(EHfeats)
      FeatINDs(FeatIND)=find(strcmp(FeaturesText,EHfeats{FeatIND}));
   end
   
   F0min=Inf;
   for FeatIND=FeatINDs
      for HarmonicsIND=1:2
         for PolarityIND=1:2
            eval(['yTEMP=unit.EH_reFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
            if ~isempty(yTEMP)
               levels_dBSPL=union(levels_dBSPL,yTEMP.levels_dBSPL);
               if FeatIND==FeatINDs(1)
                  FeatureLevels_dB=yTEMP.FeatureLevels_dB;
               else   
                  if sum(FeatureLevels_dB(~isnan(FeatureLevels_dB))-yTEMP.FeatureLevels_dB(~isnan(yTEMP.FeatureLevels_dB)))
                     error('FeatureLevels_dB do not match across Features for this unit');
                  end
               end
               BFsTEMP_kHz=union(BFsTEMP_kHz,yTEMP.BFs_kHz);
               % Find minimum F0 for PERhist XMAX
               for i=1:length(yTEMP.FeatureFreqs_Hz)
                  if yTEMP.FeatureFreqs_Hz{i}(1)<F0min
                     F0min=yTEMP.FeatureFreqs_Hz{i}(1);
                  end
               end
            end
         end
      end
   end
end
lowBF=min(BFsTEMP_kHz);
highBF=max(BFsTEMP_kHz);
clear BFsTEMP_kHz;
TFiltWidth=1;   % What is a good number here?? is 1 OK, ow, you get major smoothing for low F0, and not much smoothing for high F0s

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DO ALL CALCS (BEFORE PLOTTING), e.g., PERhists, DFTs, SCCs, ...
%%%%   - runs through all BFs, levels and saves ALL calcs prior to PLOTTING (allows amart plotting based on ALL data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BFs_kHz=cell(NUMrows,length(levels_dBSPL));
PERhists=cell(NUMrows,length(levels_dBSPL));
PERhists_Smoothed=cell(NUMrows,length(levels_dBSPL));
PERhistXs_sec=cell(NUMrows,length(levels_dBSPL));  % for plotting
DFTs=cell(NUMrows,length(levels_dBSPL));
DFTfreqs_Hz=cell(NUMrows,length(levels_dBSPL));
Nsps=cell(NUMrows,length(levels_dBSPL));
Rates=cell(NUMrows,length(levels_dBSPL));
Synchs=cell(NUMrows,length(levels_dBSPL));
Phases=cell(NUMrows,length(levels_dBSPL));
PERhistsMAX=0;
PERhistsYCHANS=0;
DFTsMAX=0;
SMP_rate=cell(1,length(levels_dBSPL));
for LEVind=1:length(levels_dBSPL)   
   SMP_rate{LEVind}=NaN*ones(1,length(FeaturesText));
end
ALSRs=cell(NUMrows,length(levels_dBSPL));
SMP_alsr=cell(1,length(levels_dBSPL));
for LEVind=1:length(levels_dBSPL)
   SMP_alsr{LEVind}=NaN*ones(1,length(FeaturesText));
end

%%%% SCC variables and params
numSCCs=2; % Right now set to +&- SCC_octOFFSET octaves
SCC_octOFFSET=0.1; % parameter of the offset between BF and other AN fiber
clear paramsIN
paramsIN.SCC.StartTime_sec=.02;  % Take 20-400 ms as stimulus window
paramsIN.SCC.EndTime_sec=0.40;
paramsIN.SCC.DELAYbinwidth_sec=50e-6;  % 50e-6 is what Joris used
paramsIN.SCC.Duration_sec=paramsIN.SCC.EndTime_sec-paramsIN.SCC.StartTime_sec;

NSCCs=cell(NUMrows,length(levels_dBSPL));
NSCC_delays_usec=cell(NUMrows,length(levels_dBSPL));
NSCC_BFs_kHz=cell(NUMrows,length(levels_dBSPL));
NSCC_avgrates=cell(NUMrows,length(levels_dBSPL));
NSCC_nsps=cell(NUMrows,length(levels_dBSPL));
NSCC_CDs_usec=cell(NUMrows,length(levels_dBSPL));
NSCC_peaks=cell(NUMrows,length(levels_dBSPL));
NSCC_0delay=cell(NUMrows,length(levels_dBSPL));
SCCsMAX=0;
SMP_NSCC_0delay=cell(numSCCs,length(levels_dBSPL));
SMP_NSCC_CD=cell(numSCCs,length(levels_dBSPL));
SMP_NSCC_peak=cell(numSCCs,length(levels_dBSPL));
for i=1:numSCCs
   for LEVind=1:length(levels_dBSPL)
      SMP_NSCC_0delay{i,LEVind}=NaN*ones(1,length(FeaturesText));
      SMP_NSCC_CD{i,LEVind}=NaN*ones(1,length(FeaturesText));
      SMP_NSCC_peak{i,LEVind}=NaN*ones(1,length(FeaturesText));
   end
end


for LEVEL=levels_dBSPL
% beep
% disp('***** HARD CODED FOR ONLY 1 (highest) LEVEL *****')
% for LEVEL=levels_dBSPL(end)
   ROWind=0;
   
   %%%%%%%%%%%%%%%%%%%% Tone Calcs
   if isfield(unit,'Tone_reFF')
      ROWind=ROWind+1;
      
      %%%% Tone_reBF plots
      LEVind=find(unit.Tone_reFF.levels_dBSPL==LEVEL);
      PERhists{ROWind,LEVind}=cell(size(unit.Tone_reFF.BFs_kHz));
      
      PERhistXs_sec{ROWind,LEVind}=cell(size(unit.Tone_reFF.BFs_kHz));
      for BFind=1:length(unit.Tone_reFF.BFs_kHz)
         if ~isempty(unit.Tone_reFF.picNums{LEVind,BFind})
            
            PIC=concatPICS_NOHR(unit.Tone_reFF.picNums{LEVind,BFind},unit.Tone_reFF.excludeLines{LEVind,BFind});
            %             % Shift spikes and frequencies to simulate shifted-BF neuron with stimulus at nominal-BF
            %             PIC=simFF_PICshift(PIC);
            PIC=calcSynchRate_PERhist(PIC);  % Calculates PERIOD histogram as well
            
            BFs_kHz{ROWind,LEVind}(BFind)=unit.Tone_reFF.BFs_kHz(BFind);
            PERhists{ROWind,LEVind}{BFind}=PIC.PERhist.PERhist;
            
            % Filter PERhists with Triangular Filter: filter 3 reps, take middle rep to avoid edge effects and keep periodic
            N=length(PERhists{ROWind,LEVind}{BFind});
            SmoothedPERhist=trifilt(repmat(PERhists{ROWind,LEVind}{BFind},1,3),TFiltWidth);
            PERhists_Smoothed{ROWind,LEVind}{BFind}=SmoothedPERhist(N+1:2*N); % Take middle 3rd
            % Determine Maximum of ALL plotted PERhists (i.e., post-Smoothing)
            if max(PERhists_Smoothed{ROWind,LEVind}{BFind})>PERhistsMAX
               PERhistsMAX=max(PERhists_Smoothed{ROWind,LEVind}{BFind});
            end
            

            %%%%%%%%%%%%% NEED TO ADD ALL DFT stuff
            
            
            PERhistXs_sec{ROWind,LEVind}{BFind}=PIC.PERhist.PERhist_X_sec;
            Nsps{ROWind,LEVind}(BFind)=PIC.PERhist.NumDrivenSpikes;
            Rates{ROWind,LEVind}(BFind)=PIC.SynchRate_PERhist.SynchRate_PERhist(1);
            if PIC.SynchRate_PERhist.FeatureRaySig
               Synchs{ROWind,LEVind}(BFind)=PIC.SynchRate_PERhist.FeatureSynchs;
               Phases{ROWind,LEVind}(BFind)=PIC.SynchRate_PERhist.FeaturePhases;
            else
               Synchs{ROWind,LEVind}(BFind)=NaN;
               Phases{ROWind,LEVind}(BFind)=NaN;
            end
         else
            BFs_kHz{ROWind,LEVind}(BFind)=unit.Tone_reFF.BFs_kHz(BFind);
            Nsps{ROWind,LEVind}(BFind)=NaN;
            Rates{ROWind,LEVind}(BFind)=NaN;
            Synchs{ROWind,LEVind}(BFind)=NaN;
            Phases{ROWind,LEVind}(BFind)=NaN;
         end
      end
      % Determine how many CHANNELS to plot
      if length(unit.Tone_reFF.BFs_kHz)>PERhistsYCHANS
         PERhistsYCHANS=length(unit.Tone_reFF.BFs_kHz);
      end
   end   % if Tone data
   
   
   %%%%%%%%%%%%%%%%%%%% EH_reBF Calcs
   if isfield(unit,'EH_reFF')
      for FeatIND=FeatINDs
         ROWind=ROWind+1;
         for HarmonicsIND=1:1
            for PolarityIND=1:1
               eval(['yTEMP=unit.EH_reFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
               if ~isempty(yTEMP)
                  %%%% EH_reBF plots
                  LEVind=find(yTEMP.levels_dBSPL==LEVEL);
                  PERhists{ROWind,LEVind}=cell(size(yTEMP.BFs_kHz));
                  PERhistXs_sec{ROWind,LEVind}=cell(size(yTEMP.BFs_kHz));
                  
                  %%%% Decide which BFs needed for SCCs
                  [y,BF_INDEX]=min(abs(yTEMP.BFs_kHz-unit.Info.BF_kHz));  % Finds index of BF from yTEMP.BFs_kHz
                  SCC_allBFinds=[];
                  % First SCC is between BF and BF+SCC_octOFFSET octaves
                  SCCind=1;  % index of SCC to calculate
                  [y,BFind2]=min(abs(yTEMP.BFs_kHz-unit.Info.BF_kHz*2^SCC_octOFFSET));
                  if abs(log2(yTEMP.BFs_kHz(BFind2)/yTEMP.BFs_kHz(BF_INDEX))-SCC_octOFFSET)>0.05
                     warndlg('The two BFs used for the first (BF+Xoctaves) SCC are more than 0.05 octaves different than the desired distance')
                  end
                  NSCC_BFinds{SCCind}=[BF_INDEX BFind2];
                  SCC_allBFinds=[SCC_allBFinds NSCC_BFinds{SCCind}];
                  % Second SCC is between BF and BF+.25 octaves
                  SCCind=2;
                  [y,BFind2]=min(abs(yTEMP.BFs_kHz-unit.Info.BF_kHz*2^-SCC_octOFFSET));
                  if abs(log2(yTEMP.BFs_kHz(BFind2)/yTEMP.BFs_kHz(BF_INDEX))+SCC_octOFFSET)>0.05
                     warndlg('The two BFs used for the second (BF-Xoctaves) SCC are more than 0.05 octaves different than the desired distance')
                  end
                  NSCC_BFinds{SCCind}=[BF_INDEX BFind2];
                  SCC_allBFinds=[SCC_allBFinds NSCC_BFinds{SCCind}];
                  % Tally all BFs needed
                  SCC_allBFinds=unique(SCC_allBFinds);
                  SCC_allSpikeTrains=cell(size(yTEMP.BFs_kHz));  % Store Spike Trains (driven spikes), but on;y those we need for computing SCCs later
                  
                  for BFind=1:length(yTEMP.BFs_kHz)
                     if ~isempty(yTEMP.picNums{LEVind,BFind})
                        PIC=concatPICS_NOHR(yTEMP.picNums{LEVind,BFind},yTEMP.excludeLines{LEVind,BFind});
                        %                         % Shift spikes and frequencies to simulate shifted-BF neuron with stimulus at nominal-BF
                        %                         PIC=simFF_PICshift(PIC);
                        PIC=calcSynchRate_PERhist(PIC);  % Calculates PERIOD histogram as well
                        
                        BFs_kHz{ROWind,LEVind}(BFind)=yTEMP.BFs_kHz(BFind);
                        PERhists{ROWind,LEVind}{BFind}=PIC.PERhist.PERhist;
                        PERhistXs_sec{ROWind,LEVind}{BFind}=PIC.PERhist.PERhist_X_sec;

                        % Filter PERhists with Triangular Filter: filter 3 reps, take middle rep to avoid edge effects and keep periodic
                        N=length(PERhists{ROWind,LEVind}{BFind});
                        SmoothedPERhist=trifilt(repmat(PERhists{ROWind,LEVind}{BFind},1,3),TFiltWidth);
                        PERhists_Smoothed{ROWind,LEVind}{BFind}=SmoothedPERhist(N+1:2*N);
                        % Determine Maximum of ALL plotted PERhists (i.e., post-Smoothing)
                        if max(PERhists_Smoothed{ROWind,LEVind}{BFind})>PERhistsMAX
                           PERhistsMAX=max(PERhists_Smoothed{ROWind,LEVind}{BFind});
                        end                        
                        
                        % Save DFTs as well of PERhists
                        DFTs{ROWind,LEVind}{BFind}=PIC.SynchRate_PERhist.SynchRate_PERhist;
                        DFTfreqs_Hz{ROWind,LEVind}{BFind}=PIC.SynchRate_PERhist.FFTfreqs;
                        % Determine Maximum of ALL plotted DFTs
                        if max(abs(DFTs{ROWind,LEVind}{BFind}))>DFTsMAX
                           DFTsMAX=max(abs(DFTs{ROWind,LEVind}{BFind}));
                        end                        

                        Nsps{ROWind,LEVind}(BFind)=PIC.PERhist.NumDrivenSpikes;
                        Rates{ROWind,LEVind}(BFind)=PIC.SynchRate_PERhist.SynchRate_PERhist(1);
                        if PIC.SynchRate_PERhist.FeatureRaySig(FeatIND)
                           Synchs{ROWind,LEVind}(BFind)=PIC.SynchRate_PERhist.FeatureSynchs(FeatIND);
                           Phases{ROWind,LEVind}(BFind)=PIC.SynchRate_PERhist.FeaturePhases(FeatIND);
                        else
                           Synchs{ROWind,LEVind}(BFind)=NaN;
                           Phases{ROWind,LEVind}(BFind)=NaN;
                        end
                        
                        %%%% Save SpikeTrains for this BF if it is used for SCCs
                        SCCind=find(SCC_allBFinds==BFind);
                        if ~isempty(SCCind)
                           SCC_allSpikeTrains{BFind}=getDrivenSpikeTrains(PIC.x.spikes{1},[],[paramsIN.SCC.StartTime_sec paramsIN.SCC.EndTime_sec]);
                        end
                        
                     else
                        BFs_kHz{ROWind,LEVind}(BFind)=yTEMP.BFs_kHz(BFind);
                        Nsps{ROWind,LEVind}(BFind)=NaN;
                        Rates{ROWind,LEVind}(BFind)=NaN;
                        Synchs{ROWind,LEVind}(BFind)=NaN;
                        Phases{ROWind,LEVind}(BFind)=NaN;
                        
                        %%%% Warn that no SpikeTrains for this BF if it is used for SCCs
                        SCCind=find(SCC_allBFinds==BFind);
                        if ~isempty(SCCind)
                           warndlg('SCC_allSpikeTrains{SCCind} is set to EMPTY because no data for this BF!')
                        end                        
                     end
                  end % BFinds

                  %%%%%%%%%%%%%%%%
                  % Calculate ALSR data
                  %%%%%%%%%%%%%%%%
                  if ~isempty(DFTfreqs_Hz{ROWind,LEVind})
                     ALSR_OCTrange=0.28;  % Slight slop for slight mismatches in sampling rates
                     ALSRinds=find((yTEMP.BFs_kHz>=unit.Info.BF_kHz*2^-ALSR_OCTrange)&(yTEMP.BFs_kHz<=unit.Info.BF_kHz*2^ALSR_OCTrange));
                     if length(ALSRinds)<length(yTEMP.BFs_kHz)
                        warndlg('Not all channels taken in ALSR')  % TAKE OUT eventually, just want to know when we're not getting whole story
                     end
                     SynchRatesTEMP=NaN*ones(1,length(yTEMP.BFs_kHz));
                     for BFind=ALSRinds
                        [y,DFT_INDEX]=min(abs(DFTfreqs_Hz{ROWind,LEVind}{BFind}-unit.Info.BF_kHz*1000));
                        if ~isempty(DFT_INDEX)
                           SynchRatesTEMP(BFind)=abs(DFTs{ROWind,LEVind}{BFind}(DFT_INDEX));
                        end
                     end
                     ALSRs{ROWind,LEVind}=mean(SynchRatesTEMP(~isnan(SynchRatesTEMP)));
                  else
                     ALSRs{ROWind,LEVind}=NaN;
                  end
                  
                  %%%%%%%%%%%%%%%%
                  % Compute SCCs
                  %%%%%%%%%%%%%%%%
                  NSCCs{ROWind,LEVind}=cell(size(NSCC_BFinds));
                  NSCC_delays_usec{ROWind,LEVind}=cell(size(NSCC_BFinds));
                  NSCC_avgrates{ROWind,LEVind}=cell(size(NSCC_BFinds));
                  NSCC_nsps{ROWind,LEVind}=cell(size(NSCC_BFinds));
                  NSCC_BFskHz{ROWind,LEVind}=cell(size(NSCC_BFinds));
                  NSCC_CDs_usec{ROWind,LEVind}=cell(size(NSCC_BFinds));
                  NSCC_peaks{ROWind,LEVind}=cell(size(NSCC_BFinds));
                  NSCC_0delay{ROWind,LEVind}=cell(size(NSCC_BFinds));
                  for SCCind=1:length(NSCC_BFinds)  % index of SCC to calculate
                     % Find SpikeTrains needed for this SCC
                     for i=1:2
                        SpikeTrains{i}=SCC_allSpikeTrains{NSCC_BFinds{SCCind}(i)};
                     end
                     disp(sprintf('Feature: %s; Level: %.f  --  Computing SCC # %d between BFs %d and %d ........', ...
                        FeaturesText{FeatIND},levels_dBSPL(LEVind),SCCind,NSCC_BFinds{SCCind}))                     
                     [NSCCs{ROWind,LEVind}{SCCind},NSCC_delays_usec{ROWind,LEVind}{SCCind},NSCC_avgrates{ROWind,LEVind}{SCCind},NSCC_nsps{ROWind,LEVind}{SCCind}] ...
                        = ShufCrossCorr(SpikeTrains,paramsIN.SCC.DELAYbinwidth_sec,paramsIN.SCC.Duration_sec);
                     
                     % Determine Maximum of ALL plotted SCCs (i.e., post-Smoothing)
                     if max(NSCCs{ROWind,LEVind}{SCCind})>SCCsMAX
                        SCCsMAX=max(NSCCs{ROWind,LEVind}{SCCind});
                     end
                     NSCC_BFskHz{ROWind,LEVind}{SCCind}=[yTEMP.BFs_kHz(NSCC_BFinds{SCCind}(1)),yTEMP.BFs_kHz(NSCC_BFinds{SCCind}(2))];                     
                     NSCC_0delay{ROWind,LEVind}{SCCind}=NSCCs{ROWind,LEVind}{SCCind}(find(NSCC_delays_usec{ROWind,LEVind}{SCCind}==0));

                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     %%%% Finding CD is TOUGH!!!! %%%%                                                %
                     %                                                                                %
                     % Need a robust way to do it                                                     %
                     % 1) Find Local Maxima within 1 period, based on 3-pt smoothed NSCC              %
                     % 2) Restrict to only those within 15% of max                                    %
                     % 3) Take local max closest to 0                                                 %
                     % *** THIS SOMETIMES CHOOSES CD close to 0, when the NSCC is fairly periodic     %
                     %     BUT, these are just tough ones to get right without a lot of "knowledge"   %
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     
                     F0per_us=1/yTEMP.FeatureFreqs_Hz{1}(1)*1e6;
                     delaysTEMP_usec=NSCC_delays_usec{ROWind,LEVind}{SCCind}(find((NSCC_delays_usec{ROWind,LEVind}{SCCind}>=-F0per_us)&(NSCC_delays_usec{ROWind,LEVind}{SCCind}<=F0per_us)));
                     nsccTEMP=NSCCs{ROWind,LEVind}{SCCind}(find((NSCC_delays_usec{ROWind,LEVind}{SCCind}>=-F0per_us)&(NSCC_delays_usec{ROWind,LEVind}{SCCind}<=F0per_us)));
                     
                     %%%%%%%%%%% LOCAL MAXIMA
                     NSCC_TFiltWidth=3;
                     %%%% find local max within 1 period, based on smoothed SCCs
                     diff_LtoR=diff(trifilt(nsccTEMP,NSCC_TFiltWidth));
                     diff_RtoL=diff(fliplr(trifilt(nsccTEMP,NSCC_TFiltWidth)));
                     diffDelays_LtoR=delaysTEMP_usec(1:end-1);
                     diffDelays_RtoL=fliplr(delaysTEMP_usec(2:end));
                     LocalMaxDelays1=intersect(diffDelays_LtoR(find(diff_LtoR<0)),diffDelays_RtoL(find(diff_RtoL<0)));
                     LocalMaxDelays=intersect(LocalMaxDelays1,delaysTEMP_usec(find(nsccTEMP>=1)));
                     nsccLocalMax=zeros(size(LocalMaxDelays));
                     for i=1:length(LocalMaxDelays)
                        nsccLocalMax(i)=nsccTEMP(find(delaysTEMP_usec==LocalMaxDelays(i)));
                     end
                     
                     %% Restrict to local max within 15% of peak
                     PercCRIT=0.15;
                     RESTRICTinds=find(nsccLocalMax>max(nsccLocalMax)*(1-PercCRIT));
                     LocalMaxDelaysRESTRICT=LocalMaxDelays(RESTRICTinds);
                     nsccLocalMaxRESTRICT=nsccLocalMax(RESTRICTinds);
                     
                     [y,i]=min(abs(LocalMaxDelaysRESTRICT));
                     NSCC_CDs_usec{ROWind,LEVind}{SCCind}=LocalMaxDelaysRESTRICT(i);
                     NSCC_peaks{ROWind,LEVind}{SCCind}=nsccLocalMaxRESTRICT(i);  % This is not actually the peak, but the NSCC at the CD
                     
                     %                   % TO COMPUTE
                     %                   *NSCCs
                     %                   *NSCC_delays_usec
                     %                   *NSCC_BFs_kHz
                     %                   *NSCC_avgrates
                     %                   *NSCC_nsps
                     %                   *NSCC_CDs_usec
                     %                   *NSCC_peaks
                     %                   *NSCC_0delay

                     
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                     
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                     
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                     
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                     
                     %%%%%%%%%%%%%%%% 2/5/05 TODO %%%%%%%%%%%%%%%%%%%%%%%%%%%
                     % *1) Compute peak, CD (use 1/F0 to limit search?)
                     % *2) Setup *NSCC and SCC plots, 
                     %         and plot SCC and NSCC values
                     % *3) Set up SMP plots
                     % 4) Start to looking at data to see effects!!!!
                     %      - look for CNL
                     %      - look for robust SCCs
                     %              - !!! LOOKS LIKE D&G story holds, largest Cross-Corr is at troughs, drops at formants
                     %      - DEVELOP STORY
                     
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     %%%%%%%%%%%%%%%%%%%% TODO  2/2/05 %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     % Compute these 2 SCCs for demo, and get all things working
                     % TRY to setup general, simple implementation of these things 
                     % Then can start looking for real issues
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     
                     
                  end
                  
                  
                  %%%%%%%%%%%%%%%%
                  % Store SMP data
                  %%%%%%%%%%%%%%%%
                  SMP_rate{LEVind}(FeatIND)=Rates{ROWind,LEVind}(BF_INDEX);
                  SMP_alsr{LEVind}(FeatIND)=ALSRs{ROWind,LEVind};
                  
                  for i=1:numSCCs
                     SMP_NSCC_0delay{i,LEVind}(FeatIND)=NSCC_0delay{ROWind,LEVind}{i};
                     SMP_NSCC_CD{i,LEVind}(FeatIND)=NSCC_CDs_usec{ROWind,LEVind}{i};
                     SMP_NSCC_peak{i,LEVind}(FeatIND)=NSCC_peaks{ROWind,LEVind}{i};
                  end
                  
                  % Determine how many CHANNELS to plot
                  if length(yTEMP.BFs_kHz)>PERhistsYCHANS
                     PERhistsYCHANS=length(yTEMP.BFs_kHz);
                  end
               end %End if data for this condition, plot
            end % End Polarity
         end % End Harmonics
      end % End Feature
   end % If EHrBF data
end % Levels


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DO ALL PERhist PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FeatureColors={'r','g'};
PERhist_XMAX=1/F0min*1000;
XLIMITS_perhist=[0 PERhist_XMAX];
XLIMITS_rate=[0 300];
XLIMITS_synch=[0 1];
XLIMITS_phase=[-pi pi];
%% Find PERhist_YMAX
PERhistGAIN=3.0; % # of channels covered by max PERhist
PERhists_logCHwidth=log10(highBF/lowBF)/(PERhistsYCHANS-1);  % log10 channel width
PERhist_YMIN=lowBF;
PERhist_YMAX=10^((PERhistsYCHANS-1+PERhistGAIN)*PERhists_logCHwidth)*lowBF;    % sets an extra (GAIN-1) log channel widths
YLIMITS=[PERhist_YMIN PERhist_YMAX];  % Used for all plots
%% This  is ALL needed to get the right LOG Yticks!!
YLIMunit=10^floor(log10(lowBF));
YLIMS=floor(lowBF/YLIMunit)*YLIMunit*[1 100]; % Do two decades to be sure we get all the ticks
YTICKS=[YLIMS(1):YLIMunit:YLIMS(1)*10 YLIMS(1)*20:YLIMunit*10:YLIMS(end)];
BFoctCRIT=1/128;  % Chooses as BF channel is within 1/128 octave

% Setup parameters for title
if isempty(unit.Info.SR_sps)
   unit.Info.SR_sps=NaN;
end
if isempty(unit.Info.Q10)
   unit.Info.Q10=NaN;
end

for LEVEL=levels_dBSPL
% beep
% disp('***** HARD CODED FOR ONLY 1 (highest) LEVEL *****')
% for LEVEL=levels_dBSPL(end)
   figure(round(LEVEL)); clf
   set(gcf,'pos',[420     4   977   976])
   ROWind=0;
   
   %%%%%%%%%%%%%%%%%%%% Tone Plots
   if isfield(unit,'Tone_reFF')
      ROWind=ROWind+1;
      
      %%%% Tone_reBF plots
      LEVind=find(unit.Tone_reFF.levels_dBSPL==LEVEL);
      
      %       figure(round(unit.Tone_reFF.levels_dBSPL(LEVind)))
      PLOTnum=(ROWind-1)*NUMcols+1;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      for BFind=1:length(BFs_kHz{ROWind,LEVind})   
         if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,LEVind}/unit.Info.BF_kHz))<BFoctCRIT))
            LINEwidth=2;
         else
            LINEwidth=.5;
         end
         NormFact=(10^(PERhistGAIN*PERhists_logCHwidth)-1)*BFs_kHz{ROWind,LEVind}(BFind)/PERhistsMAX;  % Normalizes so each plot is equal size on log y-axis
         semilogy(PERhistXs_sec{ROWind,LEVind}{BFind}*1000, ...
            PERhists_Smoothed{ROWind,LEVind}{BFind}*NormFact+BFs_kHz{ROWind,LEVind}(BFind), ...
            'LineWidth',LINEwidth)
         hold on
      end
      semilogy(XLIMITS_perhist,unit.Info.BF_kHz*[1 1],'k:')
      xlabel('Time (ms)')
      ylabel('Effective Best Frequency (kHz)')
      title(sprintf('     Exp%s, Unit %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s @ %.f dB SPL', ...
         ExpDate,UnitName,unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,'TONE', ...
         unit.Tone_reFF.levels_dBSPL(LEVind)),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
      %       xlim([0 max(PERhistXs_sec{ROWind,LEVind}{BFind}*1000)]) % Different xlim for TONES ??? 
      xlim(XLIMITS_perhist)
      PLOThand=eval(['h' num2str(PLOTnum)]);
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      ylim(YLIMITS)  % Same Ylimits for all plots
      text(XLIMITS_perhist(2),YLIMITS(1),'1/f','units','data','HorizontalAlignment','center','VerticalAlignment','top')
      hold off
      
      %%%% Rate Plot
      PLOTnum=(ROWind-1)*NUMcols+2;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      semilogy(Rates{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
      hold on
      semilogy(Nsps{ROWind,LEVind}/10,BFs_kHz{ROWind,LEVind},'m+','MarkerSize',4)
      semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
      xlabel(sprintf('Rate (sp/sec)\n[+: # of spikes/10]'))
      PLOThand=eval(['h' num2str(PLOTnum)]);
      xlim(XLIMITS_rate)
      set(PLOThand,'XDir','reverse')
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      ylim(YLIMITS)  % Same Ylimits for all plots
      hold off
      
      %%%% Synch Plot
      PLOTnum=(ROWind-1)*NUMcols+3;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      semilogy(Synchs{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
      hold on
      semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
      xlabel('Synch Coef (to f)')
      PLOThand=eval(['h' num2str(PLOTnum)]);
      xlim(XLIMITS_synch)
      set(PLOThand,'XDir','reverse')
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      set(gca,'XTick',[0 .25 .5 .75 1],'XTickLabel',{'0','.25','.5','.75','1'})
      ylim(YLIMITS)  % Same Ylimits for all plots
      hold off
      
      %%%% Phase Plot
      PLOTnum=(ROWind-1)*NUMcols+4;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      semilogy(Phases{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
      hold on
      semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
      xlabel('Phase (cycles of f)')
      PLOThand=eval(['h' num2str(PLOTnum)]);
      xlim(XLIMITS_phase)
      set(PLOThand,'XDir','reverse','XTick',[-pi -pi/2 0 pi/2 pi],'XTickLabel',[-1 -1/2 0 1/2 1])
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      ylim(YLIMITS)  % Same Ylimits for all plots
      hold off
      
   end   
   
   
   %%%%%%%%%%%%%%%%%%%% EH_reBF Plots
   if isfield(unit,'EH_reFF')
      for FeatIND=FeatINDs
         ROWind=ROWind+1;
         for HarmonicsIND=1:1
            for PolarityIND=1:1
               eval(['yTEMP=unit.EH_reFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
               if ~isempty(yTEMP)
                  %%%% EH_reBF plots
                  LEVind=find(yTEMP.levels_dBSPL==LEVEL);
                  
                  %%%% Spatio-Temporal Plots
                  PLOTnum=(ROWind-1)*NUMcols+1;
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  for BFind=1:length(BFs_kHz{ROWind,LEVind})
                     if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,LEVind}/unit.Info.BF_kHz))<BFoctCRIT))
                        LINEwidth=2;
                     else
                        LINEwidth=.5;
                     end
                     % This normalization plots each signal the same size on a log scale
                     if ~isempty(PERhistXs_sec{ROWind,LEVind}{BFind})
                        NormFact=(10^(PERhistGAIN*PERhists_logCHwidth)-1)*BFs_kHz{ROWind,LEVind}(BFind)/PERhistsMAX;
                        semilogy(PERhistXs_sec{ROWind,LEVind}{BFind}*1000, ...
                           PERhists_Smoothed{ROWind,LEVind}{BFind}*NormFact+BFs_kHz{ROWind,LEVind}(BFind), ...
                           'LineWidth',LINEwidth)
                        hold on
                     end
                  end
                  xlabel('Time (ms)')
                  ylabel('Effective Best Frequency (kHz)')                  
                  if ROWind==1
                     title(sprintf('     Exp%s, Units %s - %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s @ %.f dB SPL,   Harm: %d, Polarity: %d', ...
                        ExpDate,UnitNames{1},UnitNames{end},unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,FeaturesText{FeatIND}, ...
                        yTEMP.levels_dBSPL(LEVind),HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
                  else
                     title(sprintf('%s @ %.f dB SPL,   Harm: %d, Polarity: %d',FeaturesText{FeatIND}, ...
                        yTEMP.levels_dBSPL(LEVind),HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
                  end
                  xlim(XLIMITS_perhist)
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_perhist,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                        text(XLIMITS_perhist(2)*1.005,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000, ...
                           sprintf('%s (%.1f)',FeaturesText{FeatINDPlot},yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000), ...
                           'units','data','HorizontalAlignment','left','VerticalAlignment','middle','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                     for BFind=1:length(BFs_kHz{ROWind,LEVind})
                        if ~isempty(PERhistXs_sec{ROWind,LEVind}{BFind})
                           if (FeatINDPlot<=FeatIND)
                              if (FeatINDPlot>1)
                                 text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
                                    'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                              else
                                 text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
                                    'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color','k')
                              end
                           end
                        end
                     end
                  end
                  hold off
                  
                  
                  %%%% Rate Plot
                  PLOTnum=(ROWind-1)*NUMcols+2;   
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  semilogy(Rates{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
                  hold on
                  semilogy(Nsps{ROWind,LEVind}/10,BFs_kHz{ROWind,LEVind},'m+','MarkerSize',4)
                  semilogy(ALSRs{ROWind,LEVind},unit.Info.BF_kHz,'go','MarkerSize',6)
                  semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
                  xlabel(sprintf('Rate (sp/sec)\n[+: # of spikes/10]\nO: ALSR'))
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  xlim(XLIMITS_rate)
                  set(PLOThand,'XDir','reverse')
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_rate,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                  end
                  hold off
                  
                  %%%% Synch Plot
                  PLOTnum=(ROWind-1)*NUMcols+3;   
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  semilogy(Synchs{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
                  hold on
                  semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
                  xlabel(sprintf('Synch Coef (to %s)',FeaturesText{FeatIND}))
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  xlim(XLIMITS_synch)
                  set(PLOThand,'XDir','reverse')
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  set(gca,'XTick',[0 .25 .5 .75 1],'XTickLabel',{'0','.25','.5','.75','1'})
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_synch,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                  end
                  hold off
                  
                  %%%% Phase Plot
                  PLOTnum=(ROWind-1)*NUMcols+4;   
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  semilogy(Phases{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
                  hold on
                  semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
                  xlabel(sprintf('Phase (cycles of %s)',FeaturesText{FeatIND}))
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  xlim(XLIMITS_phase)
                  set(PLOThand,'XDir','reverse','XTick',[-pi -pi/2 0 pi/2 pi],'XTickLabel',[-1 -1/2 0 1/2 1])
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_phase,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                  end
                  hold off
                  
               end %End if data for this condition, plot
            end % End Polarity
         end % End Harmonics
      end % End Feature
   end
   
   
   Xcorner=0.05;
   Xwidth1=.5;
   Xshift1=0.05;
   Xwidth2=.1;
   Xshift2=0.03;
   
   Ycorner=0.05;
   Yshift=0.07;
   Ywidth=(1-NUMrows*(Yshift+.01))/NUMrows;   %.26 for 3; .42 for 2
   
   TICKlength=0.02;
   
   if NUMrows>4
      set(h17,'Position',[Xcorner Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h18,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h19,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h20,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   if NUMrows>3
      set(h13,'Position',[Xcorner Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h14,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h15,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h16,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   if NUMrows>2
      set(h9,'Position',[Xcorner Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h10,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h11,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h12,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   if NUMrows>1
      set(h5,'Position',[Xcorner Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h6,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h7,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h8,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   set(h1,'Position',[Xcorner Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
   set(h2,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   set(h3,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   set(h4,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   
   orient landscape
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DO ALL DFT PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XLIMITS_dft=[0 10];

for LEVEL=levels_dBSPL
% beep
% disp('***** HARD CODED FOR ONLY 1 (highest) LEVEL *****')
% for LEVEL=levels_dBSPL(end)
   figure(round(LEVEL)+1); clf
   set(gcf,'pos',[420     4   977   976])
   ROWind=0;
   
   %%%%%%%%%%%%%%%%%%%% Tone Plots
   if isfield(unit,'Tone_reFF')
      ROWind=ROWind+1;
      
      %%%% Tone_reBF plots
      LEVind=find(unit.Tone_reFF.levels_dBSPL==LEVEL);
      
      %       figure(round(unit.Tone_reFF.levels_dBSPL(LEVind)))
      PLOTnum=(ROWind-1)*NUMcols+1;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      for BFind=1:length(BFs_kHz{ROWind,LEVind})   
         if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,LEVind}/unit.Info.BF_kHz))<BFoctCRIT))
            LINEwidth=2;
         else
            LINEwidth=.5;
         end
         NormFact=(10^(PERhistGAIN*PERhists_logCHwidth)-1)*BFs_kHz{ROWind,LEVind}(BFind)/PERhistsMAX;  % Normalizes so each plot is equal size on log y-axis

         
         
         %%%%%%%%% NEED TO ADD ALL DFT Stuff FOR TONES
         disp('***** STILL NEED TO ADD ALL DFT STUFF FOR TONES')
        
         
         
         
         semilogy(PERhistXs_sec{ROWind,LEVind}{BFind}*1000, ...
            trifilt(PERhists_Smoothed{ROWind,LEVind}{BFind}*NormFact,TFiltWidth)+BFs_kHz{ROWind,LEVind}(BFind), ...
            'LineWidth',LINEwidth)
         hold on
      end
      semilogy(XLIMITS_dft,unit.Info.BF_kHz*[1 1],'k:')
      xlabel('Time (ms)')
      ylabel('Effective Best Frequency (kHz)')
      title(sprintf('     Exp%s, Units %s - %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s @ %.f dB SPL', ...
         ExpDate,UnitNames{1},UnitNames{end},unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,'TONE', ...
         unit.Tone_reFF.levels_dBSPL(LEVind)),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
      %       xlim([0 max(PERhistXs_sec{ROWind,LEVind}{BFind}*1000)]) % Different xlim for TONES ??? 
      xlim(XLIMITS_dft)
      PLOThand=eval(['h' num2str(PLOTnum)]);
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      ylim(YLIMITS)  % Same Ylimits for all plots
      text(XLIMITS_dft(2),YLIMITS(1),'1/f','units','data','HorizontalAlignment','center','VerticalAlignment','top')
      hold off
      
      %%%% Rate Plot
      PLOTnum=(ROWind-1)*NUMcols+2;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      semilogy(Rates{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
      hold on
      semilogy(Nsps{ROWind,LEVind}/10,BFs_kHz{ROWind,LEVind},'m+','MarkerSize',4)
      semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
      xlabel(sprintf('Rate (sp/sec)\n[+: # of spikes/10]'))
      PLOThand=eval(['h' num2str(PLOTnum)]);
      xlim(XLIMITS_rate)
      set(PLOThand,'XDir','reverse')
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      ylim(YLIMITS)  % Same Ylimits for all plots
      hold off
      
      %%%% Synch Plot
      PLOTnum=(ROWind-1)*NUMcols+3;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      semilogy(Synchs{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
      hold on
      semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
      xlabel('Synch Coef (to f)')
      PLOThand=eval(['h' num2str(PLOTnum)]);
      xlim(XLIMITS_synch)
      set(PLOThand,'XDir','reverse')
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      set(gca,'XTick',[0 .25 .5 .75 1],'XTickLabel',{'0','.25','.5','.75','1'})
      ylim(YLIMITS)  % Same Ylimits for all plots
      hold off
      
      %%%% Phase Plot
      PLOTnum=(ROWind-1)*NUMcols+4;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      semilogy(Phases{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
      hold on
      semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
      xlabel('Phase (cycles of f)')
      PLOThand=eval(['h' num2str(PLOTnum)]);
      xlim(XLIMITS_phase)
      set(PLOThand,'XDir','reverse','XTick',[-pi -pi/2 0 pi/2 pi],'XTickLabel',[-1 -1/2 0 1/2 1])
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      ylim(YLIMITS)  % Same Ylimits for all plots
      hold off
      
   end   
   
   
   %%%%%%%%%%%%%%%%%%%% EH_reBF Plots
   if isfield(unit,'EH_reFF')
      for FeatIND=FeatINDs
         ROWind=ROWind+1;
         for HarmonicsIND=1:1
            for PolarityIND=1:1
               eval(['yTEMP=unit.EH_reFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
               if ~isempty(yTEMP)
                  %%%% EH_reBF plots
                  LEVind=find(yTEMP.levels_dBSPL==LEVEL);
                  
                  %%%% Spatio-Temporal Plots
                  PLOTnum=(ROWind-1)*NUMcols+1;
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  for BFind=1:length(BFs_kHz{ROWind,LEVind})
                     if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,LEVind}/unit.Info.BF_kHz))<BFoctCRIT))
                        LINEwidth=2;
                     else
                        LINEwidth=.5;
                     end
                     % This normalization plots each signal the same size on a log scale
                     if ~isempty(PERhistXs_sec{ROWind,LEVind}{BFind})
                        NormFact=(10^(PERhistGAIN*PERhists_logCHwidth)-1)*BFs_kHz{ROWind,LEVind}(BFind)/DFTsMAX;
%                         plot(DFTfreqs_Hz{ROWind,LEVind}{BFind}/1000, ...
%                            abs(DFTs{ROWind,LEVind}{BFind})*NormFact+BFs_kHz{ROWind,LEVind}(BFind),'b-x', ...
%                            'LineWidth',LINEwidth)
                        semilogy(DFTfreqs_Hz{ROWind,LEVind}{BFind}/1000, ...
                           abs(DFTs{ROWind,LEVind}{BFind})*NormFact+BFs_kHz{ROWind,LEVind}(BFind),'b-x', ...
                           'LineWidth',LINEwidth)
                        hold on
                     end
                  end
                  %                   plot([1e-6 1e6],[1e-6 1e6],'k')
                  semilogy(BFs_kHz{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'k')
                  xlabel('Stimulus Frequency (kHz)')
                  ylabel('Effective Best Frequency (kHz)')                  
                  if ROWind==1
                     title(sprintf('     Exp%s, Units %s - %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s @ %.f dB SPL,   Harm: %d, Polarity: %d', ...
                        ExpDate,UnitNames{1},UnitNames{end},unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,FeaturesText{FeatIND}, ...
                        yTEMP.levels_dBSPL(LEVind),HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
                  else
                     title(sprintf('%s @ %.f dB SPL,   Harm: %d, Polarity: %d',FeaturesText{FeatIND}, ...
                        yTEMP.levels_dBSPL(LEVind),HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
                  end
                  xlim(XLIMITS_dft)
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_dft,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                        text(XLIMITS_dft(2)*1.005,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000, ...
                           sprintf('%s (%.1f)',FeaturesText{FeatINDPlot},yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000), ...
                           'units','data','HorizontalAlignment','left','VerticalAlignment','middle','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                     semilogy(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],YLIMITS,':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     text(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000,YLIMITS(1)*1.0, ...
                        sprintf('%s',FeaturesText{FeatINDPlot}),'units','data','HorizontalAlignment','center','VerticalAlignment','top', ...
                        'Color',FeatureColors{-rem(FeatINDPlot,2)+2},'FontSize',6)
%                      for BFind=1:length(BFs_kHz{ROWind,LEVind})
%                         if ~isempty(PERhistXs_sec{ROWind,LEVind}{BFind})
%                            if (FeatINDPlot<=FeatIND)
%                               if (FeatINDPlot>1)
%                                  text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
%                                     'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color',FeatureColors{-rem(FeatINDPlot,2)+2})
%                               else
%                                  text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
%                                     'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color','k')
%                               end
%                            end
%                         end
%                      end
                  end
                  hold off
                  
                  
                  %%%% Rate Plot
                  PLOTnum=(ROWind-1)*NUMcols+2;   
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  semilogy(Rates{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
                  hold on
                  semilogy(Nsps{ROWind,LEVind}/10,BFs_kHz{ROWind,LEVind},'m+','MarkerSize',4)
                  semilogy(ALSRs{ROWind,LEVind},unit.Info.BF_kHz,'go','MarkerSize',6)
                  semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
                  xlabel(sprintf('Rate (sp/sec)\n[+: # of spikes/10]\nO: ALSR'))
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  xlim(XLIMITS_rate)
                  set(PLOThand,'XDir','reverse')
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_rate,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                  end
                  hold off
                  
                  %%%% Synch Plot
                  PLOTnum=(ROWind-1)*NUMcols+3;   
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  semilogy(Synchs{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
                  hold on
                  semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
                  xlabel(sprintf('Synch Coef (to %s)',FeaturesText{FeatIND}))
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  xlim(XLIMITS_synch)
                  set(PLOThand,'XDir','reverse')
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  set(gca,'XTick',[0 .25 .5 .75 1],'XTickLabel',{'0','.25','.5','.75','1'})
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_synch,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                  end
                  hold off
                  
                  %%%% Phase Plot
                  PLOTnum=(ROWind-1)*NUMcols+4;   
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  semilogy(Phases{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
                  hold on
                  semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
                  xlabel(sprintf('Phase (cycles of %s)',FeaturesText{FeatIND}))
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  xlim(XLIMITS_phase)
                  set(PLOThand,'XDir','reverse','XTick',[-pi -pi/2 0 pi/2 pi],'XTickLabel',[-1 -1/2 0 1/2 1])
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_phase,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                  end
                  hold off
                  
               end %End if data for this condition, plot
            end % End Polarity
         end % End Harmonics
      end % End Feature
   end
   
   
   Xcorner=0.05;
   Xwidth1=.5;
   Xshift1=0.05;
   Xwidth2=.1;
   Xshift2=0.03;
   
   Ycorner=0.05;
   Yshift=0.07;
   Ywidth=(1-NUMrows*(Yshift+.01))/NUMrows;   %.26 for 3; .42 for 2
   
   TICKlength=0.02;
   
   if NUMrows>4
      set(h17,'Position',[Xcorner Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h18,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h19,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h20,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   if NUMrows>3
      set(h13,'Position',[Xcorner Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h14,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h15,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h16,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   if NUMrows>2
      set(h9,'Position',[Xcorner Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h10,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h11,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h12,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   if NUMrows>1
      set(h5,'Position',[Xcorner Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h6,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h7,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h8,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   set(h1,'Position',[Xcorner Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
   set(h2,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   set(h3,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   set(h4,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   
   orient landscape
end










%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DO ALL SCC PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FeatureColors={'r','g'};
% PERhist_XMAX=1/F0min*1000;
XLIMITS_scc=1*[-PERhist_XMAX PERhist_XMAX];
% XLIMITS_rate=[0 300];
% XLIMITS_synch=[0 1];
% XLIMITS_phase=[-pi pi];
sccGAIN=5.0; % # of channels covered by max PERhist
% SCCs_logCHwidth=log10(highBF/lowBF)/(PERhistsYCHANS-1);  % log10 channel width
% PERhist_YMIN=lowBF;
% PERhist_YMAX=10^((PERhistsYCHANS-1+PERhistGAIN)*PERhists_logCHwidth)*lowBF;    % sets an extra (GAIN-1) log channel widths
scc_logCHwidth=PERhists_logCHwidth;  % log10 channel width
% scc_YMIN=PERhist_YMIN;
% YLIMITS=[scc_YMIN scc_YMAX];  % SAME Used for all plots
%% This  is ALL needed to get the right LOG Yticks!!
% YLIMunit=10^floor(log10(lowBF));
% YLIMS=floor(lowBF/YLIMunit)*YLIMunit*[1 100]; % Do two decades to be sure we get all the ticks
% YTICKS=[YLIMS(1):YLIMunit:YLIMS(1)*10 YLIMS(1)*20:YLIMunit*10:YLIMS(end)];
% BFoctCRIT=1/128;  % Chooses as BF channel is within 1/128 octave

for LEVEL=levels_dBSPL
% beep
% disp('***** HARD CODED FOR ONLY 1 (highest) LEVEL *****')
% for LEVEL=levels_dBSPL(end)
   figure(round(LEVEL)+2); clf
   set(gcf,'pos',[420     4   977   976])
   ROWind=0;
   
   %%%%%%%%%%%%%%%%%%%% Tone Plots
   if isfield(unit,'Tone_reFF')
      ROWind=ROWind+1;
      
      %%%% Tone_reBF plots
      LEVind=find(unit.Tone_reFF.levels_dBSPL==LEVEL);
      
      %       figure(round(unit.Tone_reFF.levels_dBSPL(LEVind)))
      PLOTnum=(ROWind-1)*NUMcols+1;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      for BFind=1:length(BFs_kHz{ROWind,LEVind})   
         if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,LEVind}/unit.Info.BF_kHz))<BFoctCRIT))
            LINEwidth=2;
         else
            LINEwidth=.5;
         end
         NormFact=(10^(PERhistGAIN*PERhists_logCHwidth)-1)*BFs_kHz{ROWind,LEVind}(BFind)/PERhistsMAX;  % Normalizes so each plot is equal size on log y-axis
         semilogy(PERhistXs_sec{ROWind,LEVind}{BFind}*1000, ...
            PERhists_Smoothed{ROWind,LEVind}{BFind}*NormFact+BFs_kHz{ROWind,LEVind}(BFind), ...
            'LineWidth',LINEwidth)
         hold on
      end
      semilogy(XLIMITS_perhist,unit.Info.BF_kHz*[1 1],'k:')
      xlabel('Time (ms)')
      ylabel('Effective Best Frequency (kHz)')
      title(sprintf('     Exp%s, Units %s - %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s @ %.f dB SPL', ...
         ExpDate,UnitNames{1},UnitNames{end},unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,'TONE', ...
         unit.Tone_reFF.levels_dBSPL(LEVind)),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
      %       xlim([0 max(PERhistXs_sec{ROWind,LEVind}{BFind}*1000)]) % Different xlim for TONES ??? 
      xlim(XLIMITS_perhist)
      PLOThand=eval(['h' num2str(PLOTnum)]);
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      ylim(YLIMITS)  % Same Ylimits for all plots
      text(XLIMITS_perhist(2),YLIMITS(1),'1/f','units','data','HorizontalAlignment','center','VerticalAlignment','top')
      hold off
      
      %%%% Rate Plot
      PLOTnum=(ROWind-1)*NUMcols+2;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      semilogy(Rates{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
      hold on
      semilogy(Nsps{ROWind,LEVind}/10,BFs_kHz{ROWind,LEVind},'m+','MarkerSize',4)
      semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
      xlabel(sprintf('Rate (sp/sec)\n[+: # of spikes/10]'))
      PLOThand=eval(['h' num2str(PLOTnum)]);
      xlim(XLIMITS_rate)
      set(PLOThand,'XDir','reverse')
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      ylim(YLIMITS)  % Same Ylimits for all plots
      hold off
      
      %%%% Synch Plot
      PLOTnum=(ROWind-1)*NUMcols+3;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      semilogy(Synchs{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
      hold on
      semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
      xlabel('Synch Coef (to f)')
      PLOThand=eval(['h' num2str(PLOTnum)]);
      xlim(XLIMITS_synch)
      set(PLOThand,'XDir','reverse')
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      set(gca,'XTick',[0 .25 .5 .75 1],'XTickLabel',{'0','.25','.5','.75','1'})
      ylim(YLIMITS)  % Same Ylimits for all plots
      hold off
      
      %%%% Phase Plot
      PLOTnum=(ROWind-1)*NUMcols+4;   
      eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
      semilogy(Phases{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
      hold on
      semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
      xlabel('Phase (cycles of f)')
      PLOThand=eval(['h' num2str(PLOTnum)]);
      xlim(XLIMITS_phase)
      set(PLOThand,'XDir','reverse','XTick',[-pi -pi/2 0 pi/2 pi],'XTickLabel',[-1 -1/2 0 1/2 1])
      set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
      ylim(YLIMITS)  % Same Ylimits for all plots
      hold off
      
   end   
   
   
   %%%%%%%%%%%%%%%%%%%% EH_reBF Plots
   if isfield(unit,'EH_reFF')
      for FeatIND=FeatINDs
         ROWind=ROWind+1;
         for HarmonicsIND=1:1
            for PolarityIND=1:1
               eval(['yTEMP=unit.EH_reFF.' FeaturesText{FeatIND} '{HarmonicsIND,PolarityIND};'])
               if ~isempty(yTEMP)
                  %%%% EH_reBF plots
                  LEVind=find(yTEMP.levels_dBSPL==LEVEL);
                  
                  %%%% Spatio-Temporal Plots
                  PLOTnum=(ROWind-1)*NUMcols+1;
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  for SCCind=1:length(NSCCs{ROWind,LEVind})
                     %                      if ismember(BFind,find(abs(log2(BFs_kHz{ROWind,LEVind}/unit.Info.BF_kHz))<BFoctCRIT))
                     %                         LINEwidth=2;
                     %                      else
                     LINEwidth=.5;
                     %                      end
                     % This normalization plots each signal the same size on a log scale
                     if ~isempty(NSCCs{ROWind,LEVind}{SCCind})
                        NormFact=(10^(sccGAIN*scc_logCHwidth)-1)*geomean(NSCC_BFskHz{ROWind,LEVind}{SCCind})/SCCsMAX;
                        semilogy(NSCC_delays_usec{ROWind,LEVind}{SCCind}/1000, ...
                           NSCCs{ROWind,LEVind}{SCCind}*NormFact+geomean(NSCC_BFskHz{ROWind,LEVind}{SCCind}), ...
                           'LineWidth',LINEwidth)
                        hold on
                        % Plot 0 and 1 lines
                        semilogy(XLIMITS_scc,zeros(1,2)*NormFact+geomean(NSCC_BFskHz{ROWind,LEVind}{SCCind}), ...
                           'k-','LineWidth',LINEwidth/2)
                        semilogy(XLIMITS_scc,ones(1,2)*NormFact+geomean(NSCC_BFskHz{ROWind,LEVind}{SCCind}), ...
                           'k-','LineWidth',LINEwidth/2)
                        % Plot values at 0 delay and CD
                        semilogy(0,NSCC_0delay{ROWind,LEVind}{SCCind}*NormFact+geomean(NSCC_BFskHz{ROWind,LEVind}{SCCind}), ...
                           'om')
                        semilogy(NSCC_CDs_usec{ROWind,LEVind}{SCCind}/1000,NSCC_peaks{ROWind,LEVind}{SCCind}*NormFact+geomean(NSCC_BFskHz{ROWind,LEVind}{SCCind}), ...
                           'or')
                        
                     end
                  end
                  xlabel('Delay (ms)')
                  ylabel('Effective Best Frequency (kHz)')
                  if ROWind==1
                     title(sprintf('     Exp%s, Units %s - %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n%s @ %.f dB SPL,   Harm: %d, Polarity: %d', ...
                        ExpDate,UnitNames{1},UnitNames{end},unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10,FeaturesText{FeatIND}, ...
                        yTEMP.levels_dBSPL(LEVind),HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
                  else
                     title(sprintf('%s @ %.f dB SPL,   Harm: %d, Polarity: %d',FeaturesText{FeatIND}, ...
                        yTEMP.levels_dBSPL(LEVind),HarmonicsIND,PolarityIND),'units','norm','pos',[.1 1 0],'HorizontalAlignment','left')
                  end
                  xlim(XLIMITS_scc)
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     %                      if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                     %                         semilogy(XLIMITS_perhist,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     %                         text(XLIMITS_perhist(2)*1.005,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000, ...
                     %                            sprintf('%s (%.1f)',FeaturesText{FeatINDPlot},yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000), ...
                     %                            'units','data','HorizontalAlignment','left','VerticalAlignment','middle','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     %                      end
                     for SCCind=1:length(NSCCs{ROWind,LEVind})
                        if ~isempty(NSCCs{ROWind,LEVind}{SCCind})
                           if (FeatINDPlot<=FeatIND)
                              if (FeatINDPlot>1)
                                 text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
                                    'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                              else
                                 text(1000/yTEMP.FeatureFreqs_Hz{1}(FeatINDPlot),YLIMITS(1),sprintf('1/%s',FeaturesText{FeatINDPlot}),'units','data', ...
                                    'HorizontalAlignment','center','VerticalAlignment','top','FontSize',6,'Color','k')
                              end
                           end
                        end
                     end
                  end
                  hold off
                  
                  
                  %%%% Rate Plot
                  PLOTnum=(ROWind-1)*NUMcols+2;   
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  semilogy(Rates{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
                  hold on
                  semilogy(Nsps{ROWind,LEVind}/10,BFs_kHz{ROWind,LEVind},'m+','MarkerSize',4)
                  semilogy(ALSRs{ROWind,LEVind},unit.Info.BF_kHz,'go','MarkerSize',6)
                  semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
                  xlabel(sprintf('Rate (sp/sec)\n[+: # of spikes/10]\nO: ALSR'))
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  xlim(XLIMITS_rate)
                  set(PLOThand,'XDir','reverse')
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_rate,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                  end
                  hold off
                  
                  %%%% Synch Plot
                  PLOTnum=(ROWind-1)*NUMcols+3;   
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  semilogy(Synchs{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
                  hold on
                  semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
                  xlabel(sprintf('Synch Coef (to %s)',FeaturesText{FeatIND}))
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  xlim(XLIMITS_synch)
                  set(PLOThand,'XDir','reverse')
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  set(gca,'XTick',[0 .25 .5 .75 1],'XTickLabel',{'0','.25','.5','.75','1'})
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_synch,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                  end
                  hold off
                  
                  %%%% Phase Plot
                  PLOTnum=(ROWind-1)*NUMcols+4;   
                  eval(['h' num2str(PLOTnum) '=subplot(NUMrows,NUMcols,PLOTnum);'])
                  semilogy(Phases{ROWind,LEVind},BFs_kHz{ROWind,LEVind},'*-')
                  hold on
                  semilogy([-1000 1000],unit.Info.BF_kHz*[1 1],'k:')
                  xlabel(sprintf('Phase (cycles of %s)',FeaturesText{FeatIND}))
                  PLOThand=eval(['h' num2str(PLOTnum)]);
                  xlim(XLIMITS_phase)
                  set(PLOThand,'XDir','reverse','XTick',[-pi -pi/2 0 pi/2 pi],'XTickLabel',[-1 -1/2 0 1/2 1])
                  set(PLOThand,'YTick',YTICKS,'YTickLabel',YTICKS)
                  ylim(YLIMITS)  % Same Ylimits for all plots
                  %%%%%%%%%%%%%%%%%%%%%
                  % Plot lines at all features
                  for FeatINDPlot=1:length(FeaturesText)
                     if (yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000>=YLIMITS(1))&(yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000<=YLIMITS(2))
                        semilogy(XLIMITS_phase,yTEMP.FeatureFreqs_Hz{LEVind}(FeatINDPlot)/1000*[1 1],':','Color',FeatureColors{-rem(FeatINDPlot,2)+2})
                     end
                  end
                  hold off
                  
               end %End if data for this condition, plot
            end % End Polarity
         end % End Harmonics
      end % End Feature
   end
   
   
   Xcorner=0.05;
   Xwidth1=.5;
   Xshift1=0.05;
   Xwidth2=.1;
   Xshift2=0.03;
   
   Ycorner=0.05;
   Yshift=0.07;
   Ywidth=(1-NUMrows*(Yshift+.01))/NUMrows;   %.26 for 3; .42 for 2
   
   TICKlength=0.02;
   
   if NUMrows>4
      set(h17,'Position',[Xcorner Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h18,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h19,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h20,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-5)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   if NUMrows>3
      set(h13,'Position',[Xcorner Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h14,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h15,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h16,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-4)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   if NUMrows>2
      set(h9,'Position',[Xcorner Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h10,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h11,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h12,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-3)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   if NUMrows>1
      set(h5,'Position',[Xcorner Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
      set(h6,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h7,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
      set(h8,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-2)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   end
   
   set(h1,'Position',[Xcorner Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth1 Ywidth],'TickLength',[TICKlength 0.025])
   set(h2,'Position',[Xcorner+Xwidth1+Xshift1 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   set(h3,'Position',[Xcorner+Xwidth1+Xshift1+Xwidth2+Xshift2 Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   set(h4,'Position',[Xcorner+Xwidth1+Xshift1+2*(Xwidth2+Xshift2) Ycorner+(NUMrows-1)*(Ywidth+Yshift) Xwidth2 Ywidth],'TickLength',[TICKlength 0.025])
   
   orient landscape
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DO SMP PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Plot data
LEVELcolors={'b','r','g','c','k','y'};
FEATmarkers={'.','x','s','^','*','<','^','>'};
FIG.FontSize=8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 9/24/04 TODO
% *1) SMP: Organize data for plots 2 and 3, and plot
%    *? WHY IS featureLevels all less than 0???  - OK, its F0 that has the peak, and is at 0 dB
% 9/25/04 TODO
% *2) Look at some units, to get basic feeling
%    *- getting warning for 80 dB SPL, when not present for Pol=---
%    *- look at a few examples to be sure we've got most of the bugs
%          - see UnitSMP notes for list of good units (TRY 080204, 1.29 for design of analyses)
%
% 3) Setup SAC/SCC computations, FIGURE OUT HOW TO
% 4) Try to show level-dependent cross-BF Corr and enhanced Spectral Coding from TreFF and EHrFF
%
% 5) Demo 2-neuron/same-stim simulation with PSTview and real data!, FIGURE OUT HOW TO
% 6) DESIGN general way to organize data with shifted SMPs and SCC to look at basic questions!!!
% 7) Look for enhanced spectral coding in individual units
%
% 8) FOR ARO:
%    - method for simulating 2 neurons, with same stimulus
%    - evidence for NL phase effects for vowels
%    - general increased cross-BF correlation with Level
%    - any evidence for enhance spectral coding based on X-BF correlation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1/31/05 TODO
% Need to clean up SMP plots,
% *1) plot fitted line (LEVcolor), label all features from same level with same color (LEVcolor)
% *2) Add legend for levels, and for feature-symbols
% *3) CLEAN UP ALL
% 4) START adding other SMP metrics to plot
%    - ALSR
%    - SCC (plots, then various choices - try to find decent one to illustrate, rather than all possibilities)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %%%%% Store data vs OAL, to help with plotting
% FeatureRatevsOAL=cell(1,length(FeaturesText));
% for FeatIND=FeatINDs
%    FeatureRatevsOAL{FeatIND}=NaN+ones(1,length(levels_dBSPL));
%    for LEVind=1:length(levels_dBSPL)
%       FeatureRatevsOAL{FeatIND}(LEVind)=SMP_rate{LEVind}(FeatIND);
%    end
% end

if isfield(unit,'EH_reFF')
   FIGnum=1;
   figure(FIGnum); clf
   set(gcf,'pos',[753     4   643   976])

   
   %%%%%%%%%%%%%%%%%%%%% CALCULATE SLOPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % Rate vs. Feature Level
   SensitivitySlopes_rate=NaN+ones(size(levels_dBSPL));
   SensitivityIntercepts_rate=NaN+ones(size(levels_dBSPL));
   for LEVind=1:length(levels_dBSPL)
      if sum(~isnan(SMP_rate{LEVind}))>1
         x=levels_dBSPL(LEVind)+FeatureLevels_dB(find(~isnan(SMP_rate{LEVind})));
         y=SMP_rate{LEVind}(find(~isnan(SMP_rate{LEVind})));
         [Cfit,MSE,fit]=fit1slope(x,y);
         SensitivitySlopes_rate(LEVind)=Cfit(1);
         SensitivityIntercepts_rate(LEVind)=Cfit(2);
      end
   end

   % ALSR vs. Feature Level
   SensitivitySlopes_alsr=NaN+ones(size(levels_dBSPL));
   SensitivityIntercepts_alsr=NaN+ones(size(levels_dBSPL));
   for LEVind=1:length(levels_dBSPL)
      if sum(~isnan(SMP_alsr{LEVind}))>1
         x=levels_dBSPL(LEVind)+FeatureLevels_dB(find(~isnan(SMP_alsr{LEVind})));
         y=SMP_alsr{LEVind}(find(~isnan(SMP_alsr{LEVind})));
         [Cfit,MSE,fit]=fit1slope(x,y);
         SensitivitySlopes_alsr(LEVind)=Cfit(1);
         SensitivityIntercepts_alsr(LEVind)=Cfit(2);
      end
   end

   % NSCC_CD(1) vs. Feature Level
   SensitivitySlopes_nsccCD{1}=NaN+ones(size(levels_dBSPL));
   SensitivityIntercepts_nsccCD{1}=NaN+ones(size(levels_dBSPL));
   for LEVind=1:length(levels_dBSPL)
      if sum(~isnan(SMP_NSCC_CD{1,LEVind}))>1
         x=levels_dBSPL(LEVind)+FeatureLevels_dB(find(~isnan(SMP_NSCC_CD{1,LEVind})));
         y=SMP_NSCC_CD{1,LEVind}(find(~isnan(SMP_NSCC_CD{1,LEVind})));
         [Cfit,MSE,fit]=fit1slope(x,y);
         SensitivitySlopes_nsccCD{1}(LEVind)=Cfit(1);
         SensitivityIntercepts_nsccCD{1}(LEVind)=Cfit(2);
      end
   end

   % NSCC_0delay(1) vs. Feature Level
   SensitivitySlopes_nscc0{1}=NaN+ones(size(levels_dBSPL));
   SensitivityIntercepts_nscc0{1}=NaN+ones(size(levels_dBSPL));
   for LEVind=1:length(levels_dBSPL)
      if sum(~isnan(SMP_NSCC_0delay{1,LEVind}))>1
         x=levels_dBSPL(LEVind)+FeatureLevels_dB(find(~isnan(SMP_NSCC_0delay{1,LEVind})));
         y=SMP_NSCC_0delay{1,LEVind}(find(~isnan(SMP_NSCC_0delay{1,LEVind})));
         [Cfit,MSE,fit]=fit1slope(x,y);
         SensitivitySlopes_nscc0{1}(LEVind)=Cfit(1);
         SensitivityIntercepts_nscc0{1}(LEVind)=Cfit(2);
      end
   end

   % NSCC_peak(1) vs. Feature Level
   SensitivitySlopes_nsccPEAK{1}=NaN+ones(size(levels_dBSPL));
   SensitivityIntercepts_nsccPEAK{1}=NaN+ones(size(levels_dBSPL));
   for LEVind=1:length(levels_dBSPL)
      if sum(~isnan(SMP_NSCC_peak{1,LEVind}))>1
         x=levels_dBSPL(LEVind)+FeatureLevels_dB(find(~isnan(SMP_NSCC_peak{1,LEVind})));
         y=SMP_NSCC_peak{1,LEVind}(find(~isnan(SMP_NSCC_peak{1,LEVind})));
         [Cfit,MSE,fit]=fit1slope(x,y);
         SensitivitySlopes_nsccPEAK{1}(LEVind)=Cfit(1);
         SensitivityIntercepts_nsccPEAK{1}(LEVind)=Cfit(2);
      end
   end

   % NSCC_CD(2) vs. Feature Level
   SensitivitySlopes_nsccCD{2}=NaN+ones(size(levels_dBSPL));
   SensitivityIntercepts_nsccCD{2}=NaN+ones(size(levels_dBSPL));
   for LEVind=1:length(levels_dBSPL)
      if sum(~isnan(SMP_NSCC_CD{2,LEVind}))>1
         x=levels_dBSPL(LEVind)+FeatureLevels_dB(find(~isnan(SMP_NSCC_CD{2,LEVind})));
         y=SMP_NSCC_CD{2,LEVind}(find(~isnan(SMP_NSCC_CD{2,LEVind})));
         [Cfit,MSE,fit]=fit1slope(x,y);
         SensitivitySlopes_nsccCD{2}(LEVind)=Cfit(1);
         SensitivityIntercepts_nsccCD{2}(LEVind)=Cfit(2);
      end
   end

   % NSCC_0delay(2) vs. Feature Level
   SensitivitySlopes_nscc0{2}=NaN+ones(size(levels_dBSPL));
   SensitivityIntercepts_nscc0{2}=NaN+ones(size(levels_dBSPL));
   for LEVind=1:length(levels_dBSPL)
      if sum(~isnan(SMP_NSCC_0delay{2,LEVind}))>1
         x=levels_dBSPL(LEVind)+FeatureLevels_dB(find(~isnan(SMP_NSCC_0delay{2,LEVind})));
         y=SMP_NSCC_0delay{2,LEVind}(find(~isnan(SMP_NSCC_0delay{2,LEVind})));
         [Cfit,MSE,fit]=fit1slope(x,y);
         SensitivitySlopes_nscc0{2}(LEVind)=Cfit(1);
         SensitivityIntercepts_nscc0{2}(LEVind)=Cfit(2);
      end
   end

   % NSCC_peak(2) vs. Feature Level
   SensitivitySlopes_nsccPEAK{2}=NaN+ones(size(levels_dBSPL));
   SensitivityIntercepts_nsccPEAK{2}=NaN+ones(size(levels_dBSPL));
   for LEVind=1:length(levels_dBSPL)
      if sum(~isnan(SMP_NSCC_peak{2,LEVind}))>1
         x=levels_dBSPL(LEVind)+FeatureLevels_dB(find(~isnan(SMP_NSCC_peak{2,LEVind})));
         y=SMP_NSCC_peak{2,LEVind}(find(~isnan(SMP_NSCC_peak{2,LEVind})));
         [Cfit,MSE,fit]=fit1slope(x,y);
         SensitivitySlopes_nsccPEAK{2}(LEVind)=Cfit(1);
         SensitivityIntercepts_nsccPEAK{2}(LEVind)=Cfit(2);
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%% Rate-FeatureLevels for each OAL
   subplot(421)
   LEGtext='';
   for LEVind=1:length(levels_dBSPL)
      %% Plot fitted lines
      if ~isnan(SensitivitySlopes_rate(LEVind))
         xdata=[min(FeatureLevels_dB(find(~isnan(SMP_rate{LEVind})))+levels_dBSPL(LEVind)) max(FeatureLevels_dB(find(~isnan(SMP_rate{LEVind})))+levels_dBSPL(LEVind))];
         ydata=SensitivitySlopes_rate(LEVind)*xdata+SensitivityIntercepts_rate(LEVind);
         plot(xdata,ydata,'Marker','none','Color',LEVELcolors{LEVind},'LineStyle','-')
         hold on
         LEGtext{length(LEGtext)+1}=sprintf('%.f dB SPL (%.2f sp/sec/dB)',levels_dBSPL(LEVind),SensitivitySlopes_rate(LEVind));
      end
   end
   for LEVind=1:length(levels_dBSPL)
      for FeatIND=FeatINDs
         if ~isnan(SMP_rate{LEVind}(FeatIND))
            plot(levels_dBSPL(LEVind)+FeatureLevels_dB(FeatIND),SMP_rate{LEVind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',LEVELcolors{LEVind},'LineStyle','none')
            hold on
         end
      end
   end
   YLIMITS_SMPrate=[0 300];
   XLIMITS_SMPrate=[0 100];
   ylim(YLIMITS_SMPrate)  % Fixed ordinate for all plots
   xlim(XLIMITS_SMPrate)
   %%%%%%%%%%%%%%%%%%%%%
   % Home-made Feature Symbol Legend
   %%%%%%%%%%%%%%%%%%%%%
   LEGXleft=.05; LEGYtop=0.85; LEGYstep=0.03; LEGXsymbOFFset=0.05;
   FeatNum=0;
   for FeatIND=FeatINDs
      FeatNum=FeatNum+1;
      plot(XLIMITS_SMPrate(1)+diff(XLIMITS_SMPrate)*(LEGXleft),YLIMITS_SMPrate(1)+diff(YLIMITS_SMPrate)*(LEGYtop-(FeatNum-1)*LEGYstep),FEATmarkers{FeatIND}, ...
         'Color','k','MarkerSize',6)
      text(LEGXleft+LEGXsymbOFFset,LEGYtop-(FeatNum-1)*LEGYstep,FeaturesText{FeatIND},'Units','norm','FontSize',10)
   end
   ylabel('Rate (sp/sec)')
   xlabel('Feature Level (dB SPL)')
   hleg=legend(LEGtext,1);
   set(hleg,'FontSize',8)
   hold off
   set(gca,'FontSize',FIG.FontSize)
   title(sprintf('     Exp%s, Units %s - %s: BF=%.2f kHz, Thr=%.f dB SPL, SR=%.1f sps, Q10=%.1f\n', ...
      ExpDate,UnitNames{1},UnitNames{end},unit.Info.BF_kHz,unit.Info.Threshold_dBSPL,unit.Info.SR_sps,unit.Info.Q10), ...
      'units','norm')
   

   %%%% ALSR-FeatureLevels for each OAL
   subplot(422)
   LEGtext='';
   for LEVind=1:length(levels_dBSPL)
      %% Plot fitted lines
      if ~isnan(SensitivitySlopes_alsr(LEVind))
         xdata=[min(FeatureLevels_dB(find(~isnan(SMP_alsr{LEVind})))+levels_dBSPL(LEVind)) max(FeatureLevels_dB(find(~isnan(SMP_alsr{LEVind})))+levels_dBSPL(LEVind))];
         ydata=SensitivitySlopes_alsr(LEVind)*xdata+SensitivityIntercepts_alsr(LEVind);
         plot(xdata,ydata,'Marker','none','Color',LEVELcolors{LEVind},'LineStyle','-')
         hold on
         LEGtext{length(LEGtext)+1}=sprintf('%.f dB SPL (%.2f sp/sec/dB)',levels_dBSPL(LEVind),SensitivitySlopes_alsr(LEVind));
      end
   end
   for LEVind=1:length(levels_dBSPL)
      for FeatIND=FeatINDs
         if ~isnan(SMP_alsr{LEVind}(FeatIND))
            plot(levels_dBSPL(LEVind)+FeatureLevels_dB(FeatIND),SMP_alsr{LEVind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',LEVELcolors{LEVind},'LineStyle','none')
            hold on
         end
      end
   end
   YLIMITS_SMPalsr=[0 300];
   XLIMITS_SMPalsr=XLIMITS_SMPrate;
   ylim(YLIMITS_SMPalsr)  % Fixed ordinate for all plots
   xlim(XLIMITS_SMPalsr)
   ylabel('ALSR (sp/sec)')
   xlabel('Feature Level (dB SPL)')
   hleg=legend(LEGtext,1);
   set(hleg,'FontSize',8)
   hold off
   set(gca,'FontSize',FIG.FontSize)
   
   %%%% NSCC_0delay-FeatureLevels for each OAL
   subplot(423)
   LEGtext='';
   for LEVind=1:length(levels_dBSPL)
      %% Plot fitted lines
      if ~isnan(SensitivitySlopes_nscc0{1}(LEVind))
         xdata=[min(FeatureLevels_dB(find(~isnan(SMP_NSCC_0delay{1,LEVind})))+levels_dBSPL(LEVind)) max(FeatureLevels_dB(find(~isnan(SMP_NSCC_0delay{1,LEVind})))+levels_dBSPL(LEVind))];
         ydata=SensitivitySlopes_nscc0{1}(LEVind)*xdata+SensitivityIntercepts_nscc0{1}(LEVind);
         plot(xdata,ydata,'Marker','none','Color',LEVELcolors{LEVind},'LineStyle','-')
         hold on
         LEGtext{length(LEGtext)+1}=sprintf('%.f dB SPL (%.2f 1/dB)',levels_dBSPL(LEVind),SensitivitySlopes_nscc0{1}(LEVind));
      end
   end
   for LEVind=1:length(levels_dBSPL)
      for FeatIND=FeatINDs
         if ~isnan(SMP_NSCC_0delay{1,LEVind}(FeatIND))
            plot(levels_dBSPL(LEVind)+FeatureLevels_dB(FeatIND),SMP_NSCC_0delay{1,LEVind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',LEVELcolors{LEVind},'LineStyle','none')
            hold on
         end
      end
   end
   YLIMITS_SMPnscc0=[0 5];
   XLIMITS_SMPnscc0=XLIMITS_SMPrate;
   ylim(YLIMITS_SMPnscc0)  % Fixed ordinate for all plots
   xlim(XLIMITS_SMPnscc0)
   ylabel('NSCC (at 0 delay)')
   title(sprintf('NSCC1: BF re BF+%.2f octaves',SCC_octOFFSET),'color','red')
   xlabel('Feature Level (dB SPL)')
   hleg=legend(LEGtext,1);
   set(hleg,'FontSize',8)
   hold off
   set(gca,'FontSize',FIG.FontSize)
   
   %%%% NSCC_0delay-FeatureLevels for each OAL
   subplot(424)
   LEGtext='';
   for LEVind=1:length(levels_dBSPL)
      %% Plot fitted lines
      if ~isnan(SensitivitySlopes_nscc0{2}(LEVind))
         xdata=[min(FeatureLevels_dB(find(~isnan(SMP_NSCC_0delay{2,LEVind})))+levels_dBSPL(LEVind)) max(FeatureLevels_dB(find(~isnan(SMP_NSCC_0delay{2,LEVind})))+levels_dBSPL(LEVind))];
         ydata=SensitivitySlopes_nscc0{2}(LEVind)*xdata+SensitivityIntercepts_nscc0{2}(LEVind);
         plot(xdata,ydata,'Marker','none','Color',LEVELcolors{LEVind},'LineStyle','-')
         hold on
         LEGtext{length(LEGtext)+1}=sprintf('%.f dB SPL (%.2f 1/dB)',levels_dBSPL(LEVind),SensitivitySlopes_nscc0{2}(LEVind));
      end
   end
   for LEVind=1:length(levels_dBSPL)
      for FeatIND=FeatINDs
         if ~isnan(SMP_NSCC_0delay{2,LEVind}(FeatIND))
            plot(levels_dBSPL(LEVind)+FeatureLevels_dB(FeatIND),SMP_NSCC_0delay{2,LEVind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',LEVELcolors{LEVind},'LineStyle','none')
            hold on
         end
      end
   end
   YLIMITS_SMPnscc0=[0 5];
   XLIMITS_SMPnscc0=XLIMITS_SMPrate;
   ylim(YLIMITS_SMPnscc0)  % Fixed ordinate for all plots
   xlim(XLIMITS_SMPnscc0)
   ylabel('NSCC (at 0 delay)')
   title(sprintf('NSCC2: BF re BF-%.2f octaves',SCC_octOFFSET),'color','red')
   xlabel('Feature Level (dB SPL)')
   hleg=legend(LEGtext,1);
   set(hleg,'FontSize',8)
   hold off
   set(gca,'FontSize',FIG.FontSize)
   
   %%%% NSCC_peak-FeatureLevels for each OAL
   subplot(425)
   LEGtext='';
   for LEVind=1:length(levels_dBSPL)
      %% Plot fitted lines
      if ~isnan(SensitivitySlopes_nsccPEAK{1}(LEVind))
         xdata=[min(FeatureLevels_dB(find(~isnan(SMP_NSCC_peak{1,LEVind})))+levels_dBSPL(LEVind)) max(FeatureLevels_dB(find(~isnan(SMP_NSCC_peak{1,LEVind})))+levels_dBSPL(LEVind))];
         ydata=SensitivitySlopes_nsccPEAK{1}(LEVind)*xdata+SensitivityIntercepts_nsccPEAK{1}(LEVind);
         plot(xdata,ydata,'Marker','none','Color',LEVELcolors{LEVind},'LineStyle','-')
         hold on
         LEGtext{length(LEGtext)+1}=sprintf('%.f dB SPL (%.2f 1/dB)',levels_dBSPL(LEVind),SensitivitySlopes_nsccPEAK{1}(LEVind));
      end
   end
   for LEVind=1:length(levels_dBSPL)
      for FeatIND=FeatINDs
         if ~isnan(SMP_NSCC_peak{1,LEVind}(FeatIND))
            plot(levels_dBSPL(LEVind)+FeatureLevels_dB(FeatIND),SMP_NSCC_peak{1,LEVind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',LEVELcolors{LEVind},'LineStyle','none')
            hold on
         end
      end
   end
   YLIMITS_SMPnsccPEAK=[0 5];
   XLIMITS_SMPnsccPEAK=XLIMITS_SMPrate;
   ylim(YLIMITS_SMPnsccPEAK)  % Fixed ordinate for all plots
   xlim(XLIMITS_SMPnsccPEAK)
   ylabel('Peak NSCC (at CD)')
   xlabel('Feature Level (dB SPL)')
   hleg=legend(LEGtext,1);
   set(hleg,'FontSize',8)
   hold off
   set(gca,'FontSize',FIG.FontSize)
   
   %%%% NSCC_peak-FeatureLevels for each OAL
   subplot(426)
   LEGtext='';
   for LEVind=1:length(levels_dBSPL)
      %% Plot fitted lines
      if ~isnan(SensitivitySlopes_nsccPEAK{2}(LEVind))
         xdata=[min(FeatureLevels_dB(find(~isnan(SMP_NSCC_peak{2,LEVind})))+levels_dBSPL(LEVind)) max(FeatureLevels_dB(find(~isnan(SMP_NSCC_peak{2,LEVind})))+levels_dBSPL(LEVind))];
         ydata=SensitivitySlopes_nsccPEAK{2}(LEVind)*xdata+SensitivityIntercepts_nsccPEAK{2}(LEVind);
         plot(xdata,ydata,'Marker','none','Color',LEVELcolors{LEVind},'LineStyle','-')
         hold on
         LEGtext{length(LEGtext)+1}=sprintf('%.f dB SPL (%.2f 1/dB)',levels_dBSPL(LEVind),SensitivitySlopes_nsccPEAK{2}(LEVind));
      end
   end
   for LEVind=1:length(levels_dBSPL)
      for FeatIND=FeatINDs
         if ~isnan(SMP_NSCC_peak{2,LEVind}(FeatIND))
            plot(levels_dBSPL(LEVind)+FeatureLevels_dB(FeatIND),SMP_NSCC_peak{2,LEVind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',LEVELcolors{LEVind},'LineStyle','none')
            hold on
         end
      end
   end
   YLIMITS_SMPnsccPEAK=[0 5];
   XLIMITS_SMPnsccPEAK=XLIMITS_SMPrate;
   ylim(YLIMITS_SMPnsccPEAK)  % Fixed ordinate for all plots
   xlim(XLIMITS_SMPnsccPEAK)
   ylabel('Peak NSCC (at CD)')
   xlabel('Feature Level (dB SPL)')
   hleg=legend(LEGtext,1);
   set(hleg,'FontSize',8)
   hold off
   set(gca,'FontSize',FIG.FontSize)
   
   %%%% NSCC_CD-FeatureLevels for each OAL
   subplot(427)
   LEGtext='';
   for LEVind=1:length(levels_dBSPL)
      %% Plot fitted lines
      if ~isnan(SensitivitySlopes_nsccCD{1}(LEVind))
         xdata=[min(FeatureLevels_dB(find(~isnan(SMP_NSCC_CD{1,LEVind})))+levels_dBSPL(LEVind)) max(FeatureLevels_dB(find(~isnan(SMP_NSCC_CD{1,LEVind})))+levels_dBSPL(LEVind))];
         ydata=SensitivitySlopes_nsccCD{1}(LEVind)*xdata+SensitivityIntercepts_nsccCD{1}(LEVind);
         plot(xdata,ydata,'Marker','none','Color',LEVELcolors{LEVind},'LineStyle','-')
         hold on
         LEGtext{length(LEGtext)+1}=sprintf('%.f dB SPL (%.2f usec/dB)',levels_dBSPL(LEVind),SensitivitySlopes_nsccCD{1}(LEVind));
      end
   end
   for LEVind=1:length(levels_dBSPL)
      for FeatIND=FeatINDs
         if ~isnan(SMP_NSCC_CD{1,LEVind}(FeatIND))
            plot(levels_dBSPL(LEVind)+FeatureLevels_dB(FeatIND),SMP_NSCC_CD{1,LEVind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',LEVELcolors{LEVind},'LineStyle','none')
            hold on
         end
      end
   end
   YLIMITS_SMPnsccCD=10000*[-1 1];
   XLIMITS_SMPnsccCD=XLIMITS_SMPrate;
   ylim(YLIMITS_SMPnsccCD)  % Fixed ordinate for all plots
   xlim(XLIMITS_SMPnsccCD)
   ylabel('Characteristic Dealy of NSCC (usec)')
   xlabel('Feature Level (dB SPL)')
   %    hleg=legend(LEGtext,1);
   %    set(hleg,'FontSize',8)
   hold off
   set(gca,'FontSize',FIG.FontSize)
   
   %%%% NSCC_CD-FeatureLevels for each OAL
   subplot(428)
   LEGtext='';
   for LEVind=1:length(levels_dBSPL)
      %% Plot fitted lines
      if ~isnan(SensitivitySlopes_nsccCD{2}(LEVind))
         xdata=[min(FeatureLevels_dB(find(~isnan(SMP_NSCC_CD{2,LEVind})))+levels_dBSPL(LEVind)) max(FeatureLevels_dB(find(~isnan(SMP_NSCC_CD{2,LEVind})))+levels_dBSPL(LEVind))];
         ydata=SensitivitySlopes_nsccCD{2}(LEVind)*xdata+SensitivityIntercepts_nsccCD{2}(LEVind);
         plot(xdata,ydata,'Marker','none','Color',LEVELcolors{LEVind},'LineStyle','-')
         hold on
         LEGtext{length(LEGtext)+1}=sprintf('%.f dB SPL (%.2f usec/dB)',levels_dBSPL(LEVind),SensitivitySlopes_nsccCD{2}(LEVind));
      end
   end
   for LEVind=1:length(levels_dBSPL)
      for FeatIND=FeatINDs
         if ~isnan(SMP_NSCC_CD{2,LEVind}(FeatIND))
            plot(levels_dBSPL(LEVind)+FeatureLevels_dB(FeatIND),SMP_NSCC_CD{2,LEVind}(FeatIND),'Marker',FEATmarkers{FeatIND},'Color',LEVELcolors{LEVind},'LineStyle','none')
            hold on
         end
      end
   end
   YLIMITS_SMPnsccCD=10000*[-1 1];
   XLIMITS_SMPnsccCD=XLIMITS_SMPrate;
   ylim(YLIMITS_SMPnsccCD)  % Fixed ordinate for all plots
   xlim(XLIMITS_SMPnsccCD)
   ylabel('Characteristic Dealy of NSCC (usec)')
   xlabel('Feature Level (dB SPL)')
   %    hleg=legend(LEGtext,1);
   %    set(hleg,'FontSize',8)
   hold off
   set(gca,'FontSize',FIG.FontSize)
   
end %End if data for this condition, plot


orient tall



% Turn off saved PICS feature
SavedPICS=[]; SavedPICnums=[];
SavedPICSuse=0;

% For ARO2005: ANmodel figure
% save REAL_ANmodelST

return;
