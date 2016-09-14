function [start_indices stop_indices] = burst_start_stop(times, values, mins, maxs)

    for i = 1:length(mins.indices) - 1
        p1 = [mins.times(i); mins.values(i)];
        p2 = [maxs.times(i); maxs.values(i)];
        
        rot = planerot(p2 - p1);
        arc_times = times(mins.indices(i):maxs.indices(i));
        arc_values = values(mins.indices(i):maxs.indices(i));

        rotated = rot * [arc_times arc_values]';
        
        % [~, peak_start_index] = min(rotated(2, :));
        [~, indices] = local_minima(rotated(2, :));
        peak_start_index = indices(1);
        
        start_indices(i) = mins.indices(i) + peak_start_index - 1;
        
        p1 = [maxs.times(i); maxs.values(i)];
        p2 = [mins.times(i + 1); mins.values(i + 1)];
        
        rot = planerot(p2 - p1);
        arc_times = times(maxs.indices(i):mins.indices(i + 1));
        arc_values = values(maxs.indices(i):mins.indices(i + 1));
        
        rotated = rot * [arc_times arc_values]';

        % [~, peak_stop_index] = min(rotated(2, :));
        [~, indices] = local_minima(rotated(2, :));
        peak_stop_index = indices(end);
        
        stop_indices(i) = maxs.indices(i) + peak_stop_index - 1;
    end
    