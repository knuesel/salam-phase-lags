function out = phase_lags(t, joint_angles, varargin)
    
    out.n_joints = size(joint_angles, 2);
    
    p = inputParser;
    p.addParamValue('ConnectThreshold', 1);
    p.addParamValue('Pattern', []);     % if specified, PatternK and PatternGait are not used
    p.addParamValue('PatternK', 0);
    p.addParamValue('PatternGait', 'swim');
    p.addParamValue('NAllJoints', out.n_joints);
    p.addParamValue('AssumeDF50', false);
    p.addParamValue('SpikeThreshold', 0.1);
    p.addParamValue('SplineSmooth', []); % set to non-empty to smooth joint angles with a spline fit
    p.parse(varargin{:});
    
    if isempty(p.Results.SplineSmooth)
        x = joint_angles;
    else
        for i = 1:size(joint_angles, 2)
            spl = csaps(t, joint_angles(:, i), p.Results.SplineSmooth);
            x(:, i) = fnval(spl, t);
        end
    end

    [onsets coms offsets start_indices stop_indices] = get_model_bursts(t, x, 'SpikeThreshold', p.Results.SpikeThreshold);
    
    pattern = p.Results.Pattern;
    if isempty(pattern)
        {out.n_joints, p.Results.NAllJoints, p.Results.PatternK, p.Results.PatternGait}
        pattern = gait_pattern(out.n_joints, p.Results.NAllJoints, p.Results.PatternK, p.Results.PatternGait);
    end
    
    [out.periods out.lags out.data] = periods_and_lags(onsets, coms, offsets, pattern, p.Results.ConnectThreshold, 'AssumeDF50', p.Results.AssumeDF50);
    
    out.data.pattern_joints = 1:out.n_joints;
    
    out.burst_times = coms';

    out.data.start_indices = start_indices;
    out.data.stop_indices = stop_indices;
    
    out.joint_angles_raw = joint_angles;
    out.joint_angles = x;
    out.t = t;
    out.n_all_joints = p.Results.NAllJoints;
