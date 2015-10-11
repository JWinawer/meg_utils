function [condition_names, baseline_condition] = gamma_get_condition_names(session_number)
% [condition_names, baseline_condition] = ...
%       gamma_get_condition_names(session_number)
%
% Condition names for MEG Gamma experiment
%
% Inputs: 
%   subject: integer, 1-n
% Outputs:
%  condition_names: cell array of condition names
%
% Example: condition_names = gamma_get_condition_names(1)
%

% TODO fix for session_number <= 3

condition_names               = {   ...
    'White Noise' ...
    'Binary White Noise' ...
    'Pink Noise' ...
    'Brown Noise' ...
    'Gratings(0.36 cpd)' ...
    'Gratings(0.73 cpd)' ...
    'Gratings(1.45 cpd)' ...
    'Gratings(2.90 cpd)' ...
    'Plaid'...
    'Blank'};

if session_number >= 9
    condition_names{3} = 'Binary Pink Noise';
    condition_names{4} = 'Binary Brown Noise';
end

baseline_condition = find(~cellfun(@isempty,strfind(condition_names, 'Blank')));

return
