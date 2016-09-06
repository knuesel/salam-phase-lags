function [body limbs] = plot_phase_lags(body, limbs, varargin)
    
    limb_names = {'Forelimb', 'Hindlimb'};

    n_joints = size(body.joint_angles, 2);
    
    if isempty(limbs)
        n_limbs = 0;
    else
        n_limbs = size(limbs.joint_angles, 2);
    end
    
    p = inputParser;
    p.KeepUnmatched = true;
    p.addParamValue('KJoints', []);
    p.addParamValue('Joints',1:n_joints);
    p.addParamValue('JointPositions', 1:n_joints);          % where to plot the joints on the y axis
    p.addParamValue('JointNames', num2cell(1:n_joints));    % labels for the joints
    p.addParamValue('GirdlePositions', (0:n_limbs - 1) * 11  + 2.5); % i.e. [2.5 13.5] for 2 limbs
    p.addParamValue('GirdleNames', limb_names(1:n_limbs));
    p.addParamValue('GirdleOptions', {});
    p.addParamValue('BodyOptions', {});
    p.addParamValue('YStep', 2);
    p.parse(varargin{:});

    body.joint_names = num2cell(1:body.n_joints);
    
    body.joint_positions = 1:body.n_joints;
    
    washold = ishold;
    hold on
    if ~washold
        cla
    end
    
    v = 0.4;
    transparency = 1;

    if ~isempty(limbs)
        limbs.joint_names = cellfun(@(x) ['Girdle ' num2str(x)], num2cell(1:limbs.n_joints), 'UniformOutput', false);
        limbs.joint_positions = p.Results.GirdlePositions;
        limbs.phase_lag_handles = plot_part(limbs, 'PosColor', [v 0 v], 'PlotTargetPattern', false, 'PlotActualPattern', false, ...
                                            'JointPositions', p.Results.GirdlePositions, ...
                                            'TrajectoryStyle', {'color', 1 - transparency * (1 - [v 0 v])}, 'YStep', p.Results.YStep, p.Unmatched, p.Results.GirdleOptions{:});
    end
    
    body.phase_lag_handles = plot_part(body, 'MainJoints', p.Results.KJoints, 'Joints', p.Results.Joints, ...
                                       'JointPositions', p.Results.JointPositions, ...
                                       'YStep', p.Results.YStep, p.Unmatched, p.Results.BodyOptions{:});
    
    positions = [p.Results.JointPositions(p.Results.Joints) p.Results.GirdlePositions] * p.Results.YStep;
    names = [p.Results.JointNames(p.Results.Joints) p.Results.GirdleNames];
    [positions, indices] = sort(positions);
    names = names(indices);

    set(gca, 'ytick', positions, 'yticklabel', names);
    
    if ~washold
        hold off
    end

    body.k_joints = p.Results.KJoints;
    body.girdle_positions = p.Results.GirdlePositions;
    

function handles = plot_part(data, varargin)
    
    if ~isempty(data.data)
        handles = plot_phase_patterns(data.t, data.joint_angles, 'Pos', data.data, 'JointPositions', data.joint_positions, varargin{:});
    else
        handles = [];
    end
