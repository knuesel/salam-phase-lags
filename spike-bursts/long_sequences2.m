function out = long_sequences2(file, varargin)

    p = inputParser;
    p.addParamValue('Side', 'ipsi');
    p.addParamValue('Smooth', 0.001);
    p.addParamValue('Threshold', nan);
    p.addParamValue('TimeRange', []);
    p.addParamValue('VentralRoots', []);
    p.addParamValue('BurstReference', 'com');
    p.addParamValue('PlotTimeWindow', 100);
    p.addParamValue('Basefile', file);
    p.addParamValue('Plot', true);
    p.addParamValue('Pdf', true);
    p.addParamValue('SamplingFreq', 50); % Hz

    p.parse(varargin{:});

    plotting = p.Results.Plot;

    channels = load_jm_data(file, p.Results.Side, p.Results.VentralRoots);
    disp(['Channels: ' num2str([channels.position])]);
    
    if plotting
        prepare_figures(1:8, 14);
    end

    % Determine time range
    min_time = 0;
    max_time = 0;
    for i = 1:length(channels)
        max_time = max(max_time, channels(i).length * channels(i).interval);
    end
    if ~isempty(p.Results.TimeRange)
        min_time = p.Results.TimeRange(1);
        max_time = min(max_time, p.Results.TimeRange(2));
    end
    
    spline_times = (min_time:(1 / p.Results.SamplingFreq):max_time)';

    smoothing = p.Results.Smooth;
    if length(smoothing) == 1
        smoothing = repmat(smoothing, length(channels), 1);
    end
    
    if isempty(p.Results.Threshold)
        threshold = nan(length(channels), 1);
    elseif length(p.Results.Threshold) == 1
        threshold = repmat(p.Results.Threshold, length(channels), 1);
    else
        threshold = p.Results.Threshold;
    end
    
    for i = 1:length(channels)
        
        t = [1:channels(i).length] * channels(i).interval;
        t_flags = t >= min_time & t <= max_time;
        
        if plotting
            figure(1)
            subplot(length(channels), 1, i);
        end

        % Spline timeseries
        [spline_heights, start, stop, com_x, com_y, surfaces] = spline_com2(t(t_flags), abs(channels(i).values(t_flags)), spline_times, smoothing(i), threshold(i), plotting);
        
        if plotting
            ylabel(['VR ' num2str(channels(i).position)]);
            if i == length(channels)
                xlabel('Time [s]');
            end
        end
        
        spline_data(1:length(spline_heights), i) = spline_heights;
        coms(1:length(com_x), i) = com_x;
        start_indices(1:length(start), i) = start;
        stop_indices(1:length(stop), i) = stop;
        onsets(1:length(start), i) = spline_times(start);
        offsets(1:length(stop), i) = spline_times(stop);
    end
    
    if strcmp(p.Results.BurstReference, 'com')
        burst_times = coms;
    else
        burst_times = onsets;
    end
    
    burst_times(~burst_times) = nan;
    start_indices(~start_indices) = nan;
    stop_indices(~stop_indices) = nan;
    onsets(~onsets) = nan;
    offsets(~offsets) = nan;
    coms(~coms) = nan;

    [periods lags data burst_durations] = periods_and_lags(onsets, burst_times, offsets, zeros(length(channels), 1), 1);
    periods = periods';
    lags = lags';
    if isempty(lags)
        intersegmental_lags = zeros(size(lags)); % because e.g. repmat([], 10, 0) gives [] instead of zeros(10, 0)
    else
        intersegmental_lags = lags ./ repmat(diff([channels.position]), size(lags, 1), 1);
    end
    data.start_indices = start_indices;
    data.stop_indices = stop_indices;
    data.pattern_joints = 1:length(channels);
    lag_avg = mean(intersegmental_lags(:));
    lag_std = std(intersegmental_lags(:));
    
    duty_cycles = burst_durations ./ periods;

    out.file = file;
    out.ventral_roots = [channels.position];
    out.periods = periods;
    out.lags = lags;
    out.intersegmental_lags = intersegmental_lags;
    out.coms = coms;
    out.onsets = onsets;
    out.offsets = offsets;
    out.burst_times = burst_times;
    out.median_period = nanmedian(periods);
    out.median_lag = nanmedian(intersegmental_lags);
    out.duty_cycles = duty_cycles;
    
    if ~plotting || true
        return
    end

    % Period timeseries
    figure(2)
    plot_timeseries_median(burst_times, periods, 'Cycle period [s]', @(i) ['VR ' num2str(channels(i).position)], 'ylim', [0 20]);
    
    % Phase lag timeseries
    figure(3)
    plot_timeseries_median(data.series(1:end - 1, :)', intersegmental_lags * 100, 'Intersegmental phase lag [%]', ...
                           @(i) ['VR ' num2str(channels(i).position) '-' num2str(channels(i + 1).position)], 'ylim', [-20 20]);
    
    % Pattern timeseries
    figure(4);
    rows = size(spline_data, 1);
    plot_data = spline_data - repmat(min(spline_data), rows, 1);
    ampl = repmat(max(plot_data), rows, 1);
    % avg = repmat(mean(plot_data), rows, 1);
    plot_data = plot_data ./ ampl * 2;
    plot_phase_patterns(spline_times, plot_data, 'JointPositions', [channels.position], 'Pos', data);
    ylimit = ylim;
    ylimit(2) = ylimit(2) - 1.5;
    set(gca, 'yticklabel', [channels.position], 'ylim', ylimit);
    ylabel('VR');
    title('Neighboring burst selection (for phase lags)');

    % Original lag timeseries
    figure(5)
    plot_timeseries_median(data.series(1:end - 1, :)', lags * 100, 'Phase lag [%]', ...
                           @(i) ['VR ' num2str(channels(i).position) '-' num2str(channels(i + 1).position)], 'ylim', [-50 50]);
    
    % Duty cycles
    figure(6)
    plot_timeseries_median(burst_times, duty_cycles * 100, 'Duty cycle [%]', ...
                           @(i) ['VR ' num2str(channels(i).position)], 'ylim', [0 100]);
    
    % Phase lag histograms
    figure(7)
    for i = 1:length(channels) - 1
        subplot(length(channels) - 1, 1, i);
        hist(intersegmental_lags(:, i) * 100, -20:20);
        ylabel(['VR ' num2str(channels(i).position) '-' num2str(channels(i + 1).position)]);
        xlim([-22 22]);
    
        if i == 1
            title('Intersegmental phase lag [%]');
        end
    end
    
    
    % Period histograms
    figure(8)
    for i = 1:length(channels)
        subplot(length(channels), 1, i);
        hist(periods(:, i), 0:0.5:25);
        ylabel(['VR ' num2str(channels(i).position)]);
        xlim([0 32]);
        
        if i == 1
            title('Period [s]');
        end
    end

    if p.Results.Pdf
        basefile = p.Results.Basefile;
        time_range = [min_time max_time];
        deltat = p.Results.PlotTimeWindow;
        make_pdf(1, time_range, deltat, [basefile '_fit']);
        make_pdf(2, time_range, -1, [basefile '_period']);
        make_pdf(3, time_range, -1, [basefile '_intersegmental_lag']);
        make_pdf(4, time_range, deltat, [basefile '_pattern']);
        make_pdf(5, time_range, -1, [basefile '_lag']);
        make_pdf(6, time_range, -1, [basefile '_duty_cycle']);
        make_pdf(7, time_range, -1, [basefile '_intersegmental_lag_hist']);
        make_pdf(8, time_range, -1, [basefile '_period_hist']);
    end
    
function plot_timeseries_median(x, y, title_str, ylabel_callback, varargin)
    n = size(x, 2);
    
    for i = 1:n
        y_median = nanmedian(y(:, i));
        
        subplot(n, 1, i);
        plot(x(:, i), y(:, i), 'ok', 'markersize', 8, 'linewidth', 2);
        hline(0, ':k');
        h = hline(y_median, '-k');
        legend(h, ['Median ' num2str(y_median)]);
        
        if i == 1
            title(title_str);
        end
        
        ylabel(ylabel_callback(i));
        set(gca, varargin{:});
    end
    xlabel('Time [s]');
