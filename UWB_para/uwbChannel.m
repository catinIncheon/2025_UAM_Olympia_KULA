classdef uwbChannel < comm.internal.RandomStreamSeed
%UWBCHANNEL Filter input signal through a UWB IEEE 802.15.4a/z/ab channel
%   CHAN = uwbChannel creates a multipath UWB fading channel object, CHAN,
%   as specified by the IEEE 802.15.4a channel modeling subgroup [1]. The
%   channel model is clusterized and applies for both the 100-1000 MHz and
%   the 2-10 GHz frequency range. This object filters a real or complex
%   input signal through the multipath, UWB channel to obtain the channel
%   impaired signal.
%
%   CHAN = uwbChannel(Name,Value) creates a multipath UWB fading channel
%   object, CHAN, with the specified property Name set to the specified
%   Value. You can specify additional name-value pair arguments in any
%   order as (Name1,Value1,...,NameN,ValueN).
%
%   CHAN = uwbChannel(TYPE,LOS,Name,Value) creates a UWB multipath fading
%   channel System object, CHAN, with the Environment property set to TYPE,
%   the HasLOS property set to LOS and other specified property Names set
%   to the specified Values.
%  
%   Step method syntax:
% 
%   Y = step(CHAN,X) filters input signal X through a multipath Nakagami
%   fading channel and returns the result in Y. Both the input X and
%   the output Y are of size Ns-by-1, where Ns is the number of samples. X
%   can be real-valued or complex-valued. Y is complex-valued and of the
%   same data type as X.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   uwbChannel methods:
%
%   step     - Filter input signal through a UWB fading channel (see above)
%   release  - Allow property value and input characteristics changes
%   clone    - Create UWB channel object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset states of filters, and random stream if the
%              RandomStream property is set to "mt19937ar with seed"
%   <a href="matlab:help uwbChannel/infoImpl   ">info</a>     - Return characteristic information about the UWB channel
%
%   uwbChannel properties:
%
%   Environment           - Environment type ('Residential', 'Indoor office', 'Outdoor', 'Open outdoor', 'Industrial')
%   HasLOS                - Presence of line-of-sight component (logical)
%   MinRelativePathPower  - Minimum power of paths in cluster, relative to cluster's 1st path (%)
%   NormalizePathGains    - Normalize path gains (logical)
%   Visualization         - Option to visualize channel impulse response
%   ChannelNumber         - UWB channel number (0, 1, 2, ... 15)
%   Distance              - Distance between transmitter and receiver (m)
%   MaxDopplerShift       - Maximum Doppler shift (Hz)
%   SampleDensity         - Number of time samples per half wavelength 
%   SampleRate            - Input signal sample rate (Hz)
%   RandomStream          - Source of random number stream
%   Seed                  - Initial seed of mt19937ar random number stream
%
%   % Example 1:
%   %   Pass a 15.4z HPRF signal through an outdoor multi-path UWB channel
%   psdu = randi([0, 1], 300, 1);
%   waveTx = lrwpanWaveformGenerator(psdu, lrwpanHRPConfig);
% 
%   outdoorUWBChannel = uwbChannel('Outdoor', HasLOS=false, Visualization='Impulse response');
%   waveRx = outdoorUWBChannel(waveTx);
%
%   % Example 2:
%   %   Pass a 15.4z HPRF signal through an industrial (single-cluster, continuous) multi-path UWB channel
%   psdu = randi([0, 1], 300, 1);
%   waveTx = lrwpanWaveformGenerator(psdu, lrwpanHRPConfig);
% 
%   industrialUWBChannel = uwbChannel('Industrial', HasLOS=false, Visualization='Impulse response');
%   waveRx = industrialUWBChannel(waveTx);
%
%   % Example 3:
%   %   Equalize an IEEE 802.15.4z signal passed through a UWB multi-path channel
%   origState = rng(17);
%   msg = randi([0 1], 1000, 1);
%   cfgHPRF = lrwpanHRPConfig(Mode='HPRF',PSDULength=length(msg));
%   [waveHPRF, symbolsHPRF] = lrwpanWaveformGenerator(msg,cfgHPRF);
%   s = info(cfgHPRF);
%   singlePreambleLen = s.PreambleSpreadingFactor * s.PreambleCodeLength * cfgHPRF.SamplesPerPulse;
%   preambleDownSampled = waveHPRF(1: cfgHPRF.SamplesPerPulse: singlePreambleLen*cfgHPRF.PreambleDuration);
% 
%   % Multipath UWB channel
%   los = true;
%   chanUWB = uwbChannel('Residential', los, SampleRate=cfgHPRF.SampleRate, ...
%       SampleDensity=64, Visualization="Impulse response");
%   mpathHPRF = chanUWB(waveHPRF);
%   f = scatterplot(mpathHPRF); f.Name = 'Multipath signal';
% 
%   % Equalization
%   constelScale = max(abs(preambleDownSampled));
%   mpathHPRF = mpathHPRF * constelScale * 1/max(abs(mpathHPRF)); % AGC before equalization
%   lmsEq = comm.LinearEqualizer(Algorithm="LMS", Constellation=[-1 0 1]*constelScale, ...
%        InputSamplesPerSymbol=cfgHPRF.SamplesPerPulse, NumTaps=200, ReferenceTap=40, StepSize = 0.1);
%   eqLatency = info(lmsEq).Latency; % in symbols
%   [eqHPRF, errLMS, w] = lmsEq([mpathHPRF; zeros(eqLatency*cfgHPRF.SamplesPerPulse, 1)], preambleDownSampled); 
%   f = scatterplot(eqHPRF(cfgHPRF.PreambleDuration*singlePreambleLen+4:end)); f.Name = 'Equalized';
%   rng(origState);   % restore state of global stream
%
%   References: 
%   [1] - A. F. Molisch et al., "IEEE 802.15.4a Channel Model-Final
%   Report," Tech. Rep., Document IEEE 802.1504-0062-02-004a, 2005
%
%   See also lrwpanWaveformGenerator, lrwpanHRPConfig.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

  properties (Nontunable)
    %Environment Environment type
    % Specify Environment as one of 'Residential' | 'Indoor office' | 'Outdoor' |
    % 'Open outdoor' | 'Industrial'. This property determines parameters
    % as well as the mode of operation for the UWB Channel. The default
    % value is 'Residential'.
    Environment (1,:) char {mustBeMember(Environment,{'Residential', 'Indoor office', 'Outdoor', 'Open outdoor', 'Industrial'})} = 'Residential'

    %HasLOS Flag indicating presence of line-of-sight component
    % Specify HasLOS as a scalar logical. This flag indicates the presence of
    % a line-of-sight component between the transmitter and the receiver.
    % The default value is true.
    HasLOS (1,1) logical = true;

    %ChannelNumber Channel number
    % Specify ChannelNumber as one of [0:15]. This property determines the
    % channel bandwidth and center frequency. The default is 0.
    ChannelNumber (1, 1) {mustBeA(ChannelNumber, {'double', 'single'}), mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(ChannelNumber, 15)} = 0

    % MinRelativePathPower Minimum power of paths in cluster, relative to cluster's 1st path (%)
    %   Specify MinRelativePathPower as a real scalar in (0 100]. This
    %   value determines the minimum average power threshold for a path to be
    %   included in a cluster, as a percentage of the average power for the
    %   first path in that cluster. The default is 5 (%).
    MinRelativePathPower (1, 1) {mustBeA(MinRelativePathPower, {'double', 'single'}), mustBePositive, mustBeLessThanOrEqual(MinRelativePathPower, 100)} = 5

    %NormalizePathGains Normalize average path gains to 0 dB
    %   Set this property to true to normalize the fading processes such
    %   that the total power of the path gains, averaged over time, is 0 dB.
    %   The default value of this property is true.
    NormalizePathGains (1, 1) logical = true;
    
    %SampleRate Sample rate (Hz)
    %   Specify the sample rate of the input signal in Hz as a double
    %   precision, real, positive scalar. The default value of this
    %   property is 499.2 x 4 MHz.
    SampleRate (1, 1) {mustBePositive, mustBeFinite, mustBeA(SampleRate, {'double', 'single'})} = 499.2*4*1e6

    %Visualization Channel visualization
    %   Specify Visualization as one of "Off" | "Impulse response". When
    %   visualization is "Impulse response", separate window(s) show up to
    %   display the channel impulse response (CIR). The default value of
    %   this property is "Off".
    Visualization = 'Off';
  
    %Distance Link distance in meters
    % Specify Distance as a positive scalar, in meters. The UWB channel
    % model is based on measurements performed on a 7-20 m distance range
    % for the residential environment, 3-28 m for the indoor office
    % environment, 5-17 m for the outdoor environment, and 2-8 m for the
    % industrial environment. The default is 10.
    Distance  (1, 1) {mustBeA(Distance, {'double', 'single'}), mustBePositive, mustBeFinite} = 10

    %MaxDopplerShift Maximum Doppler shift (Hz) 
    %   Specify the maximum Doppler shift for all channel paths in Hertz as
    %   a double precision, real, nonnegative scalar. The Doppler shift
    %   applies to all the paths of the channel. When you set the
    %   MaxDopplerShift to 0, the channel remains static for the entire
    %   input. The default value of this property is 5 Hz.
    MaxDopplerShift  (1, 1) {mustBeA(MaxDopplerShift, {'double', 'single'}), mustBeNonnegative, mustBeFinite} = 5

    %SampleDensity Number of time samples per half wavelength
    %   Number of samples of filter coefficient generation per half
    %   wavelength. The coefficient generation sampling rate is F_cg =
    %   MaxDopplerShift * 2 * SampleDensity. Setting SampleDensity = Inf
    %   sets F_cg = SampleRate. The default value is 64.
    SampleDensity  (1, 1) {mustBeA(SampleDensity, {'double', 'single'}), mustBePositive} = 64
  end

  properties(Constant, Hidden)
    VisualizationSet = matlab.system.StringSet({'Off', 'Impulse response'});

    %ChannelFiltering Channel filtering
    %   Set this property to false to disable channel filtering. When this
    %   property is set to false, running this object will output channel
    %   path gains only. The object does not accept an input signal and
    %   produces no filtered output signal. The default value of this
    %   property is true.
    ChannelFiltering (1, 1) logical = true;
  end  

  properties (Access = private, Nontunable)
    pChannelFilter
    pChannelConfig
    pNumClusters
    pClusterArrivalTimes
    pClusterEnergies
    pPathArrivalTimes
    pAbsolutePathArrivalTimes
    pPathAveragePowers
    pPathPhases
    pNakagamiM
    pPathGainSamplePeriod
    pFreqFilter
    pArrayPlot
    pShadowing
  end
  properties (Access = private)
    pCurrentPathGains
    pLastChannelRealizationIdx;
    pProcessedSamples;
  end

  methods
    function obj = uwbChannel(varargin)
      setProperties(obj, nargin, varargin{:}, 'Environment', 'HasLOS');
    end
  end

  methods (Access=protected)

    function num = getNumInputsImpl(obj)
      num = 0 + obj.ChannelFiltering;
    end
    function num = getNumOutputsImpl(~)
      num = 1; % + obj.ChannelFiltering;
    end

    function [Nt, Nr] = getNumTxAndRx(~)
      [Nt, Nr] = deal(1);
    end

    function validatePropertiesImpl(obj)
  
      % No code generation when visualization is on
      coder.internal.errorIf(~isempty(coder.target) && ...
          ~strcmp(obj.Visualization, 'Off'), ...
          'comm:FadingChannel:NoCodegenForVisual');    
    end

    function validateInputsImpl(obj, x)
    
      % comm.ChannelFilter only accepts double/single
      validateattributes(x, {'double','single'}, {'column','finite'}, ...
          class(obj), 'signal input'); 
    end
    
    function setupImpl(obj, varargin)
      coder.extrinsic('lrwpan.uwb.internal.clusterization', 'lrwpan.uwb.internal.pathModeling', 'lrwpan.uwb.internal.setupNakagamiParams');
      coder.extrinsic('uwbChannel.designFrequencyFilter');
      coder.extrinsic('RandStream', 'RandStream.getGlobalStream');

      obj.pInputDataType = underlyingType(varargin{1});
      obj.pRealDataPrototype = real(cast([], 'like', varargin{1}));

      [obj.pLastChannelRealizationIdx, obj.pProcessedSamples] = deal(zeros(1, 1, obj.pInputDataType));

      setupRNG(obj); % Set up RNG
      % For codegen (extrinsic calls), do the setup() with an extrinsic'ed random stream.
      % By the end of setup, the state of the channel-object's random stream is set to a state
      % as if it was the one performing all the random calls.
      if strcmp(obj.RandomStream, 'Global stream')
        tempStream = RandStream.getGlobalStream;
      else
        tempStream = RandStream('mt19937ar', 'Seed', obj.Seed);
      end
      
      %% Environment parameterization:
      env = coder.const(@lrwpan.uwb.internal.environmentConfig, obj.Environment, obj.HasLOS, obj.pInputDataType);
      obj.pChannelConfig = env;

      %% Clusterization:
      [obj.pNumClusters, obj.pClusterArrivalTimes, obj.pClusterEnergies] = ...
        coder.const(@lrwpan.uwb.internal.clusterization, obj.Environment, obj.HasLOS, env.AverageNumClusters, env.ClusterArrivalRate, ...
        env.ClusterShadowingDeviation, env.ClusterEnergyDecayConstant, tempStream, obj.pInputDataType);

      %% Path modeling:
      [obj.pPathArrivalTimes, obj.pPathAveragePowers, obj.pPathPhases] = coder.const(@lrwpan.uwb.internal.pathModeling, env, ...
        obj.pClusterArrivalTimes, obj.pClusterEnergies, obj.MinRelativePathPower, obj.SampleRate, obj.NormalizePathGains, tempStream, obj.pInputDataType);
      
      obj.pAbsolutePathArrivalTimes = coder.const(uwbChannel.rel2abs(obj.pNumClusters, obj.pClusterArrivalTimes, obj.pPathArrivalTimes));

      %% Nakagami M parameter
      [obj.pNakagamiM, state] = coder.const(@lrwpan.uwb.internal.setupNakagamiParams, env, obj.pPathArrivalTimes, tempStream, obj.pInputDataType);

      %% Shadowing
      % single shadowing realization per object lifetime (non-tunable Distance)
      sigma = env.ShadowingDeviation;
      obj.pShadowing = coder.const(randn(tempStream, 1, 1) * sigma);

      if ~strcmp(obj.RandomStream, 'Global stream')
        % set the state of the RNGStream (possibly a codegen object), as if all calls were performed by it in setup()
        obj.pRNGStream.State = state;

      % else for the Global Stream, tempStream has been advancing its state
      end
            
      %% Channel filter
      if obj.ChannelFiltering
        obj.pChannelFilter = comm.ChannelFilter(SampleRate = double(obj.SampleRate), PathDelays=double(coder.const(@cell2mat, obj.pAbsolutePathArrivalTimes)/1e9));
        obj.pChannelFilter.NormalizeChannelOutputs = false;
      end      

      %% Visualization
      if strcmp(obj.Visualization, 'Impulse response')
        setupVisual(obj);
      end

      %% Period of channel realizations
      if isfinite(obj.SampleDensity)
        Fcg = obj.MaxDopplerShift * 2 * obj.SampleDensity;
        obj.pPathGainSamplePeriod = floor(obj.SampleRate/Fcg); % in samples
      else
        obj.pPathGainSamplePeriod = ones(1, 1, obj.pInputDataType); % new channel realization  every input sample
      end

      %% Channel realization (initial, in case step length is too small)
      obj.pCurrentPathGains = fadingRealization(obj);
      
      numerator = coder.const(@uwbChannel.designFrequencyFilter, obj.ChannelNumber, obj.pChannelConfig.FrequencyExponent);
      obj.pFreqFilter = dsp.FIRFilter(numerator, FullPrecisionOverride=false, OutputDataType="Same as input");
      % This command can visualize the filter response:
      % fvtool(obj.pFreqFilter);
    end

    function setupVisual(obj)
      if strcmp(obj.Visualization, 'Impulse response')
        obj.pArrayPlot = dsp.ArrayPlot(XDataMode='Custom', ShowLegend=true, ...
          XLabel = 'Time (ns)', YLabel = 'Magnitude of Nakagami path gains');

        if ~isempty(obj.pNumClusters)
          % pre setup() call, from loadObject
          legendStr = {};
          for idx=1:obj.pNumClusters
            % convert relative (within cluster) path arrival times to absolute time instances
            legendStr = [legendStr ['Cluster#' num2str(idx)]]; %#ok<AGROW>
          end
          obj.pArrayPlot.ChannelNames = legendStr;
        end
      end
    end
    
    function varargout = stepImpl(obj, varargin)

        nextChannelRealizationIdx = obj.pLastChannelRealizationIdx + obj.pPathGainSamplePeriod;
      % if obj.ChannelFiltering
        x = varargin{1};
        x = applyPropagationPlusAntennaEffects(obj, x);
        currLen = size(x, 1);
        % Filter first part of input with current gains. Possibly entire input.
        y = obj.pChannelFilter(x(1:min(currLen, nextChannelRealizationIdx-obj.pProcessedSamples), 1), cell2mat(obj.pCurrentPathGains)); % input is single-channel, x(:, 1) is for codegen
      % else
      %   currLen = obj.pPathGainSamplePeriod * obj.NumRealizations; % pretending there is an input
      % end

      if obj.pLastChannelRealizationIdx == 0
        gains = [obj.pCurrentPathGains]; % first gains need to output somehow
      else
        gains = cell(0, obj.pNumClusters);
      end
      coder.varsize('gains', [], [1 0]);
      
      % If channel gains change within this input, then get new gains and
      % filter remaining input part(s)
      while nextChannelRealizationIdx-obj.pProcessedSamples <= currLen
        obj.pCurrentPathGains = fadingRealization(obj);
        
        gains = [gains; obj.pCurrentPathGains]; %#ok<AGROW> 

        obj.pLastChannelRealizationIdx = nextChannelRealizationIdx;
        nextChannelRealizationIdx = obj.pLastChannelRealizationIdx + obj.pPathGainSamplePeriod;

        % if obj.ChannelFiltering
          offset = obj.pLastChannelRealizationIdx - obj.pProcessedSamples;
          y = [y; obj.pChannelFilter(x(1+offset:min(currLen, nextChannelRealizationIdx-obj.pProcessedSamples), 1), cell2mat(obj.pCurrentPathGains))]; %#ok<AGROW> % input is single-channel, x(:, 1) is for codegen
        % end
      end

      obj.pProcessedSamples = obj.pProcessedSamples + currLen;
      % if obj.ChannelFiltering
        varargout{1} = y;
        % varargout{2} = gains;
      % else
        % varargout{1} = gains;
      % end
    end

    function visualizeChannelGains(obj, pathGains)

      L = obj.pNumClusters;
      coder.internal.errorIf(L>128, 'lrwpan:LRWPAN:TooManyClusters2Visualize', L);

      obj.pArrayPlot.YLimits = [0 max(max(abs(cell2mat(pathGains))))];

      % Clusterized array plot, use multiple channels for different colors.
      % Need a common, custom, increasing X vector. Y values for other channels need to be NaN
      
      [customXData, tapOrder] = sort(cell2mat(obj.pAbsolutePathArrivalTimes));
      obj.pArrayPlot.CustomXData = [-eps double(customXData)]; % make sure x=0 is included
      
      for realization=1:size(pathGains, 1) % in case multiple realizations are passed at once
        offset = zeros(1, 1, obj.pInputDataType);
        allGains = cell2mat(pathGains(realization, :));
        allGains = allGains(tapOrder); % sort in increasing time
        
        allChannels = nan(1+numel(allGains), L, obj.pInputDataType);  % +1 for -eps
      
        for clusterIdx = 1:L
          numClusterGains = numel(pathGains{realization, clusterIdx});
      
          range = offset+1:offset+numClusterGains;
          for pathIdx = 1:numel(range)
            pos = find(range(pathIdx)==tapOrder);
            allChannels(1+pos, clusterIdx) = pathGains{realization, clusterIdx}(pathIdx);
          end
          
          offset = offset + numClusterGains;
        end
        obj.pArrayPlot(abs(allChannels));
        pause(0.2); % emulate streaming
      end
    end

    function resetImpl(obj)
      resetRNG(obj);  % Reset random number generator

      reset(obj.pFreqFilter);
      if obj.ChannelFiltering
        reset(obj.pChannelFilter);
      end
      [obj.pLastChannelRealizationIdx, obj.pProcessedSamples] = deal(zeros(1, 1, obj.pInputDataType));
      obj.pCurrentPathGains = fadingRealization(obj);
    end

    function releaseImpl(obj)
      if obj.ChannelFiltering
        release(obj.pChannelFilter);
      end
    end

    function s = infoImpl(obj)
      %info Returns characteristic information about the channel
      %   S = info(OBJ) returns a structure containing characteristic
      %   information, S, about the UWB fading channel. A description of
      %   the fields and their values is as follows:
      % 
      %   EnvironmentParameterization - Structure containing parameters for the given Environment and HasLOS
      %   CenterFrequency             - Center frequency for ChannelNumber
      %   Bandwidth                   - Channel bandwidth for ChannelNumber
      %   NumClusters                 - Number of clusters in channel realization
      %   ClusterArrivalTimes         - Start time for each cluster in channel realization
      %   ClusterEnergies             - Mean energy for each cluster in channel realization
      %   PathArrivalTimes            - Start time for each path in channel realization, relative to cluster start
      %   AbsolutePathArrivalTimes    - Start time for each path in channel realization, since t=0
      %   PathAveragePowers           - Average power for each path in channel realization
      %   PathPhases                  - Phase for each path in channel realization
      %   NakagamiMFactors            - Nakagami M factor for each path in channel realization
      %   PathGainRate                - Channel realization rate
      %   FrequencyFilterDelay        - Delay of filter for frequency-dependent propagation
      %   ChannelFilterDelay          - Delay of signal filtering
      %   ChannelFilterCoefficients   - Coefficients of channel filter

      warnS = warning('off', 'MATLAB:structOnObject');
      s.EnvironmentParameterization = struct(obj.pChannelConfig);
      warning(warnS);

      [Fc, bw] = uwbChannel.getSpectralProp(obj.ChannelNumber);
      s.CenterFrequency = Fc;
      s.Bandwidth = bw;

      s.NumClusters               = obj.pNumClusters;
      s.ClusterArrivalTimes       = obj.pClusterArrivalTimes;
      s.ClusterEnergies           = obj.pClusterEnergies;
      s.PathArrivalTimes          = obj.pPathArrivalTimes;
      s.AbsolutePathArrivalTimes  = obj.pAbsolutePathArrivalTimes;
      s.PathAveragePowers         = obj.pPathAveragePowers; 
      s.PathPhases                = obj.pPathPhases;
      s.NakagamiMFactors          = obj.pNakagamiM;
      s.PathGainRate              = obj.MaxDopplerShift * 2 * obj.SampleDensity;

      if isempty(obj.pFreqFilter)
        s.FrequencyFilterDelay = [];
      else
        s.FrequencyFilterDelay = floor((length(obj.pFreqFilter.Numerator)-1)/2); % half the order
      end
      if isempty(obj.pChannelFilter)
        s.ChannelFilterDelay        = [];
        s.ChannelFilterCoefficients = [];
      else
        tmp = info(obj.pChannelFilter);
        s.ChannelFilterDelay        = tmp.ChannelFilterDelay;
        s.ChannelFilterCoefficients = tmp.ChannelFilterCoefficients;
      end
    end

    function s = saveObjectImpl(obj)
      s = saveObjectImpl@matlab.System(obj);
      if isLocked(obj)
        % save private properties
        s.pChannelFilter              = matlab.System.saveObject(obj.pChannelFilter);
        s.pFreqFilter                 = matlab.System.saveObject(obj.pFreqFilter);
        s.pChannelConfig              = matlab.System.saveObject(obj.pChannelConfig);
        s.pNumClusters                = obj.pNumClusters;
        s.pClusterArrivalTimes        = obj.pClusterArrivalTimes;
        s.pClusterEnergies            = obj.pClusterEnergies;
        s.pPathArrivalTimes           = obj.pPathArrivalTimes;
        s.pAbsolutePathArrivalTimes   = obj.pAbsolutePathArrivalTimes;
        s.pPathAveragePowers          = obj.pPathAveragePowers;
        s.pPathPhases                 = obj.pPathPhases;
        s.pNakagamiM                  = obj.pNakagamiM;
        s.pProcessedSamples           = obj.pProcessedSamples;
        s.pPathGainSamplePeriod       = obj.pPathGainSamplePeriod;
        s.pCurrentPathGains           = obj.pCurrentPathGains;
        s.pLastChannelRealizationIdx  = obj.pLastChannelRealizationIdx;
        s.pShadowing                  = obj.pShadowing;
        % no save for array plot, a new one will be created
        
        s.pRNGStream                  = obj.pRNGStream;
        s.pInputDataType              = obj.pInputDataType;
      end
    end

    function loadObjectImpl(obj, s, wasLocked)
      if wasLocked
        obj.pChannelFilter              = matlab.System.loadObject(s.pChannelFilter);
        obj.pFreqFilter                 = matlab.System.loadObject(s.pFreqFilter);
        obj.pChannelConfig              = matlab.System.loadObject(s.pChannelConfig);
        obj.pNumClusters                = s.pNumClusters;
        obj.pClusterArrivalTimes        = s.pClusterArrivalTimes;
        obj.pClusterEnergies            = s.pClusterEnergies;
        obj.pPathArrivalTimes           = s.pPathArrivalTimes;
        obj.pAbsolutePathArrivalTimes   = s.pAbsolutePathArrivalTimes;
        obj.pPathAveragePowers          = s.pPathAveragePowers;
        obj.pPathPhases                 = s.pPathPhases;
        obj.pNakagamiM                  = s.pNakagamiM;
        obj.pProcessedSamples           = s.pProcessedSamples;
        obj.pPathGainSamplePeriod       = s.pPathGainSamplePeriod;
        obj.pCurrentPathGains           = s.pCurrentPathGains;
        obj.pLastChannelRealizationIdx  = s.pLastChannelRealizationIdx;
        obj.pShadowing                  = s.pShadowing;

        if isfield(s, 'pRNGStream') && ~isempty(s.pRNGStream)
          obj.pRNGStream       = RandStream(obj.RandomNumGenerator, 'Seed', obj.Seed);
          obj.pRNGStream.State = s.pRNGStream.State;
        end
        obj.pInputDataType  = s.pInputDataType;
      end
      % Call the base class method to load public properties
      loadObjectImpl@matlab.System(obj, s, wasLocked);
      setupVisual(obj); % create new Array plot object
    end

    function flag = isInactivePropertyImpl(obj, prop)
      flag = false;
      if strcmp(prop, 'Seed')
        flag = strcmp(obj.RandomStream, 'Global stream');
      end
      % if strcmp(prop, 'NumRealizations')
      %   flag = obj.ChannelFiltering;
      % end
    end
  end

  methods (Hidden)
    function pathGains = fadingRealization(obj)

      L = numel(obj.pPathAveragePowers);                   % number of clusters
      
      pathGains = cell(1, L);
      for clusterIdx = 1:L                            % for each cluster
        K_L = numel(obj.pPathAveragePowers{clusterIdx});   % number of paths per cluster
        pathGains{clusterIdx} = complex(zeros(1, K_L, obj.pInputDataType)); % start complex for phase rotation, in codegen
      end % init everything first, for codegen
      for clusterIdx = 1:L                            % for each cluster
        K_L = numel(obj.pPathAveragePowers{clusterIdx});   % number of paths per cluster
        for pathIdx = 1:K_L
          thisM = obj.pNakagamiM{clusterIdx}(pathIdx);
          newGamma = gammaRV(obj, thisM, obj.pPathAveragePowers{clusterIdx}(pathIdx)/thisM);
          pathGains{clusterIdx}(pathIdx) = sqrt(newGamma); % Gamma -> Nakagami
        end
      end

      % pathGains = cellfun(@(a, phi) a.*exp(1i*phi), pathGains, obj.pPathPhases, 'UniformOutput', false);  % Eq. (15)
      % codegen-supported version:
      for idx = 1:numel(pathGains)
        pathGains{idx} = pathGains{idx}.*exp(1i*obj.pPathPhases{idx});
      end

      if strcmp(obj.Visualization, 'Impulse response')
        visualizeChannelGains(obj, pathGains);
      end
    end
    
    function y = applyPropagationPlusAntennaEffects(obj, x)
      % Distance-dependent path loss
      y = distancePathLoss(obj, x);

      % Frequency-dependent path loss
      y = frequencyPathLoss(obj, y);

      % Antenna effects
      % presence of people ("antenna attenuation factor"), see Sec II.B.4 in [1] 
      y = y * 10^(-obj.pChannelConfig.AntennaLoss/10);   % convert from dB to W
    end
    
    function [signalOut, PLd] = distancePathLoss(obj, x)
    
      PL0 = obj.pChannelConfig.ReferencePathLoss;
      d = obj.Distance;
      n = obj.pChannelConfig.PathLossExponent;

      d0 = ones(1, 1, obj.pInputDataType);              % reference distance in meters
      PLd = PL0 + 10*n*log10(d/d0) + obj.pShadowing;    % distance-caused path-loss, specified in dB
      signalOut = x * 10^(-PLd/20);                     % apply path loss (in dB) to linear scale
    end

    function [y, PLf] = frequencyPathLoss(obj, x)
      y = obj.pFreqFilter(x);                           % apply per-frequency amplitudes
      PLf = 20*log10(x./y);
    end

    function g = gammaRV(obj, k, theta)
      %gammaRV Generate Gamma-distributed random variable
      % G = gammaRV(K, THETA) returns the Gamma-distributed random variable G, given
      % the shape parameter K and the scale parameter THETA, as per the method
      % described in: https://en.wikipedia.org/wiki/Gamma_distribution#Generating_gamma-distributed_random_variables
      
      %% 1. Create Gamma(1, 1) r.v. (x floor(k) times)
      % Gamma(1, 1) is an exponential random variable with rate 1, use inverse transform method:
      g11 = -log(generateRand(obj, 1, floor(k)));
      
      %% 2. Create a Gamma(floor(k), 1) r.v
      gN1 = sum(g11);
      
      %% 3. Create a Gamma(mod(k, 1), 1) r.v
      delta = mod(k, 1);
      eta = inf(1, 1, obj.pInputDataType);  % Init values ensuring that WHILE loop starts
      ksi = ones(1, 1, obj.pInputDataType);
      while eta > ksi^(delta-1)*exp(-ksi)
        % Generate U, V, W as uniform r.v.
        UVW = generateRand(obj, 1, 3);
        U = UVW(1);
        V = UVW(2);
        W = UVW(3);
        if U < exp(1)/(exp(1)+delta)
          ksi = V^(1/delta);
          eta = W*ksi^(delta-1);
        else
          ksi = 1 - log(V);
          eta = W*exp(-ksi);
        end
      end
      % ksi is now distributed as Gamma(delta, 1). 
      
      %% 4. Create a Gamma(k, theta) r.v
      % combine above results
      g = theta*(ksi + gN1);      
    end

    function overrideVisual(obj, newScopeObj)
      obj.pArrayPlot = newScopeObj;
    end
end


  methods(Static, Access = protected)    
    function groups = getPropertyGroupsImpl    
      pdp = matlab.system.display.Section( ...
          'Title', 'Delay Profile', ...
          'PropertyList', {'Environment', 'HasLOS', 'SampleRate', ...
          'MaxDopplerShift', 'SampleDensity', 'MinRelativePathPower',...
          'NormalizePathGains', 'Visualization'});
      
      pdpGroup = matlab.system.display.SectionGroup(...
          'Title', 'Delay Profile', ...
          'Sections', pdp);

      propagation = matlab.system.display.Section( ...
          'Title', 'Propagation', ...
          'PropertyList', {'ChannelNumber', 'Distance'});    
      
      propGroup = matlab.system.display.SectionGroup(...
          'Title', 'Propagation', ...
          'Sections', propagation);
      propGroup.IncludeInShortDisplay = true;

      realization = matlab.system.display.Section( ...
          'PropertyList', {'RandomStream', 'Seed'});
  
      realGroup = matlab.system.display.SectionGroup(...
          'Title', 'Realization', ...
          'Sections', realization);
      realGroup.IncludeInShortDisplay = true;
  
      groups = [pdpGroup, propGroup, realGroup];
    end
  end
  
  methods (Hidden, Static)
    function b = isAllowedInSystemBlock(~)
      b = false;
    end

    function absolutePathArrivalTimes = rel2abs(L, clusterArrivalTimes, pathArrivalTimes)
      %REL2ABS Convert relative arrival times (within a cluster) to absolute times
      %   ABS = rel2abs(L, CLUSTERTIMES, PATHTIMES) converts the relative arrival
      %   times within a cluster PATHTIMES to the absolute arrival times ABS. L
      %   is the number of clusters and CLUSTERTIMES contains the starting time
      %   for each cluster.
    
      % convert relative arrival times (within a cluster) to absolute times (since t=0)
      absolutePathArrivalTimes = cell(size(pathArrivalTimes));
      for idx=1:L
        % convert relative (within cluster) path arrival times to absolute time instances
        absolutePathArrivalTimes{idx} = pathArrivalTimes{idx} + clusterArrivalTimes(idx);
      end
    end

    function [Fc, bw] = getSpectralProp(channelNum)
    
      if any(channelNum == [4 11])
        bw = 1331.2e6;
      elseif channelNum == 7 
        bw = 1081.6e6;
      elseif channelNum == 15
        bw = 1354.97e6;
      else
        bw = 499.2e6;
      end
      allFc = [499.2 3494.4 3993.6 4492.8 3993.6 6489.6 6988.8 6489.6 7488.0 7987.2 8486.4 7987.2 8985.6 9484.8 9984.0 9484.8]*1e6;
      Fc = allFc(channelNum + 1); % 1st channel is channel 0.
    end

    function numerator = designFrequencyFilter(channelNum, kappa)
      %DESIGNFREQUENCYFILTER Create filter for frequency-dependent propagation
      %   NUM = designFrequencyFilter(CHANNELNUM, KAPPA) creates an
      %   arbitrary-magnitude FIR filter, as specified by the numerator
      %   coefficients NUM, that enables the frequency dependent pathloss for
      %   channel CHANNELNUM and the frequency exponent KAPPA.
       
      [Fc, bw] = uwbChannel.getSpectralProp(channelNum);
    
      % filter creation and visualization:
      if Fc ~= 499.2e6  % not Channel 0 (default)
        freq = (-bw/2:bw/2000:bw/2);                  % filter for baseband signal
        ampl = 1./((freq+Fc)/Fc).^(2*kappa +2);       % amplitudes as per passband equation    
        filterOrder = 50;
        dLP = fdesign.arbmag(filterOrder, freq/(bw/2), double(ampl));
        freqFilter = design(dLP , 'firls', 'systemobject', true);
        numerator = freqFilter.Numerator;
      
      else % Channel 0, default
        % hardcode output from above commands for the default channel (0), for all environment combinations, to speedup execution
        if abs(kappa - 1.12) < 1e-4
          % Residential, LOS
          numerator = [-0.0150 + 0.1178i   0.0156 - 0.1227i  -0.0162 + 0.1281i   0.0169 - 0.1339i  -0.0177 + 0.1403i   0.0186 - 0.1473i ...
                    -0.0197 + 0.1551i   0.0210 - 0.1636i  -0.0225 + 0.1732i   0.0242 - 0.1839i  -0.0264 + 0.1960i   0.0289 - 0.2098i ...
                    -0.0321 + 0.2256i   0.0361 - 0.2440i  -0.0412 + 0.2655i   0.0478 - 0.2910i  -0.0567 + 0.3218i   0.0689 - 0.3597i ...
                    -0.0862 + 0.4072i   0.1121 - 0.4683i  -0.1529 + 0.5492i   0.2221 - 0.6602i  -0.3516 + 0.8170i   0.6285 - 1.0367i ...
                    -1.3308 + 1.2469i   2.8417 + 0.0000i  -1.3308 - 1.2469i   0.6285 + 1.0367i  -0.3516 - 0.8170i   0.2221 + 0.6602i ...
                    -0.1529 - 0.5492i   0.1121 + 0.4683i  -0.0862 - 0.4072i   0.0689 + 0.3597i  -0.0567 - 0.3218i   0.0478 + 0.2910i ...
                    -0.0412 - 0.2655i   0.0361 + 0.2440i  -0.0321 - 0.2256i   0.0289 + 0.2098i  -0.0263 - 0.1960i   0.0242 + 0.1839i ... 
                    -0.0225 - 0.1732i   0.0210 + 0.1636i  -0.0197 - 0.1551i   0.0186 + 0.1473i  -0.0177 - 0.1403i   0.0169 + 0.1339i ...
                    -0.0162 - 0.1281i   0.0156 + 0.1227i   0.0000 + 0.0000i];
        elseif abs(kappa - 1.53) < 1e-4
          % Residential, NLOS
          numerator = [-0.0288 + 0.2088i   0.0300 - 0.2175i  -0.0313 + 0.2270i   0.0328 - 0.2374i  -0.0345 + 0.2486i   0.0364 - 0.2610i ...  
                    -0.0387 + 0.2747i   0.0413 - 0.2898i  -0.0445 + 0.3066i   0.0482 - 0.3255i  -0.0526 + 0.3468i   0.0580 - 0.3710i ...
                    -0.0647 + 0.3987i   0.0730 - 0.4307i  -0.0836 + 0.4682i   0.0973 - 0.5126i  -0.1156 + 0.5659i   0.1407 - 0.6309i ...
                    -0.1762 + 0.7118i   0.2286 - 0.8146i  -0.3102 + 0.9484i   0.4460 - 1.1262i  -0.6918 + 1.3640i   1.1872 - 1.6590i ...
                    -2.2992 + 1.8068i   4.0762 - 0.0000i  -2.2992 - 1.8068i   1.1872 + 1.6590i  -0.6918 - 1.3640i   0.4460 + 1.1262i ...
                    -0.3102 - 0.9484i   0.2286 + 0.8146i  -0.1762 - 0.7118i   0.1407 + 0.6309i  -0.1156 - 0.5659i   0.0973 + 0.5126i ...
                    -0.0835 - 0.4682i   0.0730 + 0.4307i  -0.0646 - 0.3987i   0.0580 + 0.3710i  -0.0526 - 0.3468i   0.0481 + 0.3255i ...
                    -0.0444 - 0.3066i   0.0413 + 0.2898i  -0.0387 - 0.2747i   0.0364 + 0.2610i  -0.0345 - 0.2486i   0.0328 + 0.2374i ...
                    -0.0313 - 0.2270i   0.0300 + 0.2175i   0.0000 + 0.0000i];
        elseif abs(kappa - 0.03) < 1e-4
          % Indoor office, LOS
          numerator = [-0.0024 + 0.0236i   0.0024 - 0.0246i  -0.0025 + 0.0256i   0.0026 - 0.0268i  -0.0027 + 0.0281i   0.0028 - 0.0295i ...
                    -0.0029 + 0.0311i   0.0030 - 0.0328i  -0.0032 + 0.0348i   0.0034 - 0.0369i  -0.0036 + 0.0394i   0.0038 - 0.0422i ...
                    -0.0042 + 0.0454i   0.0046 - 0.0492i  -0.0052 + 0.0537i   0.0059 - 0.0590i  -0.0068 + 0.0654i   0.0082 - 0.0735i ...
                    -0.0101 + 0.0837i   0.0130 - 0.0972i  -0.0177 + 0.1158i   0.0262 - 0.1428i  -0.0432 + 0.1853i   0.0853 - 0.2600i ...
                    -0.2354 + 0.4113i   1.3548 + 0.0000i  -0.2354 - 0.4113i   0.0853 + 0.2600i  -0.0432 - 0.1853i   0.0262 + 0.1428i ...
                    -0.0177 - 0.1158i   0.0130 + 0.0972i  -0.0101 - 0.0837i   0.0082 + 0.0735i  -0.0068 - 0.0654i   0.0059 + 0.0590i ...
                    -0.0052 - 0.0537i   0.0046 + 0.0492i  -0.0042 - 0.0454i   0.0038 + 0.0422i  -0.0036 - 0.0394i   0.0033 + 0.0369i ...
                    -0.0032 - 0.0348i   0.0030 + 0.0328i  -0.0029 - 0.0311i   0.0028 + 0.0295i  -0.0027 - 0.0281i   0.0026 + 0.0268i ...
                    -0.0025 - 0.0256i   0.0024 + 0.0246i   0.0000 + 0.0000i];
        elseif abs(kappa - 0.71) < 1e-4
          % Indoor office, NLOS
          numerator = [-0.0077 + 0.0658i   0.0080 - 0.0686i  -0.0083 + 0.0716i   0.0086 - 0.0749i  -0.0090 + 0.0785i   0.0094 - 0.0824i ...
                    -0.0099 + 0.0868i   0.0104 - 0.0916i  -0.0111 + 0.0970i   0.0119 - 0.1030i  -0.0129 + 0.1098i   0.0141 - 0.1176i ... 
                    -0.0156 + 0.1265i   0.0174 - 0.1369i  -0.0197 + 0.1491i   0.0228 - 0.1636i  -0.0269 + 0.1812i   0.0326 - 0.2030i ...
                    -0.0407 + 0.2304i   0.0529 - 0.2661i  -0.0723 + 0.3142i   0.1060 - 0.3819i  -0.1709 + 0.4820i   0.3180 - 0.6372i ...
                    -0.7415 + 0.8503i   2.0614 - 0.0000i  -0.7415 - 0.8503i   0.3180 + 0.6372i  -0.1709 - 0.4820i   0.1060 + 0.3819i ...
                    -0.0723 - 0.3142i   0.0529 + 0.2661i  -0.0407 - 0.2304i   0.0326 + 0.2030i  -0.0269 - 0.1812i   0.0228 + 0.1636i ...
                    -0.0197 - 0.1491i   0.0174 + 0.1369i  -0.0156 - 0.1265i   0.0141 + 0.1176i  -0.0129 - 0.1098i   0.0119 + 0.1030i ...
                    -0.0111 - 0.0970i   0.0104 + 0.0916i  -0.0099 - 0.0868i   0.0094 + 0.0824i  -0.0089 - 0.0785i   0.0086 + 0.0749i ...
                    -0.0082 - 0.0716i   0.0080 + 0.0686i   0.0000 + 0.0000i];
        elseif abs(kappa + 1.103) < 1e-4
          % Industrial LOS
          numerator = [0.0001 - 0.0014i  -0.0001 + 0.0014i   0.0001 - 0.0015i  -0.0001 + 0.0016i   0.0001 - 0.0017i  -0.0001 + 0.0017i ...
                     0.0001 - 0.0018i  -0.0001 + 0.0019i   0.0001 - 0.0021i  -0.0001 + 0.0022i   0.0001 - 0.0023i  -0.0001 + 0.0025i ...
                     0.0001 - 0.0027i  -0.0001 + 0.0029i   0.0001 - 0.0032i  -0.0002 + 0.0035i   0.0002 - 0.0039i  -0.0002 + 0.0044i ...
                     0.0002 - 0.0050i  -0.0002 + 0.0058i   0.0003 - 0.0070i  -0.0004 + 0.0087i   0.0007 - 0.0116i  -0.0014 + 0.0173i ...
                     0.0046 - 0.0336i   0.9926 - 0.0000i   0.0046 + 0.0336i  -0.0014 - 0.0173i   0.0007 + 0.0116i  -0.0004 - 0.0087i ...
                     0.0003 + 0.0070i  -0.0002 - 0.0058i   0.0002 + 0.0050i  -0.0002 - 0.0044i   0.0002 + 0.0039i  -0.0002 - 0.0035i ...
                     0.0001 + 0.0032i  -0.0001 - 0.0029i   0.0001 + 0.0027i  -0.0001 - 0.0025i   0.0001 + 0.0023i  -0.0001 - 0.0022i ...
                     0.0001 + 0.0021i  -0.0001 - 0.0019i   0.0001 + 0.0018i  -0.0001 - 0.0017i   0.0001 + 0.0017i  -0.0001 - 0.0016i ...
                     0.0001 + 0.0015i  -0.0001 - 0.0014i   0.0000 + 0.0000i];
        elseif abs(kappa + 1.4270) < 1e-4
          % Industrial NLOS
          numerator = [ 0.0004 - 0.0054i  -0.0004 + 0.0057i   0.0004 - 0.0059i  -0.0004 + 0.0062i   0.0004 - 0.0065i  -0.0004 + 0.0068i ...
                     0.0004 - 0.0072i  -0.0004 + 0.0076i   0.0004 - 0.0080i  -0.0004 + 0.0085i   0.0004 - 0.0091i  -0.0004 + 0.0098i ...
                     0.0004 - 0.0105i  -0.0004 + 0.0114i   0.0004 - 0.0124i  -0.0004 + 0.0137i   0.0004 - 0.0152i  -0.0005 + 0.0171i ...
                     0.0005 - 0.0196i  -0.0005 + 0.0228i   0.0005 - 0.0274i  -0.0006 + 0.0342i   0.0008 - 0.0456i  -0.0013 + 0.0684i ...
                     0.0037 - 0.1363i   0.9942 - 0.0000i   0.0037 + 0.1363i  -0.0013 - 0.0684i   0.0008 + 0.0456i  -0.0006 - 0.0342i ...
                     0.0005 + 0.0274i  -0.0005 - 0.0228i   0.0005 + 0.0196i  -0.0005 - 0.0171i   0.0004 + 0.0152i  -0.0004 - 0.0137i ...
                     0.0004 + 0.0124i  -0.0004 - 0.0114i   0.0004 + 0.0105i  -0.0004 - 0.0098i   0.0004 + 0.0091i  -0.0004 - 0.0085i ...
                     0.0004 + 0.0080i  -0.0004 - 0.0076i   0.0004 + 0.0072i  -0.0004 - 0.0068i   0.0004 + 0.0065i  -0.0004 - 0.0062i ...
                     0.0004 + 0.0059i  -0.0004 - 0.0057i   0.0000 + 0.0000i];
        elseif abs(kappa - 0) < 1e-4
          % Open Outdoor (only LOS is allowed)
          numerator = [-0.0022 + 0.0224i   0.0023 - 0.0234i  -0.0024 + 0.0244i   0.0024 - 0.0255i  -0.0025 + 0.0267i   0.0026 - 0.0281i ...
                    -0.0027 + 0.0296i   0.0028 - 0.0312i  -0.0030 + 0.0331i   0.0032 - 0.0352i  -0.0034 + 0.0375i   0.0036 - 0.0402i ...
                    -0.0039 + 0.0433i   0.0043 - 0.0468i  -0.0048 + 0.0511i   0.0055 - 0.0561i  -0.0064 + 0.0623i   0.0076 - 0.0700i ...
                    -0.0094 + 0.0797i   0.0121 - 0.0926i  -0.0165 + 0.1103i   0.0244 - 0.1361i  -0.0403 + 0.1768i   0.0798 - 0.2487i ...
                    -0.2217 + 0.3961i   1.3350 + 0.0000i  -0.2217 - 0.3961i   0.0798 + 0.2487i  -0.0403 - 0.1768i   0.0244 + 0.1361i ...
                    -0.0165 - 0.1103i   0.0121 + 0.0926i  -0.0094 - 0.0797i   0.0076 + 0.0700i  -0.0064 - 0.0623i   0.0055 + 0.0561i ...
                    -0.0048 - 0.0511i   0.0043 + 0.0468i  -0.0039 - 0.0433i   0.0036 + 0.0402i  -0.0034 - 0.0375i   0.0031 + 0.0352i ...
                    -0.0030 - 0.0331i   0.0028 + 0.0312i  -0.0027 - 0.0296i   0.0026 + 0.0281i  -0.0025 - 0.0267i   0.0024 + 0.0255i ...
                    -0.0024 - 0.0244i   0.0023 + 0.0234i   0.0000 + 0.0000i];
        elseif abs(kappa - 0.12) < 1e-4
          % Outdoor, LOS
          numerator = [ -0.0028 + 0.0272i   0.0029 - 0.0284i  -0.0030 + 0.0296i   0.0031 - 0.0310i  -0.0032 + 0.0325i   0.0033 - 0.0341i ...
                    -0.0034 + 0.0359i   0.0036 - 0.0379i  -0.0038 + 0.0402i   0.0040 - 0.0427i  -0.0043 + 0.0455i   0.0046 - 0.0488i ...
                    -0.0050 + 0.0525i   0.0056 - 0.0569i  -0.0062 + 0.0620i   0.0071 - 0.0681i  -0.0083 + 0.0756i   0.0100 - 0.0849i ...
                    -0.0123 + 0.0966i   0.0159 - 0.1122i  -0.0218 + 0.1334i   0.0321 - 0.1643i  -0.0529 + 0.2125i   0.1037 - 0.2962i ...
                    -0.2798 + 0.4584i   1.4190 + 0.0000i  -0.2798 - 0.4584i   0.1037 + 0.2962i  -0.0529 - 0.2125i   0.0321 + 0.1643i ...
                    -0.0218 - 0.1334i   0.0159 + 0.1122i  -0.0123 - 0.0966i   0.0100 + 0.0849i  -0.0083 - 0.0756i   0.0071 + 0.0681i ...
                    -0.0062 - 0.0620i   0.0056 + 0.0569i  -0.0050 - 0.0525i   0.0046 + 0.0488i  -0.0043 - 0.0455i   0.0040 + 0.0427i ...
                    -0.0038 - 0.0402i   0.0036 + 0.0379i  -0.0034 - 0.0359i   0.0033 + 0.0341i  -0.0032 - 0.0325i   0.0030 + 0.0310i ...
                    -0.0030 - 0.0296i   0.0029 + 0.0284i   0.0000 + 0.0000i];
        elseif abs(kappa - 0.13) < 1e-4
          % Outdoor, NLOS
          numerator = [-0.0029 + 0.0277i   0.0029 - 0.0288i  -0.0030 + 0.0301i   0.0031 - 0.0315i  -0.0032 + 0.0330i   0.0033 - 0.0347i ...
                    -0.0035 + 0.0365i   0.0037 - 0.0386i  -0.0039 + 0.0408i   0.0041 - 0.0434i  -0.0044 + 0.0463i   0.0047 - 0.0496i ...
                    -0.0051 + 0.0534i   0.0057 - 0.0578i  -0.0064 + 0.0630i   0.0073 - 0.0692i  -0.0085 + 0.0768i   0.0102 - 0.0862i ...
                    -0.0126 + 0.0982i   0.0163 - 0.1139i  -0.0223 + 0.1355i   0.0328 - 0.1668i  -0.0540 + 0.2157i   0.1059 - 0.3004i ...
                    -0.2850 + 0.4638i   1.4266 + 0.0000i  -0.2850 - 0.4638i   0.1059 + 0.3004i  -0.0540 - 0.2157i   0.0328 + 0.1668i ...
                    -0.0223 - 0.1355i   0.0163 + 0.1139i  -0.0126 - 0.0982i   0.0102 + 0.0862i  -0.0085 - 0.0768i   0.0073 + 0.0692i ...
                    -0.0064 - 0.0630i   0.0057 + 0.0578i  -0.0051 - 0.0534i   0.0047 + 0.0496i  -0.0044 - 0.0463i   0.0041 + 0.0434i ...
                    -0.0039 - 0.0408i   0.0037 + 0.0386i  -0.0035 - 0.0365i   0.0033 + 0.0347i  -0.0032 - 0.0330i   0.0031 + 0.0315i ...
                    -0.0030 - 0.0301i   0.0029 + 0.0289i   0.0000 + 0.0000i];
        end
      end
    end
  end
end



