% advanced_usage_example.m
% Example script demonstrating advanced usage of the MATLAB App

% Load the MATLAB App
app = app1;

% Set filter type and cutoff frequency
app.FilterTypeDropDown.Value = 'highpass';
app.CutFrequencyEditField.Value = 15;

% Customize additional settings
% ...

% Start data acquisition
app.StartStopButtonPushed();