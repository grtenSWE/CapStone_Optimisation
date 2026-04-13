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
    %% Symmetric (common for VAWT / structural simplicity)
    'NACA0008'
    'NACA0009'
    'NACA0010'
    'NACA0011'
    'NACA0012'
    'NACA0013'
    'NACA0014'
    'NACA0015'
    'NACA0016'
    'NACA0017'
    'NACA0018'
    'NACA0019'
    'NACA0020'
    'NACA0021'
    'NACA0022'
    'NACA0023'
    'NACA0024'
    'NACA0025'
    'NACA0026'
    'NACA0028'
    'NACA0030'

    %% Mild camber (general HAWT performance)
    'NACA1408'
    'NACA1409'
    'NACA1410'
    'NACA1411'
    'NACA1412'
    'NACA1414'

    'NACA2408'
    'NACA2409'
    'NACA2410'
    'NACA2411'
    'NACA2412'
    'NACA2413'
    'NACA2414'
    'NACA2415'

    %% Moderate camber (balanced efficiency + torque)
    'NACA4309'
    'NACA4310'
    'NACA4312'
    'NACA4314'
    'NACA4315'

    %% Higher camber (better lift at low Reynolds / startup torque)
    'NACA4409'
    'NACA4410'
    'NACA4412'
    'NACA4414'
    'NACA4415'
    'NACA4418'

    %% Very high camber / thick (root sections / aggressive lift)
    'NACA4421'
    'NACA4424'

    %% Thick symmetric (structure / low-speed robustness)
    'NACA0032'
    'NACA0035'
};

B_values = [3, 5];

% Fixed blade count for comparison
for B = B_values
    results.candidates = {};
    all_wp = zeros(1, length(airfoil_candidates));
    
    best_overall = struct('name', '', 'result', [], 'design', [], 'weighted_power', -Inf);
    
    % Open file ONCE in append mode
    filename = sprintf('turbine_spec_%s.txt', string(B));
    fid = fopen(filename, 'a+');
    
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
    
            all_wp(i) = wp;
            if wp > best_overall.weighted_power
                best_overall.name = name;
                best_overall.result = res;
                best_overall.design = design;
                best_overall.weighted_power = wp;
            end
        end
    
        % ==========================
        % WRITE EACH RESULT (IN LOOP)
        % ==========================
        fprintf(fid, '========================================\n');
        fprintf(fid, 'Airfoil: %s\n', name);
    
        fprintf(fid, 'Result:\n');
        fprintf(fid, '  weighted_power: %.6f\n', res.weighted_power);
        fprintf(fid, '  chord: [%s]\n', num2str(res.chord, ' %.4f'));
        fprintf(fid, '  beta:  [%s]\n', num2str(res.beta, ' %.4f'));
    
        fprintf(fid, '  info:\n');
        fprintf(fid, '    nSections: %d\n', res.info.nSections);
        fprintf(fid, '    B: %d\n', res.info.B);
    
        fprintf(fid, 'Design Variables:\n');
        fprintf(fid, '  x: [%s]\n', num2str(design, ' %.4f'));
    
        fprintf(fid, '\n');
    end
    
    % ==========================
    % POST-PROCESS: BEST 5
    % ==========================
    if ~isempty(results.candidates)
    
        % Sort by weighted power descending
        [~, idx] = sort(all_wp, 'descend');
        topN = min(5, length(idx));
    
        fprintf(fid, '========================================\n');
        fprintf(fid, 'TOP %d SOLUTIONS\n', topN);
        fprintf(fid, '========================================\n');
    
        for k = 1:topN
            entry = results.candidates{idx(k)};
            res = entry.Result;
    
            fprintf(fid, '#%d Airfoil: %s\n', k, entry.Name);
            fprintf(fid, '  weighted_power: %.6f\n', res.weighted_power);
            fprintf(fid, '  chord: [%s]\n', num2str(res.chord, ' %.4f'));
            fprintf(fid, '  beta:  [%s]\n', num2str(res.beta, ' %.4f'));
            fprintf(fid, '\n');
        end
    
        results.best = best_overall;
    else
        results.best = [];
    end
    
    % ==========================
    % BEST OVERALL (FINAL SUMMARY)
    % ==========================
    if ~isempty(results.best)
        fprintf(fid, '========================================\n');
        fprintf(fid, 'BEST OVERALL\n');
        fprintf(fid, '========================================\n');
        fprintf(fid, 'Airfoil: %s\n', results.best.name);
        fprintf(fid, 'Weighted Power: %.6f\n', results.best.weighted_power);
    end
    
    fclose(fid);
    
end
end