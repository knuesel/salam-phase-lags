% Make 10 seconds of oscillatory data for 8 segments
n = 8;
t = (0:0.01:10)';
phase_pattern = (1:n) * 2*pi/(n+1);
real_lags = phase_pattern + rand(1, n); % add some randomness to the lags
theta = 2 * pi * repmat(t, 1, n) - repmat(real_lags, length(t), 1);
joint_angles = sin(theta);


% Calculate the phase lags from the 'joint_angles' data. We need to give the
% expected phase pattern to the phase_lags function, to help it connect the
% right oscillation cycles of each segment.
out = phase_lags(t, joint_angles, 'Pattern', phase_pattern);

% Print the calculated lags. Note that while the phase pattern above was given
% as phases in radians, the calculated lags are expressed as a fraction of a
% cycle (e.g. lag 0.5 == half a cycle == 180 degrees == pi radians)
disp('Lags:');
out.lags

% Plot the joint angles together with the calculated phase lags
figure(1);
plot_phase_lags(out, []);


% Generate some joint angles with high level of noise
joint_angles_noisy = sin(theta + rand(length(t), n));

% Make a quick plot of this noisy data for reference
figure(2);
plot(t, joint_angles_noisy + repmat(1:n, length(t), 1));
set(gca, 'YDir', 'reverse');
title('Noisy joint angles (raw data)')

% Calculate the phase lags from the noisy data. We ask for a cubic spline
% smoothing of the data with a smoothing parameter of 0.99999 (see the 'csaps'
% documentation). Without this smoothing, the phase_lags function would detect
% meaningless oscillations at a high frequency due to the noise.
% We also specify a 'connect threshold' of 0.5: this means that if for some
% cycle, the observed phase lag between two consecutive segments deviates by
% more than half a cyle from the expected phase lag (given in phase_pattern),
% then the phase_lags function will not "connect" this oscillation cycle. This
% avoids having the last cycle of the first segments connected to the previous
% oscillation cycle.
out2 = phase_lags(t, joint_angles_noisy, 'Pattern', phase_pattern, 'ConnectThreshold', 0.5, 'SplineSmooth', 0.99999);

disp('Lags (noisy):');
out2.lags

% Plot the lags with some fancy options
figure(3);
plot_phase_lags(out2, [], ...
		'PlotTargetPattern', false, ... % Do not plot the expected phase lag pattern
		'PosColor', [0 0.7 0.2], ... % Use a green color for the positive series (the only one plotted here)
		'PlotPatches', false, ... % Don't color the centroid surface used for finding the times of oscillations
                'TrajectoryStyle', {'color', [.2 .2 .2], 'linestyle', ':'}, ... % Use gray dotted line for joint angles
                'SeriesStyle', {'linewidth', 3}, ... % Use thicker line for the lag series
		'MainJoints', 2:4, ... % Specify joints 2, 3, 4 as "main joints"
                'MainStyle', {'marker', 'square', 'linewidth', 6}); % Use squares and thicker lines for main joints
title('Noisy joint angles')
