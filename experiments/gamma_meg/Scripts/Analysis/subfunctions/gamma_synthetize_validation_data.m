function [sensorData, conditions] = gamma_synthetize_validation_data()
% Create synthetic data set for validation of MEG denoisedata pipeline

%% specify simulation parameters

fs              = 1000;  % sampling frequency, Hz
epoch_length    = 1;     % seconds

num_channels    = 157;
num_repeats     = 10;    % num epochs per condition



num_noise_basis                 = 10; % number of independent bases for correlated noise
response_amp.uncorrelated_noise = 20;
response_amp.correlated_noise   = 20;
response_amp.erf                = 50; % if this is too small, then we might not be able to find the right noise pool
response_amp.gamma              = 1;
response_amp.broadband          = 2;




% --------- derived -------------------------
condition_names     = gamma_get_condition_names(99);
num_conditions      = numel(condition_names); % 
condition_codes     = 1:num_conditions; % arbitrary codes assigned to conditions

blank_condition     = find(~cellfun(@isempty, strfind(condition_names, 'Blank')));
noise_conditions    = find(~cellfun(@isempty, strfind(condition_names, 'Noise')));
grating_conditions  = setdiff(condition_codes, [blank_condition noise_conditions]);

samples_per_epoch   = epoch_length * fs;
conditions          = reshape(ones(num_repeats,1)*condition_codes, [], 1);
num_epochs          = size(conditions,1);
%% Group channels for noisepool (front), visual (back)
load('meg160xyz');

% find the 90 channels in front (highest x value): these will be noise pool
[~, sort_y] = sort(xyz(:,1), 'descend');
channels.noisepool = sort_y(1:90); 

% the rest will be visual
channels.visual = sort_y(91:end);

% % check it
% map = zeros(1, 157);
% map(channels.noisepool) = 1;
% map(channels.visual) = 2;
% 
% ft_plotOnMesh(map, [],[],[],'interpolation', 'nearest')

%% generate noiseless time series
sensorData      = zeros(samples_per_epoch, num_epochs, num_channels);
noise_epochs    = ismember(conditions, noise_conditions);
grating_epochs  = ismember(conditions, grating_conditions);
stim_epochs     = noise_epochs | grating_epochs;

t = (1:1000)/fs;
% ------------------------ERF --------------------------------
%
% for stimulus epochs, fill the visual sensors with erf time series

for ii = channels.visual'
    % make an example evoked signal
    tau = rand*0.06+0.17; % peak of evoked response is, say, between 170 and 230 ms
    erf = t .* exp(-t /tau) / max(t .* exp(-t /tau));        
    sensorData(:,noise_epochs, ii) = ...
        response_amp.erf * repmat(erf, sum(noise_epochs),1)';
    
    sensorData(:,grating_epochs, ii) = ...
        2*response_amp.erf * repmat(erf, sum(grating_epochs),1)';    
end

% ------------------------GAMMA --------------------------------
%
% for grating epochs, fill the visual sensors with gamma time series


gamma_filter = designfilt('bandpassiir','FilterOrder',10, ...
    'HalfPowerFrequency1', 40,'HalfPowerFrequency2', 60,...
    'SampleRate',fs,'DesignMethod','butter');

% make gamma response
gamma = randn(size(sensorData(:,grating_epochs,channels.visual)));
gamma = filter(gamma_filter, gamma);
gamma = gamma / var(gamma(:));

sensorData(:,grating_epochs, channels.visual) = ...
    sensorData(:,grating_epochs, channels.visual) + ...
     response_amp.gamma * gamma;

% ------------------------BROADBAND  --------------------------------
% 
% for stimulus epochs, fill the visual sensors with broadband time series
sensorData(:,stim_epochs, channels.visual) = ...
    sensorData(:,stim_epochs, channels.visual) + ...
    response_amp.broadband * zscore(randn(size(sensorData(:,stim_epochs, channels.visual))));

% ------------------------Uncorrelated Noise  ----------------------------
% add white noise to all channels, all conditions
sensorData = sensorData + ...
    response_amp.uncorrelated_noise * zscore(randn(samples_per_epoch, num_epochs, num_channels));

% ------------------------Correlated Noise  ----------------------------
% 

correlated_basis = randn(samples_per_epoch * num_epochs, num_noise_basis);
mixing_matrix    = randn(num_noise_basis, num_channels);
mixing_matrix    = bsxfun(@rdivide, mixing_matrix, sqrt(sum(mixing_matrix.^2)));
correlated_noise = correlated_basis * mixing_matrix;
correlated_noise = reshape(correlated_noise, samples_per_epoch, num_epochs, num_channels);

sensorData       = sensorData + correlated_noise * response_amp.correlated_noise;
    
