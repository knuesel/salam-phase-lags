function [spline_heights, start_indices, stop_indices, com_x, com_y, surfaces] = spline_com2(t, data, spline_times, smoothing, threshold, plotting)

    spline2 = csaps(t, data, smoothing);
    spline_heights = fnval(spline2, spline_times);
    
    [mins maxs peak_to_peak threshold] = filter_min_max(spline_times, spline_heights, threshold);
    [start_indices stop_indices] = burst_start_stop(spline_times, spline_heights, mins, maxs);
    
    [com_x com_y surfaces] = get_centroid(spline_times, spline_heights, start_indices, stop_indices);
    
    if ~plotting
        return
    end
    
    ymax = 1.2 * max(spline_heights);
    for cycle = 1:length(start_indices)
        start = start_indices(cycle);
        stop = stop_indices(cycle);

        patch('xdata', spline_times([start start stop stop]), 'ydata', [0 ymax ymax 0], 'edgecolor', 'none', 'facecolor', [.9 .9 .9]);
        % patch('xdata', spline_times([start start stop stop]), 'ydata', peak_to_peak([1 2 2 1]), 'edgecolor', 'none', 'facecolor', [.8 .8 .8]);
        patch('xdata', spline_times(start:stop), 'ydata', spline_heights(start:stop), 'edgecolor', 'none', 'facecolor', [.9 .75 .75]);
    end
    
    hold on
    
    % RAW DATA
    plot(t(1:10:end), data(1:10:end) / 10, 'k');
    
    % SMOOTHED DATA
    smoothed = smooth(data, 1000);
    plot(t(1:10:end), smoothed(1:10:end), 'color', [0 .6 0], 'linewidth', 1.5);
    
    % SPLINE DATA
    plot(spline_times, spline_heights, 'color', [.6 0 0], 'linewidth', 2)
    
    % CENTERS OF MASS
    plot(com_x, com_y, 'o', 'color', [.6 0 0], 'markerfacecolor', [.6 0 0], 'markersize', 5);
    
    hold off
    
    ylim([0 ymax]);
