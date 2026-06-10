classdef environmentConfig < comm.internal.ConfigBase
%ENVIRONMENTCONFIG Configuration for propagation environment of UWB channel model
%   CFG = environmentConfig(Environment, HasLOS) creates a configuration object for a
%   IEEE 802.15.4a/z UWB Channel Model. Environment can be one of 'Residential' |
%   'Indoor office' | 'Outdoor' | 'Open outdoor' | 'Industrial'. HasLOS is a
%   boolean indicating whether a line-of-sight component exists between
%   transmitter and receiver. For 'Open outdoor' environments, HasLOS must be
%   true.
%
%   environmentConfig properties:
%
%   Environment                 - Environment type ('Residential', 'Indoor office', 'Outdoor', 'Open outdoor', 'Industrial'
%   HasLOS                      - Boolean indicating presence of line-of-sight component
%   ReferencePathLoss           - Path loss (in dB) at 1 m distance
%   PathLossExponent            - Path loss exponent
%   ShadowingDeviation          - Standard deviation of shadowing
%   AntennaLoss                 - Antenna loss
%   FrequencyExponent           - Frequency dependence of path loss
%   AverageNumClusters          - Mean number of clusters
%   ClusterArrivalRate          - Inter-cluster arrival rate
%   PathArrivalRate1            - First (ray) arrival rate for mixed Poisson model
%   PathArrivalRate2            - Second (ray) arrival rate for mixed Poisson model
%   MixtureProbability          - Mixture probability for mixed Poisson model
%   ClusterEnergyDecayConstant  - Inter-cluster exponential decay constant
%   PathDecaySlope              - Slope of intra-cluster exponential decay constant
%   PathDecayOffset             - Offset of intra-cluster exponential decay constant
%   ClusterShadowingDeviation   - Standard deviation of cluster shadowing
%   PDPIncreaseFactor           - Increase rate of alternative power delay profile
%   PDPDecayFactor              - Decay rate of alternative power delay profile (at later times)
%   FirstPathAttenuation        - Attenuation of 1st component in alternative power delay profile
%   NakagamiMeanOffset          - Offset of Nakagami m factor mean
%   NakagamiMeanSlope           - Slope of Nakagami m factor mean
%   NakagamiDeviationOffset     - Offset of Nakagami m factor variance
%   NakagamiDeviationSlope      - Slope of Nakagami m factor variance
%   FirstPathNakagamiMFactor    - Nakagami m factor of first (strong) component
%
%   See also uwbChannel.
%
%   References: 
%   [1] - A. F. Molisch et al., "IEEE 802.15.4a Channel Model-Final
%   Report," Tech. Rep., Document IEEE 802.1504-0062-02-004a, 2005.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

  properties(SetAccess = 'private')
    %Environment Environment type
    % Specify Environment as one of 'Residential' | 'Indoor office' | 'Outdoor' |
    % 'Open outdoor' | 'Industrial'. This property determines parameters
    % as well as the mode of operation for the UWB Channel. 
    Environment (1,:) char {mustBeMember(Environment,{'Residential', 'Indoor office', 'Outdoor', 'Open outdoor', 'Industrial'})} = 'Residential'

    %HasLOS Flag indicating presence of a line-of-sight (HasLOS) component
    % Specify HasLOS as a scalar logical. This flag indicates the presence of
    % a line-of-sight component between the transmitter and the receiver.
    HasLOS (1,1) logical = true;
  end

  properties
    %ReferencePathLoss Path loss at 1 m distance
    % ReferencePathLoss is the path loss PL_0 (i.e.,  ratio of received to
    % transmitted power), specified in dB, at a 1m reference distance.
    ReferencePathLoss

    %PathLossExponent Path loss exponent
    % PathLossExponent is the path loss exponent (n), which determines the rate at which
    % received power decays as a function of distance.
    PathLossExponent

    %ShadowingDeviation Standard deviation of shadowing
    % ShadowingDeviation is the standard deviation (sigma_S, in dB) of a zero-mean Gaussian distributed
    % random variable (S), which expresses shadowing, i.e., large-scale
    % fading.
    ShadowingDeviation

    %AntennaLoss Antenna loss
    % AntennaLoss is the signal power loss due to antennas (Aant), specified in dB.
    AntennaLoss

    %FrequencyExponent Frequency dependence of path loss
    % FrequencyExponent is the exponent (kappa) that determines the rate at
    % which received power decays as a function of frequency. The values
    % are specified in dB/octave. This property does not apply when Environment is
    % 'Open outdoor'.
    FrequencyExponent

    %AverageNumClusters Mean number of clusters
    % AverageNumClusters is the mean number of clusters (Lbar), in which rays are grouped.
    AverageNumClusters

    %ClusterArrivalRate Inter-cluster arrival rate
    % ClusterArrivalRate is the arrival rate (Lambda) of clusters (i.e.,
    % groups of rays), which follow a Poisson process. The value expresses
    % the number of arrivals with 1 ns. This property does not apply when
    % HasLOS is false and Environment is either 'Indoor office' or 'Industrial'.
    ClusterArrivalRate

    %PathArrivalRate1 - First (ray) arrival rate for mixed Poisson model
    % PathArrivalRate1 is one of the two arrival rates of rays within a
    % cluster (lambda1), which follow a Poisson process. PathArrivalRate1
    % is weighted by MixtureProbability. The value expresses the number of
    % arrivals with 1 ns. This property does not apply when Environment is
    % 'Industrial' or when Environment is 'Indoor office' and HasLOS is false.
    PathArrivalRate1

    %PathArrivalRate2 - Second (ray) arrival rate for mixed Poisson model
    % PathArrivalRate2 is the other arrival rate of rays within a cluster
    % (lambda2), which follow a Poisson process. PathArrivalRate2 is
    % weighted by the complement of the mixture probability,
    % 1-MixtureProbability. The value expresses the number of arrivals with
    % 1 ns.
    PathArrivalRate2

    %MixtureProbability Mixture probability for mixed Poisson model
    % MixtureProbability is a mixture probability (beta) that specifies the
    % relative weight of the two different ray arrival rates (within a
    % cluster) PathArrivalRate1 and PathArrivalRate2. Values must be
    % contained in [0 1].
    MixtureProbability

    %ClusterEnergyDecayConstant Inter-cluster exponential decay constant
    % ClusterEnergyDecayConstant is a constant (Gamma) determining the rate
    % of exponential decay of the cluster integrated energy as a function
    % of the cluster arrival time. The value is specified in ns. This
    % property does not apply when HasLOS is false and Environment is either
    % 'Indoor office' or 'Industrial'.
    ClusterEnergyDecayConstant

    %PathDecaySlope Slope of intra-cluster exponential decay constant
    % PathDecaySlope (k_gamma) proportionally affects gamma_l as a function
    % of the cluster arrival time. gamma_l is a constant determining the
    % rate of exponential decay of a ray's power as a function of the ray
    % arrival time.This property does not apply when HasLOS is false and
    % Environment is either 'Indoor office' or 'Industrial'.
    PathDecaySlope

    %PathDecayOffset Offset of intra-cluster exponential decay constant
    % PathDecayOffset is the y-intercept value (gamma_0, in ns) of the
    % function relating gamma_l with the cluster arrival time. gamma_l is a
    % constant determining the rate of exponential decay of a ray's power
    % as a function of the ray arrival time. This property does not apply
    % when HasLOS is false and Environment is either 'Indoor office' or
    % 'Industrial'.
    PathDecayOffset

    %ClusterShadowingDeviation Standard deviation of cluster shadowing
    % ClusterShadowingDeviation is the standard deviation (sigma_cluster in
    % dB) of a normally distributed random variable (Mcluster), which
    % expresses cluster shadowing, i.e., temporal variations from the
    % average cluster power. This property applies when Environment is
    % 'Residential' or when Environment is 'Industrial' and HasLOS is true.
    ClusterShadowingDeviation

    %PDPIncreaseFactor Increase rate of alternative power delay profile
    % PDPIncreaseFactor (gamma_rise) determines how quickly the alternative
    % power delay profile (PDP) rises. This alternative model is used when
    % HasLOS is false and Environment is 'Indoor office' or 'Industrial'.
    PDPIncreaseFactor

    %PDPDecayFactor Decay rate of alternative power delay profile (at later times)
    % PDPDecayFactor (gamma_1) determines how quickly the alternative power
    % delay profile (PDP) decays. This alternative model is used when
    % HasLOS is false and Environment is 'Indoor office' or 'Industrial'.
    PDPDecayFactor

    %FirstPathAttenuation Attenuation of 1st component in alternative power delay profile
    % FirstPathAttenuation is the attenuation (chi) of the first multi-path
    % component in the alternative delay profile (PDP). This alternative
    % model is used when HasLOS is false and Environment is 'Indoor office' or
    % 'Industrial'.
    FirstPathAttenuation

    %NakagamiMeanOffset Offset of Nakagami m factor mean
    % NakagamiMeanOffset is the y-intercept value (m0, in dB) of the function relating the mean
    % value of the Nakagami m factor with the delay of a multipath
    % component.
    NakagamiMeanOffset

    %NakagamiMeanSlope Slope of Nakagami m factor mean
    % NakagamiMeanSlope is the slope (k_m) of the function relating the mean value of the
    % Nakagami m factor with the delay of a multipath component.
    NakagamiMeanSlope

    %NakagamiDeviationOffset Offset of Nakagami m factor variance
    % NakagamiDeviationOffset is the y-intercept value (in dB) of the function relating the
    % standard deviation of the Nakagami m factor with the delay of a
    % multipath component.
    NakagamiDeviationOffset

    %NakagamiDeviationSlope Slope of Nakagami m factor variance
    % NakagamiDeviationSlope is the slope of the function relating the standard deviation of
    % the Nakagami m factor with the delay of a multipath component.
    NakagamiDeviationSlope

    %FirstPathNakagamiMFactor Nakagami m factor of first (strong) component
    % FirstPathNakagamiMFactor is the Nakagami factor (m_0tilde) of the first component of each cluster (which
    % are modeled differently than the rest). This property applies when
    % Environment is 'Open outdoor' or when Environment is 'Industrial' and HasLOS is true.
    FirstPathNakagamiMFactor
  end

  methods
    function obj = environmentConfig(environment, HasLOS, varargin)
%   CFG = environmentConfig(environment, HasLOS, dataType) creates a
%   configuration object for a IEEE 802.15.4a/z UWB Channel Model.
%   environment can be one of 'Residential' | 'Indoor office' | 'Outdoor' |
%   'Open outdoor' | 'Industrial'. HasLOS is a boolean indicating whether a
%   line-of-sight component exists between transmitter and receiver. For
%   'Open outdoor' environments, HasLOS must be true. dataType is either
%   'double' or 'single'.
      arguments
        environment (1,:) char {mustBeMember(environment,{'Residential', 'Indoor office', 'Outdoor', 'Open outdoor', 'Industrial'})}
        HasLOS (1,1) logical
      end
      arguments (Repeating)
        varargin % no varargin validation for codegen
      end
     
      narginchk(2, 3);
      if nargin == 2
        dataType = 'double';
      else
        dataType = validatestring(varargin{1}, {'double', 'single'}, 'lrwpan.uwb.internal.environmentConfig');
      end

      obj.Environment = environment;
      obj.HasLOS = HasLOS;
      
      obj = updateModelParameters(obj, dataType);
    end

    function obj = updateModelParameters(obj, dataType)
      switch obj.Environment
        case 'Residential'
          obj = setupResidentialEnvironment(obj, dataType);
        case 'Indoor office'
          obj = setupIndoorOfficeEnvironment(obj, dataType);
        case 'Outdoor'
          obj = setupOutdoorEnvironment(obj, dataType);
        case 'Open outdoor'
          obj = setupOpenOutdoorEnvironment(obj, dataType);
        case 'Industrial'
          obj = setupIndustrialEnvironment(obj, dataType);
      end
    end

    function obj = setupResidentialEnvironment(obj, dataType)
      % Sec. III.A in [1]
      if obj.HasLOS
        obj.ReferencePathLoss           = cast(43.9, dataType);
        obj.PathLossExponent            = cast(1.79, dataType);
        obj.ShadowingDeviation          = cast(2.22, dataType);
        obj.AntennaLoss                 = cast(3, dataType);
        obj.FrequencyExponent           = cast(1.12, dataType);  % Middle value of suggested range 1.12+/-0.12
        obj.AverageNumClusters          = cast(3, dataType);
        obj.ClusterArrivalRate          = cast(0.047, dataType);
        obj.PathArrivalRate1            = cast(1.54, dataType);
        obj.PathArrivalRate2            = cast(0.15, dataType);
        obj.MixtureProbability          = cast(0.095, dataType);
        obj.ClusterEnergyDecayConstant  = cast(22.61, dataType);
        obj.PathDecaySlope              = cast(0, dataType);
        obj.PathDecayOffset             = cast(12.53, dataType);
        obj.ClusterShadowingDeviation   = cast(2.75, dataType);
        obj.PDPIncreaseFactor           = cast(nan, dataType);
        obj.PDPDecayFactor              = cast(nan, dataType);
        obj.FirstPathAttenuation        = cast(nan, dataType);
        obj.NakagamiMeanOffset          = cast(0.67, dataType);
        obj.NakagamiMeanSlope           = cast(0, dataType);
        obj.NakagamiDeviationOffset     = cast(0.28, dataType);
        obj.NakagamiDeviationSlope      = cast(0, dataType);
        obj.FirstPathNakagamiMFactor    = cast(nan, dataType);
      else % NLOS
        obj.ReferencePathLoss           = cast(48.7, dataType);
        obj.PathLossExponent            = cast(4.58, dataType);
        obj.ShadowingDeviation          = cast(3.51, dataType);
        obj.AntennaLoss                 = cast(3, dataType);
        obj.FrequencyExponent           = cast(1.53, dataType);  % Middle value of suggested range 1.53+/-0.32
        obj.AverageNumClusters          = cast(3.5, dataType);
        obj.ClusterArrivalRate          = cast(0.12, dataType);
        obj.PathArrivalRate1            = cast(1.77, dataType);
        obj.PathArrivalRate2            = cast(0.15, dataType);
        obj.MixtureProbability          = cast(0.045, dataType);
        obj.ClusterEnergyDecayConstant  = cast(26.27, dataType);
        obj.PathDecaySlope              = cast(0, dataType);
        obj.PathDecayOffset             = cast(17.5, dataType);
        obj.ClusterShadowingDeviation   = cast(2.93, dataType);
        obj.PDPIncreaseFactor           = cast(nan, dataType);
        obj.PDPDecayFactor              = cast(nan, dataType);
        obj.FirstPathAttenuation        = cast(nan, dataType);
        obj.NakagamiMeanOffset          = cast(0.69, dataType);
        obj.NakagamiMeanSlope           = cast(0, dataType);
        obj.NakagamiDeviationOffset     = cast(0.32, dataType);
        obj.NakagamiDeviationSlope      = cast(0, dataType);
        obj.FirstPathNakagamiMFactor    = cast(nan, dataType);
      end
    end

    function obj = setupIndoorOfficeEnvironment(obj, dataType)
      % Sec. III.B in [1]
      if obj.HasLOS
        obj.ReferencePathLoss           = cast(35.4, dataType);
        obj.PathLossExponent            = cast(1.63, dataType);
        obj.ShadowingDeviation          = cast(1.9, dataType);
        obj.AntennaLoss                 = cast(3, dataType);
        obj.FrequencyExponent           = cast(0.03, dataType);
        obj.AverageNumClusters          = cast(5.4, dataType);
        obj.ClusterArrivalRate          = cast(0.016, dataType);
        obj.PathArrivalRate1            = cast(0.19, dataType);
        obj.PathArrivalRate2            = cast(2.97, dataType);
        obj.MixtureProbability          = cast(0.0184, dataType);
        obj.ClusterEnergyDecayConstant  = cast(14.6, dataType);
        obj.PathDecaySlope              = cast(0, dataType);
        obj.PathDecayOffset             = cast(6.4, dataType);
        obj.ClusterShadowingDeviation   = cast(nan, dataType);
        obj.PDPIncreaseFactor           = cast(nan, dataType);
        obj.PDPDecayFactor              = cast(nan, dataType);
        obj.FirstPathAttenuation        = cast(nan, dataType);
        obj.NakagamiMeanOffset          = cast(0.42, dataType);
        obj.NakagamiMeanSlope           = cast(0, dataType);
        obj.NakagamiDeviationOffset     = cast(0.31, dataType);
        obj.NakagamiDeviationSlope      = cast(0, dataType);
        obj.FirstPathNakagamiMFactor    = cast(nan, dataType);
      else % NLOS
        obj.ReferencePathLoss           = cast(57.9, dataType);
        obj.PathLossExponent            = cast(3.07, dataType);
        obj.ShadowingDeviation          = cast(3.9, dataType);
        obj.AntennaLoss                 = cast(3, dataType);
        obj.FrequencyExponent           = cast(0.71, dataType);
        obj.AverageNumClusters          = cast(1, dataType);
        obj.ClusterArrivalRate          = cast(nan, dataType);
        obj.PathArrivalRate1            = cast(nan, dataType);
        obj.PathArrivalRate2            = cast(nan, dataType);
        obj.MixtureProbability          = cast(nan, dataType);
        obj.ClusterEnergyDecayConstant  = cast(nan, dataType);
        obj.PathDecaySlope              = cast(nan, dataType);
        obj.PathDecayOffset             = cast(nan, dataType);
        obj.ClusterShadowingDeviation   = cast(nan, dataType);
        obj.PDPIncreaseFactor           = cast(15.21, dataType);
        obj.PDPDecayFactor              = cast(11.84, dataType);
        obj.FirstPathAttenuation        = cast(0.86, dataType);
        obj.NakagamiMeanOffset          = cast(0.5, dataType);
        obj.NakagamiMeanSlope           = cast(0, dataType);
        obj.NakagamiDeviationOffset     = cast(0.25, dataType);
        obj.NakagamiDeviationSlope      = cast(0, dataType);
        obj.FirstPathNakagamiMFactor    = cast(nan, dataType);
      end
    end

    function obj = setupOutdoorEnvironment(obj, dataType)
      % Sec. III.C in [1]
      if obj.HasLOS
        obj.ReferencePathLoss           = cast(45.6, dataType);
        obj.PathLossExponent            = cast(1.76, dataType);
        obj.ShadowingDeviation          = cast(0.83, dataType);
        obj.AntennaLoss                 = cast(3, dataType);
        obj.FrequencyExponent           = cast(0.12, dataType);
        obj.AverageNumClusters          = cast(13.6, dataType);
        obj.ClusterArrivalRate          = cast(0.0048, dataType);
        obj.PathArrivalRate1            = cast(0.27, dataType);
        obj.PathArrivalRate2            = cast(2.41, dataType);
        obj.MixtureProbability          = cast(0.0078, dataType);
        obj.ClusterEnergyDecayConstant  = cast(31.7, dataType);
        obj.PathDecaySlope              = cast(0, dataType);
        obj.PathDecayOffset             = cast(3.7, dataType);
        obj.ClusterShadowingDeviation   = cast(nan, dataType);
        obj.PDPIncreaseFactor           = cast(nan, dataType);
        obj.PDPDecayFactor              = cast(nan, dataType);
        obj.FirstPathAttenuation        = cast(nan, dataType);
        obj.NakagamiMeanOffset          = cast(0.77, dataType);
        obj.NakagamiMeanSlope           = cast(0, dataType);
        obj.NakagamiDeviationOffset     = cast(0.78, dataType);
        obj.NakagamiDeviationSlope      = cast(0, dataType);
        obj.FirstPathNakagamiMFactor    = cast(nan, dataType);
      else % NLOS
        obj.ReferencePathLoss           = cast(73, dataType);
        obj.PathLossExponent            = cast(2.5, dataType);
        obj.ShadowingDeviation          = cast(2, dataType);
        obj.AntennaLoss                 = cast(3, dataType);
        obj.FrequencyExponent           = cast(0.13, dataType);
        obj.AverageNumClusters          = cast(10.5, dataType);
        obj.ClusterArrivalRate          = cast(0.0243, dataType);
        obj.PathArrivalRate1            = cast(0.15, dataType);
        obj.PathArrivalRate2            = cast(1.13, dataType);
        obj.MixtureProbability          = cast(0.062, dataType);
        obj.ClusterEnergyDecayConstant  = cast(104.7, dataType);
        obj.PathDecaySlope              = cast(0, dataType);
        obj.PathDecayOffset             = cast(9.3, dataType);
        obj.ClusterShadowingDeviation   = cast(nan, dataType);
        obj.PDPIncreaseFactor           = cast(nan, dataType);
        obj.PDPDecayFactor              = cast(nan, dataType);
        obj.FirstPathAttenuation        = cast(nan, dataType);
        obj.NakagamiMeanOffset          = cast(0.56, dataType);
        obj.NakagamiMeanSlope           = cast(0, dataType);
        obj.NakagamiDeviationOffset     = cast(0.25, dataType);
        obj.NakagamiDeviationSlope      = cast(0, dataType);
        obj.FirstPathNakagamiMFactor    = cast(nan, dataType);
      end
    end
  
    function obj = setupOpenOutdoorEnvironment(obj, dataType)
      % Sec. III.D in [1]
      coder.internal.errorIf(~obj.HasLOS, 'lrwpan:LRWPAN:OpenOutdoorNLOS');
      
      obj.ReferencePathLoss           = cast(48.96, dataType);
      obj.PathLossExponent            = cast(1.58, dataType);
      obj.ShadowingDeviation          = cast(3.96, dataType);
      obj.AntennaLoss                 = cast(3, dataType);
      obj.FrequencyExponent           = cast(0, dataType);
      obj.AverageNumClusters          = cast(3.31, dataType);
      obj.ClusterArrivalRate          = cast(0.0305, dataType);
      obj.PathArrivalRate1            = cast(0.0225, dataType);
      obj.PathArrivalRate2            = cast(0, dataType);
      obj.MixtureProbability          = cast(1, dataType); % report specifies MixtureProbability=0, but this must be a typo, because with lambda_2=0, that means 0 arrivals
      obj.ClusterEnergyDecayConstant  = cast(56, dataType);
      obj.PathDecaySlope              = cast(0, dataType);
      obj.PathDecayOffset             = cast(0.92, dataType);
      obj.ClusterShadowingDeviation   = cast(nan, dataType);
      obj.PDPIncreaseFactor           = cast(nan, dataType);
      obj.PDPDecayFactor              = cast(nan, dataType);
      obj.FirstPathAttenuation        = cast(nan, dataType);
      obj.NakagamiMeanOffset          = cast(4.1, dataType);
      obj.NakagamiMeanSlope           = cast(0, dataType);
      obj.NakagamiDeviationOffset     = cast(2.5, dataType);
      obj.NakagamiDeviationSlope      = cast(0, dataType);
      obj.FirstPathNakagamiMFactor    = cast(nan, dataType); % report specifies FirstPathNakagami=0, but this must be a typo as Nakagami m must be > 1/2
    end
  
    function obj = setupIndustrialEnvironment(obj, dataType)
      % Sec. III.E in [1]
      if obj.HasLOS
        obj.ReferencePathLoss           = cast(56.7, dataType);
        obj.PathLossExponent            = cast(1.2, dataType);
        obj.ShadowingDeviation          = cast(6, dataType);
        obj.AntennaLoss                 = cast(3, dataType);
        obj.FrequencyExponent           = cast(-1.103, dataType);
        obj.AverageNumClusters          = cast(4.75, dataType);
        obj.ClusterArrivalRate          = cast(0.0709, dataType);
        obj.PathArrivalRate1            = cast(0, dataType);  % Report doesn't define lambdas & MixtureProbability, but are needed for power computation
        obj.PathArrivalRate2            = cast(0, dataType);  % Report doesn't define lambdas & MixtureProbability, but are needed for power computation
        obj.MixtureProbability          = cast(0, dataType);  % Report doesn't define lambdas & MixtureProbability, but are needed for power computation
        obj.ClusterEnergyDecayConstant  = cast(13.47, dataType);
        obj.PathDecaySlope              = cast(0.926, dataType);
        obj.PathDecayOffset             = cast(0.651, dataType);
        obj.ClusterShadowingDeviation   = cast(4.32, dataType);
        obj.PDPIncreaseFactor           = cast(nan, dataType);
        obj.PDPDecayFactor              = cast(nan, dataType);
        obj.FirstPathAttenuation        = cast(nan, dataType);
        obj.NakagamiMeanOffset          = cast(0.36, dataType);
        obj.NakagamiMeanSlope           = cast(0, dataType);
        obj.NakagamiDeviationOffset     = cast(1.13, dataType);
        obj.NakagamiDeviationSlope      = cast(0, dataType);
        obj.FirstPathNakagamiMFactor    = cast(12.99, dataType);
      else % NLOS
        obj.ReferencePathLoss           = cast(56.7, dataType);
        obj.PathLossExponent            = cast(2.15, dataType);
        obj.ShadowingDeviation          = cast(6, dataType);
        obj.AntennaLoss                 = cast(3, dataType);
        obj.FrequencyExponent           = cast(-1.427, dataType);
        obj.AverageNumClusters          = cast(1, dataType);
        obj.ClusterArrivalRate          = cast(nan, dataType);
        obj.PathArrivalRate1            = cast(nan, dataType);
        obj.PathArrivalRate2            = cast(nan, dataType);
        obj.MixtureProbability          = cast(nan, dataType);
        obj.ClusterEnergyDecayConstant  = cast(nan, dataType);
        obj.PathDecaySlope              = cast(nan, dataType);
        obj.PathDecayOffset             = cast(nan, dataType);
        obj.ClusterShadowingDeviation   = cast(nan, dataType);
        obj.PDPIncreaseFactor           = cast(17.35, dataType);
        obj.PDPDecayFactor              = cast(85.36, dataType);
        obj.FirstPathAttenuation        = cast(1, dataType);
        obj.NakagamiMeanOffset          = cast(0.3, dataType);
        obj.NakagamiMeanSlope           = cast(0, dataType);
        obj.NakagamiDeviationOffset     = cast(1.15, dataType);
        obj.NakagamiDeviationSlope      = cast(0, dataType);
        obj.FirstPathNakagamiMFactor    = cast(nan, dataType);
      end
    end
  end


  methods (Access=protected)
    function groups = getPropertyGroups(obj)
      % override, to allow for STS group

      mainGroupNames = {'Environment', 'HasLOS'};

      propagationGroupNames = {'ReferencePathLoss', 'PathLossExponent', 'ShadowingDeviation', ...
                'AntennaLoss', 'FrequencyExponent'};

      pdpGroupNames = {'AverageNumClusters', 'ClusterArrivalRate', 'PathArrivalRate1', 'PathArrivalRate2', ...
        'MixtureProbability', 'ClusterEnergyDecayConstant', 'PathDecaySlope', 'PathDecayOffset', ...
        'ClusterShadowingDeviation', 'PDPIncreaseFactor', 'PDPDecayFactor', 'FirstPathAttenuation'};

      fadingGroupNames = {'NakagamiMeanOffset', 'NakagamiMeanSlope', 'NakagamiDeviationOffset', ...
                'NakagamiDeviationSlope', 'FirstPathNakagamiMFactor'};
      
      groups = [getGroup(mainGroupNames) ...
                getGroup(propagationGroupNames, 'Propagation:') ...
                getGroup(pdpGroupNames, 'Power Delay Profile:'), ...
                getGroup(fadingGroupNames, 'Small-scale fading:')];

      function group = getGroup(groupNames, varargin)
        v = cellfun(@(x) obj.(x), groupNames, 'UniformOutput', false);
        active = cellfun(@(x) ~obj.isInactiveProperty(x), groupNames);
        theseProps = cell2struct(v(active), groupNames(active), 2);
        if nargin == 1
          group = matlab.mixin.util.PropertyGroup(theseProps);
        else
          group = matlab.mixin.util.PropertyGroup(theseProps, varargin{1});
        end
      end
    end


    function flag = isInactiveProperty(obj, prop)
      % Controls the conditional display of properties
      flag = false;
      
      if any(strcmp(prop, {'PDPIncreaseFactor', 'PDPDecayFactor', 'FirstPathAttenuation'}))
        flag = obj.HasLOS || ~any(strcmp(obj.Environment, {'Indoor office', 'Industrial'}));
      end

      if strcmp(prop, 'FirstPathNakagamiMFactor')
        flag = ~(strcmp(obj.Environment, 'Industrial') && obj.HasLOS);
      end

      if strcmp(prop, 'ClusterShadowingDeviation')
        flag = ~((strcmp(obj.Environment, 'Industrial') && obj.HasLOS) || strcmp(obj.Environment, 'Residential'));
      end

      if any(strcmp(prop, {'PathArrivalRate1', 'PathArrivalRate2', 'MixtureProbability'}))
        flag = (strcmp(obj.Environment, 'Indoor office') && ~obj.HasLOS) || strcmp(obj.Environment, 'Industrial');
      end

      if any(strcmp(prop, {'ClusterArrivalRate', 'ClusterEnergyDecayConstant', 'PathDecaySlope', 'PathDecayOffset'}))
        flag =  ~obj.HasLOS && any(strcmp(obj.Environment, {'Indoor office', 'Industrial'}));
      end

      if strcmp(prop, 'FrequencyExponent')
        flag =  strcmp(obj.Environment, 'Open outdoor');
      end
    end
  end
end

