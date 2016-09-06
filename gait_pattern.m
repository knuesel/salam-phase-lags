function pattern = gait_pattern(n_joints, n_all_joints, k, gait)
% Generate a pattern model for use with hopf_c2
% n_joints: number of joints in data
% n_all_joints: number of joints in body
    
    % pattern(i) should have (i-1)*2*pi*k/n_joints: we start at 0 and end one step before 2*pi*k
    pattern = linspace(0, 2 * pi * k, n_all_joints + 2)';
    pattern = pattern(1:n_joints);

    if strcmp(gait, 'walk')
        if n_joints == 8 && n_all_joints == 8
            tail_start = 6;
        else
            tail_start = ceil(n_joints / 2) + 1;
        end
        
        pattern(tail_start:end) = pattern(tail_start:end) + pi;
        
    elseif strcmp(gait, 'swim')
            ; % nothing to do
    else
        error(['unknown gait: ' gait]);
    end
