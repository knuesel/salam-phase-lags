function handles = plot_timeseries_stack(t, ydata, ypositions, yticklabels, colors, varargin)
    [n_times n_series] = size(ydata);
    ydata = -ydata + ones(n_times, 1) * ypositions;
    handles = plot(t, ydata, varargin{:});
    ystep = min(diff(ypositions));

    if ~isempty(colors)
        for i = 1:length(handles)
            set(handles(i), 'color', colors{i})
        end
    end
    
    if isempty(ystep)
        ystep = range(ydata);
    end
        
    ylims = [ypositions(1) - 0.9 * ystep, ypositions(end) + 0.9 * ystep];

    set(gca, 'ytick', ypositions, 'yticklabel', yticklabels, 'ylim', ylims, 'ydir', 'reverse');
