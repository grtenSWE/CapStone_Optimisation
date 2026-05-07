function [obj, Vu, rpm_] = turbineObj(design, fx, Vu, rho, eta, nSections, clearance, B, R, Curve, skipPenalties, returnRPM)
% TURBINEOBJ Objective function for multi-wind-speed turbine optimisation.
%
%   obj = turbineObj(design, fx)
%
%   design  - vector of length 2*nSections: [chord, beta]
%   fx      - airfoil surrogate function
%   Returns the negative weighted power (for use with minimisers).

chord = design(1:nSections);
beta  = design(nSections+1:end-1);
R     = design(end);

wind_speeds = [4.0, 5.0, 6.0, 7.0];
weightings  = [0.25, 0.45, 0.20, 0.10];
weighted_power = 0.0;

Vu_before = Vu;
rpm_ = zeros(1, 4);

for i = 1:length(wind_speeds)
    Vu = wind_speeds(i);
    [PE, RPM] = evaluateTurbine(fx, chord, beta, Vu, rho, eta, nSections, clearance, B, R, Curve);

    % Apply RPM contribution rule
    if RPM < 0
        contribution = 0;
    elseif RPM <= 200
        contribution = 1;
    elseif RPM < 250
        contribution = 1 - (RPM - 200) / 50;
    else
        contribution = 0;
    end
    
    if returnRPM
        rpm_(i) = RPM;
    end

    weighted_power = weighted_power + weightings(i) * PE * contribution;
end


if skipPenalties
    Vu = Vu_before;
    obj = -weighted_power;
    return;
end

% Apply penalty if beta is not monotonically decreasing.
penalty_beta = 0;
for i = 1:length(beta)-1
    if beta(i+1) > beta(i)
        penalty_beta = penalty_beta + (beta(i+1) - beta(i))^2;
    end
end

% Apply penalty if chord is not monotonically increasing in first 3rd.
penalty_chord1 = 0;
% end_idx = floor(nSections/3);
% for i = 1:(end_idx-1)
%     if chord(i+1) < chord(i)
%         penalty_chord1 = penalty_chord1 + (chord(i) - chord(i+1))^2;
%     end
% end

% Apply penalty if chord is not monotonically decreasing in last 2 thirds.
penalty_chord2 = 0;
% start_idx = floor(nSections/3) + 1;
% for i = start_idx:(nSections-1)
%     if chord(i+1) > chord(i)
%         penalty_chord2 = 10;
%         break
%     end
% end

% Apply penalty if solidity constraints are violated.
penalty_solidity = 0;
r = linspace(clearance, R, nSections);

sol = calculateSolidity(chord, r, B);
if any(sol > 0.9)
    penalty_solidity = 10;
end

% Apply penalty if not smooth
smooth_penalty = 0;
lambda = 0.5;
chord_smooth = smoothdata(chord);
smooth_penalty = smooth_penalty + lambda * sum((chord - chord_smooth).^2);
% beta_smooth = smoothdata(beta);
% smooth_penalty = smooth_penalty + lambda * sum((beta - beta_smooth).^2);

% Combine penalties
penalty_total = 1e3 * (penalty_beta + penalty_chord1 + penalty_chord2 + penalty_solidity + smooth_penalty);
weighted_power = weighted_power - penalty_total;

Vu = Vu_before;
obj = -weighted_power;

function solidity = calculateSolidity(chord, r, B)
    chord = chord(:);
    r = r(:);

    solidity = zeros(size(r));

    for i_ = 2:length(r)
        solidity(i_) = (B * chord(i_)) / (2*pi*r(i_));
    end

    % copy root value for stability
    solidity(1) = solidity(2);

    % optional safety clamp
    solidity = min(max(solidity, 0), 1);

end
end