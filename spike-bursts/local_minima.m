function [minima indices flags] = local_minima(values)
    
    flags = values(1:end - 2) > values(2:end - 1) & values(2:end - 1) < values(3:end);
    indices = find(flags);
    minima = values(flags);
