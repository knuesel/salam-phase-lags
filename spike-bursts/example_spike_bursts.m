    % Load spike data from .mat file exported by Spike2, keeping channels with
    % names corresponding to "ipsilateral" ventral roots. The last argument
    % specifies the ventral roots to keep (empty means keep all).
    channels = load_spike2_data('17020602_temoin2RC', 'ipsi', []);

    % Print the channel positions loaded from the .mat file
    disp(['Channels: ' num2str([channels.position])]);
    
    result = long_sequences2(channels, 'Smooth', [0.001 0.001], 'TimeRange', [400 600], 'PlotName', 'switch', 'PlotTimeWindow', 200);
