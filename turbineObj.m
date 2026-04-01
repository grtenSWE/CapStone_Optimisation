function obj = turbineObj(design, fx)
% TURBINEOBJ Objective-function scaffold for the optimisation assignment.
%
% Core task:
%   - split design into chord and beta
%   - evaluate evaluateTurbine(fx, chord, beta) at wind speeds [4 5 6 7]
%   - use weights [0.25 0.45 0.20 0.10]
%   - apply the RPM rule from the handout
%   - return the negative weighted power

global Vu nSections

chord = design(1:nSections);
beta = design(nSections+1:end);

wind_speeds = [4.0, 5.0, 6.0, 7.0];
weightings = [0.25, 0.45, 0.20, 0.10];
weighted_power = 0.0;

Vu_before = Vu;

for i = 1:length(wind_speeds)
    Vu = wind_speeds(i);

    % TODO:
    % 1. call evaluateTurbine(fx, chord, beta)
    % 2. apply the RPM rule from the assignment handout
    % 3. add the weighted contribution to weighted_power
end

Vu = Vu_before;
obj = -weighted_power;

error('turbineObj:NotImplemented', 'Complete turbineObj.m before using it in optimisation.');
end
