%function plot_example

n = 8;

t = (0:0.01:10)';

% drive = 1;
% [theta, r, x, dtheta, nu, R] = salam_cpg_osc(t, drive);


lags = (1:n) * 2*pi/(n+1);

joint_angles = sin(2 * pi * repmat(t, 1, n) - repmat(lags, length(t), 1) + rand(length(t), n));

out = phase_lags(t, joint_angles, 'Pattern', lags, 'splinesmooth', 0.00001);
plot_phase_lags(out, []);
