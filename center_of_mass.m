function [com_x, com_y, surfaces] = center_of_mass(times, values, start_indices, stop_indices)
    
    if min(size(values)) == 1
        start_indices = start_indices(:);
        stop_indices = stop_indices(:);
        values = values(:);
    end

    [n_cycles n_series] = size(start_indices);
    
    com_x = zeros(n_cycles, n_series);
    com_y = zeros(n_cycles, n_series);
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
            
            com_sum = sum(magnitudes .* times_cycle);

            if sum(magnitudes) == 0
                com_x(cycle, column) = mean(times_cycle);
            else
                com_x(cycle, column) = com_sum / sum(magnitudes);
            end

            % maybe wrong: I think we should just do 0.5 * sum(magnitudes) / length(magnitudes) + a*x + b
            com_y(cycle, column) = com_sum * 0.5 / sum(times_cycle) + a * com_x(cycle, column) + b;

            surfaces(cycle, column) = diff(times_cycle)' * magnitudes(2:end);
            
            % hold on
            % plot(times_cycle, baseline, 'r');
            % plot(com_x, com_y, 'or', 'markersize', 3);
            % hold off
        end
    end
