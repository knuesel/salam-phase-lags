function handles = plot_phase_patterns(t, joint_angles, varargin)
% doesn't do much if both 'Pos' and 'Neg' options are left empty
    
    [n_rows, n_joints] = size(joint_angles);
    
    p = inputParser;
    p.addParamValue('Pos', []);         % if non-empty, must have fields start_indices, stop_indices, patterns, pattern_joints, series
    p.addParamValue('Neg', []);         % same as above
    p.addParamValue('PlotPatches', true);                   % whether to plot the center-of-mass color patches
    p.addParamValue('PlotTrajectories', true);              % whether to plot the joint trajectories
    p.addParamValue('PlotTargetPattern', true);
    p.addParamValue('PlotActualPattern', true);
    p.addParamValue('MainJoints', []);                      % joint indices to show with thicker lines
    p.addParamValue('SpecialJoints', []);                   % joint indices to show in a different color
    p.addParamValue('SpecialColor', [0 1 0]);
    p.addParamValue('JointNames', num2cell(1:n_joints));    % labels for the joints
    p.addParamValue('JointPositions', 1:n_joints);          % where to plot the joints on the y axis
    p.addParamValue('YStep', 2);                            % scaling factor for joint positions
    p.addParamValue('PosColor', [.9 0 0]);
    p.addParamValue('NegColor', [.5 0 .5]);
    p.addParamValue('TrajectoryStyle', {});
    p.addParamValue('TrajectoryScale', 1);
    p.addParamValue('PatternStyle', {});
    p.addParamValue('SeriesStyle', {});
    p.addParamValue('MainStyle', {});
    p.addParamValue('Opacity', 0.3);
    p.addParamValue('Labels', true);
    p.addParamValue('Joints', []);      % subset of joints to plot
    p.parse(varargin{:});
    
    series_style = {'linestyle', '-', 'marker', 'o', 'markersize', 4, 'linewidth', 2, p.Results.SeriesStyle{:}};
    main_style = {series_style{:}, 'linewidth', 3, p.Results.MainStyle{:}};
    trajectory_style = {'color', 'black', p.Results.TrajectoryStyle{:}};
    pattern_style = {'color', [.7 .7 .7], 'markerfacecolor', [.7 .7 .7], 'linestyle', '-', 'marker', 'o', 'markersize', 6, 'linewidth', 2, p.Results.PatternStyle{:}};

    % make some short names
    joint_positions = p.Results.JointPositions * p.Results.YStep;
    pos = p.Results.Pos;
    neg = p.Results.Neg;
    main = p.Results.MainJoints;
    joints = p.Results.Joints;
    opacity = p.Results.Opacity;
    
    if isempty(joints)
        joints = 1:n_joints;
    end

    main = intersect(main, joints);
    
    if ~isempty(pos)
        pos.pattern_kept = ismember(pos.pattern_joints, joints);
        pos.pattern_joints = pos.pattern_joints(pos.pattern_kept);
    end

    if ~isempty(neg)
        neg.pattern_kept = ismember(neg.pattern_joints, joints);
        neg.pattern_joints = neg.pattern_joints(neg.pattern_kept);
    end
    
    normal_joints = setdiff(1:n_joints, p.Results.SpecialJoints);

    % Patch colors
    if ~isempty(pos)
        pos.colors(normal_joints) = {p.Results.PosColor};
        pos.colors(p.Results.SpecialJoints) = {p.Results.SpecialColor};

        pos.patch_colors(normal_joints) = { 1 - opacity * (1 - p.Results.PosColor) };
        % pos.colors(p.Results.SpecialJoints) = { 1 - 0.6 * (1 - p.Results.PosColor) };
        pos.patch_colors(p.Results.SpecialJoints) = { 1 - opacity * (1 - p.Results.SpecialColor) };
    end
    if ~isempty(neg)
        neg.colors(normal_joints) = {p.Results.NegColor};
        neg.colors(p.Results.SpecialJoints) = {p.Results.SpecialColor};

        neg.patch_colors(normal_joints) = { 1 - opacity * (1 - p.Results.NegColor) };
        % neg.colors(p.Results.SpecialJoints) = { 1 - 0.6 * (1 - p.Results.NegColor) };
        neg.patch_colors(p.Results.SpecialJoints) = { 1 - opacity * (1 - p.Results.SpecialColor) };
    end

    washold = ishold;
    hold on
    if ~washold
        cla
    end

    if p.Results.PlotPatches
        if ~isempty(pos)
            plot_timeseries_stack_areas(t, max(0, joint_angles(:, joints)), joint_positions(:, joints), pos.start_indices(:, joints), pos.stop_indices(:, joints), pos.patch_colors);
        end
        
        if ~isempty(neg)
            plot_timeseries_stack_areas(t, min(0, joint_angles(:, joints)), joint_positions(:, joints), neg.start_indices(:, joints), neg.stop_indices(:, joints), neg.patch_colors);
        end
    end
    
    if p.Results.PlotTargetPattern
        % patterns are transposed because ts_pattern returned one column per cycle (all joints),
        % but plot_timepoints_stack takes one column per joint (all cycles)
        if ~isempty(pos)
            plot_timepoints_stack(pos.patterns(pos.pattern_kept, :)', joint_positions(pos.pattern_joints), [], pattern_style{:});
        end
        
        if ~isempty(neg)
            plot_timepoints_stack(neg.patterns(neg.pattern_kept, :)', joint_positions(neg.pattern_joints), [], pattern_style{:});
        end
    end

    if p.Results.PlotTrajectories
        % Plot joint trajectories, disconnected when more than 10 timesteps are missing
        joint_angles(t(2:end) - t(1:end - 1) > 10 * median(diff(t)), :) = nan;
        plot_timeseries_stack(t, ...
                              joint_angles(:, joints) * p.Results.TrajectoryScale, ...
                              joint_positions(:, joints), ...
                              p.Results.JointNames(:, joints), ...
                              [], ...
                              trajectory_style{:});
                              % pos.colors, ...
                              % trajectory_style{:});
    end
    
    handles = [];

    if p.Results.PlotActualPattern
        if ~isempty(pos) && any(pos.series(:))
            style = {'color', p.Results.PosColor, 'markerfacecolor', p.Results.PosColor};
            h = plot_timepoints_stack(pos.series(joints, :)', joint_positions(pos.pattern_joints), [], style{:}, series_style{:});
            handles(end + 1) = h(1);

            plot_timepoints_stack(pos.series(main, :)', joint_positions(pos.pattern_joints(main)), [], style{:}, main_style{:});
        end
        
        if ~isempty(neg) && any(neg.series(:))
            style = {'color', p.Results.NegColor, 'markerfacecolor', p.Results.NegColor};
            h = plot_timepoints_stack(neg.series(joints, :)', joint_positions(neg.pattern_joints), [], style{:}, series_style{:});
            handles(end + 1) = h(1);

            plot_timepoints_stack(neg.series(main, :)', joint_positions(neg.pattern_joints(main)), [], style{:}, main_style{:});
        end
    end
    
    if ~washold
        hold off;
    end
    
    if p.Results.Labels
        xlabel('Time [s]');
        ylabel('Joints');
    end
    
function plot_timeseries_stack_areas(t, ydata, ypositions, start_indices, stop_indices, colors, varargin)
    
    if ~isempty(start_indices)
        
        for series = 1:size(ydata, 2)
            n_cycles = sum(~isnan(start_indices(:, series)));
            for cycle = 1:n_cycles
                start = start_indices(cycle, series) + 1;
                stop = stop_indices(cycle, series);
                t_cycle = [t(start); t(start:stop); t(stop)];
                y_cycle = [0; ydata(start:stop, series); 0];
                y_cycle = -y_cycle + ypositions(series);
                
                patch('xdata', t_cycle, 'ydata', y_cycle, 'facecolor', colors{series}, 'edgecolor', 'none', varargin{:});
                
            end
        end
    end
