function STMPconvert_STs_Nchans1stim(ExpDate,UnitName,STIMtype)
% FROM: STMPsave_STs_1unitNstim_EHrBFi.m AND simFF_PICshift
% M. Heinz Jun 08, 2007
% Converts data from 1 unit for STMP analysis (for which data collected was
% from 1 unit and multiple stimuli - typically varied sampling rates) into
% Predicted Population of responses to one stimulus.
%
% Setup to be general, for all STIMtypes
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global STMP_dir STMP_ExpList

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Verify parameters and experiment, unit are valid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TESTunitNUM=1;  % 1: ARO (111804, 1.28), 2: ISH (041805, 2.04), 3: Purdue1 (111606, 2.09); 4: Purdue2 (041306, 1.03), 
%%%% Specify ExpDate if not provided
if ~exist('ExpDate','var')
   if TESTunitNUM==1
      ExpDate='111804'; UnitName='1.28'; STIMtype='EHrBFi';
   elseif TESTunitNUM==2
      ExpDate='041805'; UnitName='2.04';
   elseif TESTunitNUM==3
      ExpDate='111606'; UnitName='2.09';
   elseif TESTunitNUM==4
      ExpDate='041307'; UnitName='1.03';
   end            
end

%%%% Find the full Experiment Name 
ExpDateText=strcat('20',ExpDate(end-1:end),'_',ExpDate(1:2),'_',ExpDate(3:4));
for i=1:length(STMP_ExpList)
   if ~isempty(strfind(STMP_ExpList{i},ExpDateText))
      ExpName=STMP_ExpList{i};
      break;
   end
end
if ~exist('ExpName','var')
   disp(sprintf('***ERROR***:  Experiment: %s not found\n   Experiment List:',ExpDate))
   disp(strvcat(STMP_ExpList))
   beep
   error('STOPPED');
end

%%%% Parse out the Track and Unit Number 
TrackNum=str2num(UnitName(1:strfind(UnitName,'.')-1));
UnitNum=str2num(UnitName(strfind(UnitName,'.')+1:end));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Setup related directories
RAWdata_dir=fullfile(STMP_dir,'ExpData',ExpName);
eval(['cd ''' RAWdata_dir ''''])
UNITinfo_dir=fullfile(STMP_dir,'ExpData',ExpName,'UNITinfo');   % For general unit info (BF, SR, bad lines, ...)
STMPanal_dir=fullfile(STMP_dir,'ExpData',ExpName,'STMPanalyses');   % For STMP analyses (Spike Trains, PSTs, PerHist, DFTs, SAC/SCCs, ...)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Verify unitINFO and STs_1unitNstim exists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
unitINFO_filename=sprintf('unitINFO.%d.%02d.mat',TrackNum,UnitNum);
eval(['ddd=dir(''' fullfile(UNITinfo_dir,unitINFO_filename) ''');'])
if isempty(ddd)
   error(sprintf('%s NOT FOUND - run STMPsave_UnitINFO function ',unitINFO_filename))
end
eval(['load ''' fullfile(UNITinfo_dir,unitINFO_filename) ''''])
STs_1unitNstim_filename=sprintf('STs_1unitNstim.%d.%02d.%s.mat',TrackNum,UnitNum,STIMtype);
eval(['ddd=dir(''' fullfile(STMPanal_dir,STs_1unitNstim_filename) ''');'])
if isempty(ddd)
   error(sprintf('%s NOT FOUND - run STMPsave_STs_1unitNstim_[...] function ',STs_1unitNstim_filename))
end
eval(['load ''' fullfile(STMPanal_dir,STs_1unitNstim_filename) ''''])

disp(sprintf('\n... STMP: Converting ORIGINAL %s SpikeTrains to STMP SpikeTrains \n      for:  Experiment: ''%s''; Unit: %d.%02d',STIMtype,ExpName,TrackNum,UnitNum))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% See if STs_Nchans1stim exists already
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
STs_Nchans1stim_filename=sprintf('STs_Nchans1stim.%d.%02d.%s.mat',TrackNum,UnitNum,STIMtype);
eval(['ddd=dir(''' fullfile(STMPanal_dir,STs_Nchans1stim_filename) ''');'])
if ~isempty(ddd)
   beep
   TEMP = input(sprintf('File: ''%s'' already exists!!\n  ***** Do you want to re-run STs_Nchans1stim, or leave it as is?  [0]: LEAVE AS IS; RERUN: 1;  ',STs_Nchans1stim_filename));
   if isempty(TEMP)
      TEMP=0;
   end
   if TEMP~=1
      beep
      disp(sprintf(' FILE NOT ALTERED\n'));
      return;
   else
      disp(' ... Re-Running STs_Nchans1stim - SAVING NEW FILE!');
   end   
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setup STs_Nchans1stim data structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
STs_Nchans1stim=STs_1unitNstim;
%              Info: [1x1 struct]             % UNCHANGED
STs_Nchans1stim.Info.STMPshift=1;
%          STIMtype: 'EHrBFi'                 % UNCHANGED
%       ChannelInfo: [1x1 struct]             % CONVERTED
%     ParameterInfo: [1x1 struct]             % UNCHANGED
%     ConditionInfo: [1x1 struct]             % UNCHANGED
%          StimInfo: [1x1 struct]             % CONVERTED
%       SpikeTrains: {2x1 cell}               % CONVERTED
% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Get general parameters for this unit, e.g., all BFs, levels, ...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~strcmp(STs_1unitNstim.ChannelInfo.channel_parameter,'Octave Shift')
   error('channel parameter needs to be ''Octave Shift''')
end
NumCH=size(STs_1unitNstim.SpikeTrains{1,1,1},1);
NumP=size(STs_1unitNstim.SpikeTrains{1,1,1},2);
NumFEATURES=size(STs_1unitNstim.SpikeTrains,1);
NumPOL=size(STs_1unitNstim.SpikeTrains,2);
NumHARMS=size(STs_1unitNstim.SpikeTrains,3);

STs_Nchans1stim.ChannelInfo.channel_values=cell(NumFEATURES,NumPOL,NumHARMS);
STs_Nchans1stim.ChannelInfo.Octave_Shifts=cell(NumFEATURES,NumPOL,NumHARMS);
STs_Nchans1stim.ChannelInfo.NeuralDelay_sec=cell(NumFEATURES,NumPOL,NumHARMS);
STs_Nchans1stim.ChannelInfo.FreqFact=cell(NumFEATURES,NumPOL,NumHARMS);
STs_Nchans1stim.ChannelInfo.StimDur_msec=cell(NumFEATURES,NumPOL,NumHARMS);
STs_Nchans1stim.ChannelInfo.LineDur_msec=cell(NumFEATURES,NumPOL,NumHARMS);
for FeatIND=1:NumFEATURES
   for PolIND=1:NumPOL
      for HarmIND=1:NumHARMS
         STs_Nchans1stim.ChannelInfo.Octave_Shifts{FeatIND,PolIND,HarmIND}= ...
            -STs_1unitNstim.ChannelInfo.channel_values{FeatIND,PolIND,HarmIND};  % store these for rerence
         for ChanIND=1:NumCH
            for ParamIND=1:NumP

               ORIGunit_BF_Hz=STs_1unitNstim.Info.BF_kHz*1000;
               ORIGstim_FeatureTarget_Hz=STs_1unitNstim.ChannelInfo.channel_FeatureTarget_Hz{FeatIND,PolIND,HarmIND}(ChanIND);
               ORIG_SpikeTrains=STs_1unitNstim.SpikeTrains{FeatIND,PolIND,HarmIND}{ChanIND,ParamIND};            

               [STMPunit_BF_Hz,STMPstim_FeatureTarget_Hz,STMP_SpikeTrains,NeuralDelay_sec,FreqFact] = ...
                  STMP_spikeconversion(ORIGunit_BF_Hz,ORIGstim_FeatureTarget_Hz,ORIG_SpikeTrains);

               %%%% Shift all frequency parameters by x(BF/FeatureFreq)
               STs_Nchans1stim.ChannelInfo.channel_parameter='Effective BF (kHz)';
               STs_Nchans1stim.ChannelInfo.channel_values{FeatIND,PolIND,HarmIND}(ChanIND)=STMPunit_BF_Hz/1000;
               STs_Nchans1stim.ChannelInfo.channel_F0_Hz{FeatIND,PolIND,HarmIND}(ChanIND)=STs_1unitNstim.ChannelInfo.channel_F0_Hz{FeatIND,PolIND,HarmIND}(ChanIND)*FreqFact;
               STs_Nchans1stim.ChannelInfo.channel_SamplingRate_Hz{FeatIND,PolIND,HarmIND}(ChanIND)=...
                  STs_1unitNstim.ChannelInfo.channel_SamplingRate_Hz{FeatIND,PolIND,HarmIND}(ChanIND)*FreqFact;
               STs_Nchans1stim.ChannelInfo.channel_FeatureTarget_Hz{FeatIND,PolIND,HarmIND}(ChanIND)=STMPstim_FeatureTarget_Hz;
               STs_Nchans1stim.ChannelInfo.channel_FeatureFreqs_Hz{FeatIND,PolIND,HarmIND}{ChanIND}=...
                  STs_1unitNstim.ChannelInfo.channel_FeatureFreqs_Hz{FeatIND,PolIND,HarmIND}{ChanIND}*FreqFact;
               STs_Nchans1stim.SpikeTrains{FeatIND,PolIND,HarmIND}{ChanIND,ParamIND}=STMP_SpikeTrains;
               STs_Nchans1stim.ChannelInfo.NeuralDelay_sec{FeatIND,PolIND,HarmIND}(ChanIND)=NeuralDelay_sec;
               STs_Nchans1stim.ChannelInfo.FreqFact{FeatIND,PolIND,HarmIND}(ChanIND)=FreqFact;
               
               %%%% Shift all time parameters by x(FeatureFreq/BF) (1/FreqFact)
               STs_Nchans1stim.ChannelInfo.StimDur_msec{FeatIND,PolIND,HarmIND}(ChanIND)=STs_1unitNstim.StimInfo.StimDur_msec/FreqFact;
               STs_Nchans1stim.ChannelInfo.LineDur_msec{FeatIND,PolIND,HarmIND}(ChanIND)=STs_1unitNstim.StimInfo.LineDur_msec/FreqFact;

            end  % end Param
         end  % end Freq
      end % End FormsatHarms
   end % End Invert Polarity
end % End: FeatIND

%% SAVE SpikeTrains
disp(['   *** Saving new file: "' STs_Nchans1stim_filename '" ...'])
eval(['save ''' fullfile(STMPanal_dir,STs_Nchans1stim_filename) ''' STs_Nchans1stim'])

return;
