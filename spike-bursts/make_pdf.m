function make_pdf(fig, time_range, plot_range, name)
    
    figure(fig);
    
    dt = diff(time_range);
    n = round(dt / plot_range);
    n = max(1, n);
    
    if plot_range < 0 || n == 1
        print('-dpdf', [name '.pdf']);
    else    
        plot_range = dt / n;
        
        for i = 1:n
            for h = findobj(fig, 'Type', 'Axes')'
                xlim(h, time_range(1) + [i - 1, i] * plot_range);
            end
            
            suffix = ['_' num2str(i)];
            print('-dpdf', [name suffix '.pdf']);
        end
    end
    