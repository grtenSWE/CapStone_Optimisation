 function obj = turbineObj(design, fx)
% TURBINEOBJ Objective function for multi-wind-speed turbine optimisation.
%
%   obj = turbineObj(design, fx)
%
%   design  - vector of length 2*nSections: [chord, beta]
%   fx      - airfoil surrogate function
%   Returns the negative weighted power (for use with minimisers).

global Vu nSections

chord = design(1:nSections);
beta  = design(nSections+1:end);

wind_speeds = [4.0, 5.0, 6.0, 7.0];
weightings  = [0.25, 0.45, 0.20, 0.10];
weighted_power = 0.0;

Vu_before = Vu;

for i = 1:length(wind_speeds)
    Vu = wind_speeds(i);
    [PE, RPM] = evaluateTurbine(fx, chord, beta);

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

    weighted_power = weighted_power + weightings(i) * PE * contribution;
end

Vu = Vu_before;
obj = -weighted_power;
end