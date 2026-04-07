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
    % Symmetric (common for VAWT / structural simplicity)
    'NACA0009'
    'NACA0012'
    'NACA0015'
    'NACA0018'
    'NACA0020'
    'NACA0021'
    'NACA0025'

    % Mild camber (general HAWT performance)
    'NACA1408'
    'NACA1410'
    'NACA1412'
    'NACA2412'
    'NACA2414'
    'NACA2415'

    % Higher camber (better lift at low Reynolds / startup torque)
    'NACA4412'
    'NACA4415'
    'NACA4418'

    % Thick cambered (root sections / structural strength)
    'NACA6409'
    'NACA6412'
    'NACA6415'
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
        [res, design] = optimiseTurbineGivenShape(name, fx, B);
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

fid = fopen('turbine_results.txt', 'w+');

for i = 1:length(results.candidates)
    entry = results.candidates{i};
    fprintf(fid, 'Airfoil: %s\n', entry.Name);
    
    if isfield(entry.Result, 'weighted_power')
        fprintf(fid, '  Weighted Power: %.4f\n', entry.Result.weighted_power);
    end
    
    fprintf(fid, '\n');
end

if ~isempty(results.best)
    fprintf(fid, 'Best Overall: %s\n', results.best.name);
    fprintf(fid, 'Best Weighted Power: %.4f\n', results.best.weighted_power);
end

fclose(fid);

end