function [centroid_x, centroid_y, surfaces] = get_centroid(times, values, start_indices, stop_indices)
    
    if min(size(values)) == 1
        start_indices = start_indices(:);
        stop_indices = stop_indices(:);
        values = values(:);
    end

    [n_cycles n_series] = size(start_indices);
    
    centroid_x = zeros(n_cycles, n_series);
    centroid_y = zeros(n_cycles, n_series);
    surfaces = zeros(n_cycles, n_series);
    
    for column = 1:n_series
        for cycle = 1:n_cycles
            start = start_indices(cycle, column);
            stop = stop_indices(cycle, column);
            times_cycle = times(start:stop);

            % line connecting the start and end points
            a = (values(stop, column) - values(start, column)) / (times(stop, column) - times(start, column));
            b = values(start, column) - a * times(start, column);
            baseline = a * times_cycle + b;
            
            magnitudes = values(start:stop, column) - baseline;
            
            centroid_sum = sum(magnitudes .* times_cycle);

            if sum(magnitudes) == 0
                centroid_x(cycle, column) = mean(times_cycle);
            else
                centroid_x(cycle, column) = centroid_sum / sum(magnitudes);
            end

            % maybe wrong: I think we should just do 0.5 * sum(magnitudes) / length(magnitudes) + a*x + b
            centroid_y(cycle, column) = centroid_sum * 0.5 / sum(times_cycle) + a * centroid_x(cycle, column) + b;

            surfaces(cycle, column) = diff(times_cycle)' * magnitudes(2:end);
            
            % hold on
            % plot(times_cycle, baseline, 'r');
            % plot(centroid_x, centroid_y, 'or', 'markersize', 3);
            % hold off
        end
    end
