function h = set_figure(h)
% Sets the current figure without stealing the focus.
% The figure can be specified by a handle or a name.
% If a corresponding figure doesn't exist, it will be created but focus will be stealed.
    
    if nargin >= 1
        if ishandle(h)
            set(0, 'CurrentFigure', h);
        elseif isnumeric(h)
            h = figure(h);
        elseif ischar(h)
            name = h;
            h = findobj('type', 'figure', 'name', name);
            if length(h) == 0
                h = figure('name', name);
            else
                h = h(1);
                set(0, 'CurrentFigure', h);
            end
        end
    else
        h = figure();
    end
