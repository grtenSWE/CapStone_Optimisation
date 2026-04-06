function results = optimiseTurbine()
% OPTIMISETURBINE Outer-loop scaffold for comparing candidate airfoils.
%
% Suggested core steps:
%   1. choose a small list of candidate airfoils
%   2. build a surrogate for each one
%   3. call optimiseTurbineGivenShape
%   4. store the best result for each airfoil
%   5. identify the best overall candidate

results = struct();

% Candidate airfoils
airfoil_candidates = {
    'NACA0012'
    'NACA2412'
    'NACA4415'
};

% Fixed blade count for comparison
B = 5;

results.candidates = {};
best_overall = struct('name', '', 'result', [], 'design', [], 'weighted_power', -Inf);

for i = 1:length(airfoil_candidates)
    name = airfoil_candidates{i};
    [fx, success] = createSurrogate(name, -10:25);
    if ~success
        warning('optimiseTurbine:SurrogateFail', 'Failed to build surrogate for %s', name);
        continue;
    else
        [res, design] = optimiseTurbineGivenShape(fx, B);
        entry = struct('Name', name, 'Result', res, 'Design', design);
        results.candidates{end+1} = entry;
            wp = NaN;
        if isfield(res, 'weighted_power')
            wp = res.weighted_power;
        end
        if isnan(wp)
            wp = -Inf;
        end
    
        if wp > best_overall.weighted_power
            best_overall.name = name;
            best_overall.result = res;
            best_overall.design = design;
            best_overall.weighted_power = wp;
        end
    end
end

if isempty(results.candidates)
    results.best = [];
else
    results.best = best_overall;
end


end