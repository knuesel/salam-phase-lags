function [theta, r, x, dtheta, nu, R] = salam_cpg_osc(times, drives)
% [theta, r, x, dtheta, nu, R] = salam_cpg_osc(times, drives)
%
% Integrate an oscillator-based model of the salamander's CPG.
%
% Inputs:
%   times   A vector of times defining the integration steps (e.g. 0:0.01:10)
%   drives  A vector of same size as times, giving the drive level for the
%           corresponding time. Can also be a scalar (for constant drive).
% 
% Outputs:
%   theta   A matrix of the oscillators' phases (rows and columns as for r)
%   r       A matrix of the oscillators' amplitudes, one oscillator per column,
%           one row per timestep. The column order is:
%           left oscillators, right oscillators, limbs (LF, RF, LH, RH)
%   x       A matrix of the oscillators' outputs (rows and columns as for r)
%   dtheta  A matrix of the oscillators' instantaneous frequencies, in rad/s
%   nu      A matrix of the oscillators' intrinsic frequencies, as calculated
%           from the drives (rows and columns as for r)
%   R       A matrix of the oscillators' target amplitudes, as calculated
%           from the drives (rows and columns as for r)
%
% Example to integrate the model from t=0 to t=10 with a timestep of 0.01 s,
% with a drive linearly increasing from 0 to 6:
%
%   times = 0:0.01:10;
%   drives = linspace(0, 6, length(times));
%   [theta, r, x, dtheta] = salam_cpg_osc(times, drives);
%   plot_salam_cpg(times, x, dtheta, drives);
  
  % Make sure we have a column vector of drives
  if length(drives) == 1
    drives = ones(length(times), 1) * drives;
  else
    drives = drives(:); % indexing with (:) ensures we have a column vector
  end

  % Network parameters
  n_segments = 8;                     % 8 axial segments
  girdles = [1 5];                    % Forelimbs project to segments 1-4, hind limbs to segments 5-end

  n_osc = 2 * n_segments + 2 * length(girdles); % Two oscillators per segment and 2 limbs per girdle
  
  phase_lag = 1 / n_segments;         % Intersegmental phase lag expressed as a fraction of a whole cycle.
                                      % A phase lag equal to 1 / n_segments corresponds to a whole cycle
                                      % between the first and last segments.
  
  a = ones(1, n_osc) * 20;            % Convergence factor

  % Coupling weights
  w_axis_downwards = 10;              % from axial oscillators to caudal neighbors
  w_axis_upwards = 10;                % from axial oscillators to rostral neighbors
  w_axis_contralateral = 10;          % from axial oscillator to neighbor on other side
  w_limb_axis = 30;                   % from limb to axial oscillators
  w_limb_limb = 10;                   % between two limb oscillators

  % Phase biases, expressed in radians
  phi_axis_downwards = phase_lag * 2 * pi; % head-to-tail wave: positive phi_ij for descending couplings
  phi_axis_upwards = -phase_lag * 2 * pi;  % head-to-tail-wave: negative phi_ij for ascending couplings
  phi_limb_axis = 0;                       % 0 = in-phase
  
  % Indices for oscillator groups
  axis_left = 1:n_segments;
  axis_right = n_segments + 1:2 * n_segments;
  limbs_left = 2 * n_segments + [1 3];
  limbs_right = 2 * n_segments + [2 4];
  axis_indices = [axis_left axis_right];
  limb_indices = [limbs_left limbs_right];
  
  % Indices of oscillators that receive couplings from each limb oscillator
  limb_left1_targets = axis_left(girdles(1):girdles(2) - 1);
  limb_left2_targets = axis_left(girdles(2):end);
  limb_right1_targets = axis_right(girdles(1):girdles(2) - 1);
  limb_right2_targets = axis_right(girdles(2):end);

  % Matrices of coupling weights and phase biases
  % Row index = receiver
  % Column index = sender
  W = zeros(n_osc);    % initially zeros (i.e. no coupling)
  PHI = zeros(n_osc);

  % Connections between axial oscillators
  [W, PHI] = add_couplings(W, PHI, axis_left(1:end-1), axis_left(2:end), w_axis_upwards, phi_axis_upwards);
  [W, PHI] = add_couplings(W, PHI, axis_left(2:end), axis_left(1:end-1), w_axis_downwards, phi_axis_downwards);
  [W, PHI] = add_couplings(W, PHI, axis_right(1:end-1), axis_right(2:end), w_axis_upwards, phi_axis_upwards);
  [W, PHI] = add_couplings(W, PHI, axis_right(2:end), axis_right(1:end-1), w_axis_downwards, phi_axis_downwards);
  [W, PHI] = add_couplings(W, PHI, axis_left, axis_right, w_axis_contralateral, pi);
  [W, PHI] = add_couplings(W, PHI, axis_right, axis_left, w_axis_contralateral, pi);

  % Ascending interlimb connections
  [W, PHI] = add_couplings(W, PHI, limbs_left(1), limbs_left(2), w_limb_limb, pi); % pi = anti-phase
  [W, PHI] = add_couplings(W, PHI, limbs_right(1), limbs_right(2), w_limb_limb, pi);
  
  % Descending interlimb connections
  [W, PHI] = add_couplings(W, PHI, limbs_left(2), limbs_left(1), w_limb_limb, pi);
  [W, PHI] = add_couplings(W, PHI, limbs_right(2), limbs_right(1), w_limb_limb, pi);
  
  % Contralateral interlimb connections
  [W, PHI] = add_couplings(W, PHI, limbs_left, limbs_right, w_limb_limb, pi);
  [W, PHI] = add_couplings(W, PHI, limbs_right, limbs_left, w_limb_limb, pi);

  % Limb->axis connections
  [W, PHI] = add_couplings(W, PHI, limb_left1_targets, limbs_left(1), w_limb_axis, phi_limb_axis);
  [W, PHI] = add_couplings(W, PHI, limb_left2_targets, limbs_left(2), w_limb_axis, phi_limb_axis);
  [W, PHI] = add_couplings(W, PHI, limb_right1_targets, limbs_right(1), w_limb_axis, phi_limb_axis);
  [W, PHI] = add_couplings(W, PHI, limb_right2_targets, limbs_right(2), w_limb_axis, phi_limb_axis);
  
  % Calculate nu and R from drives, for whole simulation, using different saturation function parameters
  % for axial and limb oscillators
  [nu_axis, R_axis] = saturation_function(drives, ...
                                          1, 5, ...         % d_low, d_high
                                          0.2, 0.3, ...     % c_nu_1, c_nu_0
                                          0.065, 1.196, ... % c_R_1, c_R_0
                                          0, 0);            % nu_sat, R_sat

  [nu_limbs, R_limbs] = saturation_function(drives, ...
                                            1, 3, ...         % d_low, d_high
                                            0.2, 0, ...       % c_nu_1, c_nu_0
                                            0.131, 1.131, ... % c_R_1, c_R_0
                                            0, 0);            % nu_sat, R_sat
  
  % nu and R are matrices with one row per timestep, one column per oscillator
  nu(:, axis_indices) = repmat(nu_axis, 1, length(axis_indices));
  nu(:, limb_indices) = repmat(nu_limbs, 1, length(limb_indices));
  R(:, axis_indices) = repmat(R_axis, 1, length(axis_indices));
  R(:, limb_indices) = repmat(R_limbs, 1, length(limb_indices));
  
  % Random initial values for state variables
  theta0 = (rand(1, n_osc) * 2 - 1) * pi; % initial phases between -pi and pi
  r0 = rand(1, n_osc);                    % initial amplitudes between 0 and 1
  r_dot0 = rand(1, n_osc);                % initial amplitude derivates between 0 and 1

  % Pre-allocate output matrices for better performance (except x which is calculated at the end)
  theta = zeros(length(times), n_osc);
  r = zeros(length(times), n_osc);
  r_dot = zeros(length(times), n_osc);
  dtheta = zeros(length(times), n_osc);

  % Set first row to initial values of state variables
  theta(1, :) = theta0;
  r(1, :) = r0;
  r_dot(1, :) = r_dot0;
  
  % Euler integration, starting with second time as the first time corresponds to initial conditions
  for i = 2:length(times)
    timestep = times(i) - times(i - 1);
    
    % dtheta is the instantaneous frequency and is part of the output,
    % so we record it in a matrix. The other derivatives (dr and dr_dot)
    % are put in temporary variables, overwritten at every timestep.
    [dtheta(i - 1, :), dr, dr_dot] = get_derivatives(W, PHI, nu(i - 1, :), R(i - 1, :), a, ...        % parameters
                                                     theta(i - 1, :), r(i - 1, :), r_dot(i - 1, :));  % state variables
        
    theta(i, :) = theta(i - 1, :) + dtheta(i - 1, :) * timestep;
    r_dot(i, :) = r_dot(i - 1, :) + dr_dot * timestep;
    r(i, :) = r(i - 1, :) + dr * timestep;
  end
  
  % Calculate oscillators' outputs from phase and amplitude
  x = r .* (1 + cos(theta));


function [dtheta, dr, dr_dot] = get_derivatives(W, PHI, nu, R, a, theta, r, r_dot)
  
  for i = 1:length(theta)
    % The sum over j is calculated using a dot product
    dtheta(i) = 2 * pi * nu(i) + dot(r, W(i, :) .* sin(theta - theta(i) - PHI(i, :)));
  end
  
  dr = r_dot;
  dr_dot = a .* (a / 4 .* (R - r) - r_dot);
 

function [nu, R] = saturation_function(d, d_low, d_high, c_nu_1, c_nu_0, c_R_1, c_R_0, nu_sat, R_sat)
  % Make output vectors of same size as input 'd', initialized with saturated values
  nu = nu_sat * ones(size(d)); 
  R = R_sat * ones(size(d)); 

  % Prepare boolean flags marking non-saturating drives
  non_saturated = d_low <= d & d <= d_high;

  % Calculate non saturated values
  nu(non_saturated) = c_nu_1 * d(non_saturated) + c_nu_0;
  R(non_saturated) = c_R_1 * d(non_saturated) + c_R_0;

  
function [W, PHI] = add_couplings(W, PHI, receivers, senders, w, phi)
% Add couplings from senders(i) to receivers(i)
% If either senders or receivers is scalar (but not both),
% the value is replicated to make a vector
  
  if length(receivers) > 1 && length(senders) == 1
    senders = senders * ones(size(receivers));
  elseif length(receivers) == 1 && length(senders) > 1
    receivers = receivers * ones(size(senders));
  end

  for i = 1:length(senders)
    W(receivers(i), senders(i)) = w;
    PHI(receivers(i), senders(i)) = phi;
  end
