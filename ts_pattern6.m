function [connected_times, connected_indices, pattern_times, errors_per_column, error_average] = ts_pattern6(data, periods, pattern, max_deviation)
% TS_PATTERN6(data, pattern, max_deviation)
% data is an MxN matrix representing N timeseries
% pattern is an vector of length N representing a pattern to fit to the data
% This version tries with patterns centered on every line (time), on the first column (segment).
% This version gives the average error per segment.
% This version tests on the phase lag between consecutive segments.
% This version requires the maximum deviation to be provided. Using a mean for period estimation was not reliable.
% This version return pattern_times anchored on the connected_times' first elements
% This version returns the connected indices (original column indices in data)
% This version takes a normalized pattern on (0, 2*pi) and scales it to the local period.
% It takes periods as parameters, and only a scalar for max_deviation, which will be multiplied by the period.
% This version takes segment timeseries as rows (first row = first segment)
    
    [n_lines, n_cols] = size(data);
    
    if length(pattern) ~= n_lines || ~isvector(pattern)
        disp(['size(data): ', num2str(size(data))])
        disp(['pattern: ', num2str(pattern)]);
        error('Pattern should be a vector of length == size(data, 1).');
    end
    
    if n_cols == 0
        connected_times = zeros(n_lines, 0);
        pattern_times = zeros(n_lines, 0);
        errors_per_column = [];
        error_average = [];
    end
    
    % make sure we have a column vector
    pattern = pattern(:);
    
    % pattern phase lags
    dpattern = diff(pattern);

    % Keep track of "connected" times
    % We start with all the columns in data's top row, but connected times can 
    % on subsequent lines jump to other columns of data to find the best fit
    connected_times(1, :) = data(1, :);
    connected_indices(1, 1:n_cols) = 1:n_cols;
    pattern_times = connected_times;
    
    for i=2:n_lines
        for j=1:n_cols
            
            prev_col = connected_indices(i - 1, j);
            
            if isnan(prev_col)
                dev_min = nan;
            else
                % calculate lags from the last connected time j to any column of the next line
                line_lags = data(i, :) - connected_times(i - 1, j);
                
                % compare with the corresponding lag in the pattern
                pattern_lag = dpattern(i - 1) / (2 * pi) * periods(i - 1, prev_col);
                deviations = line_lags - pattern_lag;
                             
                % find best column to connect to
                [dev_min, dev_min_index] = min(abs(deviations));
            end
            
            % in case of too big deviations, we don't connect
            if ~isnan(dev_min) && dev_min < max_deviation * periods(i - 1, prev_col)
                connected_times(i, j) = data(i, dev_min_index);
                connected_indices(i, j) = dev_min_index;
                pattern_times(i, j) = pattern_times(i - 1, j) + pattern_lag;
            else
                connected_times(i, j) = NaN;
                connected_indices(i, j) = NaN;
                pattern_times(i, j) = NaN;
            end
        end
    end
    
    % Calculate error per column as the average per segment deviation
    errors = abs(connected_times - pattern_times);
    errors_per_column = mean(errors, 1);
    
    % For the overall average error, ignore columns with NaNs
    error_average = nanmean(errors_per_column);
    if isnan(error_average)
        error_average = Inf;
    end
