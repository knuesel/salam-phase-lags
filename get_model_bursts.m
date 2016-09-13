function [onsets centroids offsets start_indices stop_indices] = get_model_bursts(t, x, varargin)
% This function takes smooth timeseries as generated by a CPG model and
% returns burst timing information as would be extracted from in vitro data
% This code work with matrices, not just one timeseries. The in vitro code works on one timeseries
% and expects long signals with lots of cycles.
    
    p = inputParser;
    p.addParamValue('SpikeThreshold', 0.1); % specifies the smallest fraction of the median period that is still accepted as a burst
    p.parse(varargin{:});

    % not shifting data by mean value, as it would introduce a significant bias when the number of cycles is not very large
        
    [n_rows n_cols] = size(x);
    
    % [crossings_up flags_ascending] = get_crossings3(t, x, 'Center', false, 'Direction', 'ascending');
    % [crossings_down flags_descending] = get_crossings3(t, x, 'Center', false, 'Direction', 'descending');

    % First estimate of crossings
    flags_ascending = x(1:end - 1, :) < 0 & x(2:end, :) >= 0;
    flags_descending = x(1:end - 1, :) > 0 & x(2:end, :) <= 0;
    
    % Calculate typical period in units of timesteps
    diffs = [];
    for i = 1:n_cols
        diffs = [diffs; diff(find(flags_ascending)); diff(find(flags_descending))];
    end
    median_diff = nanmedian(diffs);
    
    
    for i = 1:n_cols
        % Remove wrong crossings (zero reached but not crossed)
        before_first_zeros = find(x(1:end - 1, i) ~= 0 & x(2:end, i) == 0);
        for j = before_first_zeros'
            first_nonzero = find(x(j + 1:end - 1, i) ~= 0, 1);
            if ~isempty(first_nonzero)
                if x(j + first_nonzero, i) < 0
                    flags_ascending(j, i) = false;
                else
                    flags_descending(j, i) = false;
                end
            end
        end

        % for each series, make sure we start with an onset and stop with an offset
        first_descending = find(flags_descending(:, i), 1);
        last_ascending = find(flags_ascending(:, i), 1, 'last');
        
        if find(flags_ascending(:, i), 1) > first_descending
            flags_descending(first_descending, i) = false;
        end
        
        if find(flags_descending(:, i), 1, 'last') < last_ascending
            flags_ascending(last_ascending, i) = false;
        end

        start = find(flags_ascending(:, i));
        stop = find(flags_descending(:, i));
        
        if isempty(stop)
            start = [];
            stop = [];                  % make sure it's 0x0, not 0x1
        end
        
        too_short = (stop - start) < median_diff * p.Results.SpikeThreshold;
        start(too_short) = [];
        stop(too_short) = [];
        
        start_indices(1:length(start), i) = start;
        stop_indices(1:length(stop), i) = stop;
        onsets(1:length(start), i) = t(start);
        offsets(1:length(stop), i) = t(stop);
        
        [centroid_x centroid_y surfaces] = get_centroid(t, max(0, x(:, i)), start, stop);
        centroids(1:length(centroid_x), i) = centroid_x;
    end
    
    start_indices(~start_indices) = nan;
    stop_indices(~stop_indices) = nan;
    onsets(~onsets) = nan;
    offsets(~offsets) = nan;
    centroids(~centroids) = nan;
