function [ts, conditions] = eeg_make_epochs(raw_ts, trigger, epoch_time, fs, interspace_trig)
% Slice time series matrix (samples x channels) into 3D epoched array
% (samples x epoch x channel) based on trigger times.
%
%[ts, conditions] = meg_make_epochs(raw_ts, trigger, epoch_time, fs)
%
% Inputs
%   raw_ts:       time series matrix (samples x channels)
%   trigger:      a vector of stimulus onsets equal in length to first
%                   dimension of raw_ts. Should be all zeros except an
%                   integer to indicate trial onset. These integer values
%                   correspond to the condition number.
%   epoch_time:   a 2 vector of start and end time of the epochs 
%                   (in seconds) relative to the trial onset
%   fs:           sampling rate (Hz)
%   
%   blank_trig:   the MEG trigger value which corresponds to the interspace
%   (optional)       between stimuli images (default: max(trigger))
%
% Outputs
%   ts:           3D array containing epoched time series (samples by
%                   epoch x channel)
%   conditions:   vector equal in length to the number of epochs. each
%                   entry is the condition number (trigger value) for that
%                   epoch

%% Parameters
if nargin>5
    trigger(trigger == interspace_trig) = 0; % remove the triggers corresponding to the interspace images
else
    % do nothing for now
    % interspace_trig = max(trigger);
    
end


onsets = find(trigger);

epoch_samples = round(epoch_time); %epoch length in samples
epoch_len     = diff(epoch_samples);    %epoch length in samples
num_channels  = size(raw_ts, 2);
num_epochs    = length(onsets);

ts            = zeros(num_epochs, epoch_len, num_channels);

for ii = 1:num_epochs
    inds = onsets(ii):onsets(ii)+(epoch_len-1);
    ts(ii, :, :) = raw_ts(inds,:);    
end

ts         = permute(ts, [2 1 3]);
conditions = trigger(onsets);

return
