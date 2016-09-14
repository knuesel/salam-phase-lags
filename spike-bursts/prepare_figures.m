function prepare_figures(figs, fontsize)
    for i = figs(:)'
        if strcmp(class(i), 'cell')
            i = i{1};
        end
        set_figure(i);
        clf
        orient landscape;
        set(0, 'DefaultAxesFontSize', fontsize);
        set(0, 'DefaultTextFontSize', fontsize);
    end
