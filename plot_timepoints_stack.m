function handles = plot_timepoints_stack(times, ypositions, yticklabels, varargin)
    
    if ~isempty(times(~isnan(times)))
        n_series = size(times, 2);
        handles = plot(times', ypositions', varargin{:});
        ystep = min(diff(ypositions));
        
        if yticklabels
            set(gca, 'ytick', ypositions, 'yticklabel', yticklabels, 'ydir', 'reverse', 'ylim', [ypositions(1) - 0.9 * ystep, ypositions(end) + 0.9 * ystep]);
        end
    else
        handles = [];
    end
