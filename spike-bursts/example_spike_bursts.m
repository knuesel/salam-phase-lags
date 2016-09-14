    % Load spike data from .mat file exported by Spike2, keeping channels with
    % names corresponding to "ipsilateral" ventral roots. The last argument
    % specifies the ventral roots to keep (empty means keep all).
    channels = load_spike2_data('17020602_temoin2RC', 'ipsi', []);

    % Print the channel positions loaded from the .mat file
    disp(['Channels loaded: ' num2str([channels.position])]);
    

    % Process data between t=400s and t=600s using a smoothing param of 0.001
    % and generate all the plots. See documentation of 'csaps' function for
    % meaning of the smoothing parameter. Basically for spike data the
    % parameter must be set close to 0, while for oscillations it must be set
    % close 1.

    result = long_sequences2(channels, 'Smooth', 0.001, 'TimeRange', [400 600]);


    % Same as before, but use different smoothing params for both channels and
    % show only the 'data' plot.  See how the first channel has a red curve
    % following the green curve more closely (the green curve is not used for
    % analysis, it shows the result of a simple moving-average filter and is
    % added to the plot for reference).

    % result = long_sequences2(channels, 'Smooth', [0.01 0.001], 'TimeRange', [400 600], 'Plot', 'data');


    % The following would generate the 'data' plot and save the result to PDF
    % files named switch_xxx.pdf (one file per 200-seconds interval of data,
    % which will be only one file given our [400 600] time range).

    % result = long_sequences2(channels, 'Smooth', 0.001, 'TimeRange', [400 600], 'Plot', 'data', 'Pdf', true, 'PdfPrefix', 'switch', 'PlotTimeWindow', 200);
