function [outMin outMax peak_to_peak threshold] = filter_min_max(times, values, threshold)
    
    times = times(:);
    values = values(:);
    
    min_flags = values(1:end - 2) >  values(2:end - 1) & values(2:end - 1) <= values(3:end);
    max_flags = values(1:end - 2) <  values(2:end - 1) & values(2:end - 1) >= values(3:end);
    
    peak_to_peak = quantile(values, [0.0001 0.9999]);
    
    if isnan(threshold)
        threshold = diff(peak_to_peak) * 0.1;
    end
    
    Min = extreme_struct(times, values, min_flags);
    Max = extreme_struct(times, values, max_flags);
    
    MIN = 1;
    MAX = 2;

    extrema(1:Min.n, 1) = Min.i;
    extrema(1:Min.n, 2) = MIN;

    extrema(Min.n + 1:Min.n + Max.n, 1) = Max.i;
    extrema(Min.n + 1:Min.n + Max.n, 2) = MAX;

    extrema = sortrows(extrema);
    
    if any(extrema(:, 1:end - 1) == extrema(:, 2:end))
        error('Non-alternating extrema');
    end

    out = struct('start', {}, 'stop', {}, 'max', {});
    
    for i = 1:size(extrema, 1)
        ind = extrema(i, 1);
        
        if extrema(i, 2) == MIN
            
            % We're at a Min. 
            
            % If we have a Max candidate, the Min could be used as a better Min.stop candidate.
            if ~isempty(Max.staged)
            
                % Better Min.stop candidate?
                if values(Max.staged) - values(ind) > threshold && (isempty(Min.stop) || values(ind) < values(Min.stop))
                    Min.stop = ind;
                end
            
            % Otherwise it could be a better Min.start candidate for the first burst. (Except for the first burst, Min.start is always the
            % Min.stop of the previous burst, since both are the lowest point between the two burst maxima.)
            else
                
                % Better first Min.start candidate?
                if isempty(Min.start) || values(ind) < values(Min.start)
                    Min.start = ind;
                end
            end
                
        else % MAX
            
            % We're at a Max.
            
            % If we already have a Min.stop candidate, this Max could be used to validate the Min.stop (hence the whole burst) and constitute
            % a Max candidate for the next burst. The Min.stop would also become the next Min.start.
            if ~isempty(Min.stop)
                
                % Validate the burst and set new start?
                if values(ind) - values(Min.stop) > threshold
                    out(end + 1) = struct('start', Min.start, 'stop', Min.stop, 'max', Max.staged);
                    
                    Min.start = Min.stop;
                    Max.staged = ind;
                    Min.stop = [];
                end
            
            % Otherwise, this Max could only be used as a better Max candidate.
            else
                
                % Better Max candidate?
                if ~isempty(Min.start) && values(ind) - values(Min.start) > threshold && (isempty(Max.staged) || values(ind) > values(Max.staged))
                    Max.staged = ind;
                end
            end
        end
    end

    if ~isempty(Min.stop)
        out(end + 1) = struct('start', Min.start, 'stop', Min.stop, 'max', Max.staged);
    end

    outMin.indices = unique([out.start out.stop]);
    outMin.values = values(outMin.indices);
    outMin.times = times(outMin.indices);

    outMax.indices = [out.max];
    outMax.values = values(outMax.indices);
    outMax.times = times(outMax.indices);

function out = extreme_struct(times, values, flags)

    out.i = find(flags);
    out.t = times(out.i);
    out.v = values(out.i);
    out.n = length(out.i);
    out.start = [];
    out.stop = [];
    out.staged = [];
