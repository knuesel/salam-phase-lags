function [periods lags data burst_durations] = periods_and_lags(onsets, burst_times, offsets, pattern, threshold, varargin)
% Returns lags as a fraction of the cycle
    
    p = inputParser;
    p.addParamValue('AssumeDF50', false); % Set to true to calculate the period based only on the burst duration (not silences)
    p.parse(varargin{:});
    
    if size(onsets, 1) < 2
        periods = [];
        lags = [];
        data.series = [];
        data.series_indices = [];
        return
    end
    
    % Silence for each burst, calculated as the average of the left and right silences
    % (for the first (respectively last) burst we use twice the right (left) silence).
    silence_right = onsets(2:end, :) - offsets(1:end - 1, :);
    silence_left = silence_right([1 1:end], :);
    silence_right(end + 1, :) = silence_right(end, :);
    
    % replicate last silence of shorter timeseries
    for i = 1:size(silence_right, 2)
        first_missing = find(isnan(silence_right(:, i)), 1);

        if ~isempty(first_missing) && first_missing > 1
            silence_right(first_missing, i) = silence_right(first_missing - 1, i);
        end
    end
    
    silences = 0.5 * (silence_left + silence_right);
    
    burst_durations = offsets - onsets;

    if p.Results.AssumeDF50
        periods = burst_durations * 2;
    else
        periods = silences + burst_durations;
    end
    period_avg = nanmean(periods(:));
    period_std = nanstd(periods(:));
    period = nanmedian(periods(:));
    
    [data.series data.series_indices data.patterns] = ts_pattern6(burst_times', periods(:, 1:end - 1)', pattern, threshold);

    for i = 1:size(data.series, 1)
        ok = ~isnan(data.series_indices(i, :));
        connected_periods(i, ok) = periods(data.series_indices(i, ok), i);
    end
    connected_periods(connected_periods == 0) = nan;
    
    lags = diff(data.series, 1, 1);
    lag_periods = 0.5 * (connected_periods(1:end - 1, :) + connected_periods(2:end, :));
    lags = lags ./ lag_periods;
    
    lags;
    lag_periods;

    periods = periods';
