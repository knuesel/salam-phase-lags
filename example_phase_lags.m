%function plot_example

n = 8;

t = (0:0.01:10)';

% drive = 1;
% [theta, r, x, dtheta, nu, R] = salam_cpg_osc(t, drive);


lags = (1:n) * 2*pi/(n+1);

joint_angles = sin(2 * pi * repmat(t, 1, n) - repmat(lags, length(t), 1) + rand(length(t), n));

out = phase_lags(t, joint_angles, 'Pattern', lags, 'splinesmooth', 0.99999);

if isempty(out.lags)
	warning('Could not get lags from data');
	plot(t, out.joint_angles);
else
	disp('Lags:');
	out.lags
	%plot_phase_lags(out, []);
	plot_phase_lags(out, [], 'PlotTargetPattern', false);
end
