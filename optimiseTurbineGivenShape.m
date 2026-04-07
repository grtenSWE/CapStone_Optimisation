function [result, x] = optimiseTurbineGivenShape(name, fx, num_blades)
% OPTIMISETURBINEGIVENSHAPE Inner-loop scaffold for a fixed airfoil.
%
% Suggested steps:
%   1. set the usual global parameters (Vu, rho, eta, nSections, etc.)
%   2. set B = num_blades
%   3. choose lower and upper bounds for chord and beta
%   4. define objective = @(design) turbineObj(design, fx)
%   5. run ga (or another justified optimiser)
%   6. evaluate the best design across the chosen wind speeds
%   7. return the best design and a short summary in result

% A simple starting point is to use a smooth reference design such as:
%   chord_ref = linspace(0.30, 0.14, nSections);
%   beta_ref = linspace(40, 14, nSections) * pi/180;
%
% You may then build sensible bounds around that reference, or use bounds
% based on a BEM design from your previous assignment.

result = struct();
x = [];

% Implement a simple optimisation using ga (if available) with a sensible
% reference design and bounds. Use globals to match evaluateTurbine.

% Set globals used by evaluateTurbine / turbineObj
global Vu rho eta nSections clearance B R Curve

Vu = 6.0;
R = 0.75;
Curve = @generator;
rho = 1.29;
eta = 0.6;
nSections = 15;
clearance = 0.1;
B = num_blades;

% Reference smooth design
chord_ref = linspace(0.30, 0.14, nSections);
beta_ref  = linspace(40, 14, nSections) * pi/180;

% Bounds around the reference design
chord_lb = 0.25 .* chord_ref;       % lower bound on chord
chord_ub = 1.75 .* chord_ref;       % upper bound on chord
beta_lb  = beta_ref - (10*pi/180);
beta_ub  = beta_ref + (10*pi/180);

lb = [chord_lb, beta_lb];
ub = [chord_ub, beta_ub];

% Objective wrapper with caching to avoid re-evaluating similar designs (AI)
% function obj = safe_obj(design)
%     % ensure vector length
%     if length(design) ~= 2*nSections
%         obj = 1e9; return
%     end
% 
%     % Persistent cache keyed by quantized design
%     persistent cacheMap
%     if isempty(cacheMap)
%         cacheMap = containers.Map('KeyType', 'char', 'ValueType', 'double');
%     end
% 
%     % Quantize design to 4 decimal places to catch near-duplicates
%     key = mat2str(round(design, 4));
%     if isKey(cacheMap, key)
%         obj = cacheMap(key);
%         return
%     end
% 
%     % Evaluate
%     obj = turbineObj(design, fx);
%     cacheMap(key) = obj;
% end

function obj = objective(design)
    obj = turbineObj(design, fx);
end

nvars = 2 * nSections;

% Initial guess (used for pop matrix)
% x0 = [chord_ref, beta_ref];

% GA tuning (reduced population/generations, remove plot, seed initial population)
popSize = 50;
maxGens = 50;

% Build initial population matrix with first row = x0
% initPop = zeros(popSize, nvars);
% initPop(1,:) = x0;
% for ii = 2:popSize
%     initPop(ii,:) = lb + (ub - lb) .* rand(1, nvars);
% end

init_pop = repmat([chord_ref, beta_ref], 100, 1);
init_pop = init_pop + randn(100, nvars) .* 0.02;
init_pop = max(init_pop, lb);
init_pop = min(init_pop, ub);

opts = optimoptions('ga', ...
    'PopulationSize',          popSize, ...
    'MaxGenerations',          maxGens, ...
    'Display',                 'iter', ...
    'PlotFcn',                 {@gaplotbestf}, ...
    'EliteCount',              5, ...
    'CrossoverFraction',       0.5, ...
    'FunctionTolerance',       1e-4, ...
    'MaxStallGenerations',     5, ...
    'InitialPopulationMatrix', init_pop);

[xbest, fbest] = ga(@objective, nvars, [], [], [], [], lb, ub, [], opts);

outputFolder = 'GAResults';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

figs = findall(0, 'Type', 'figure');
if ~isempty(figs)
    filename = fullfile(outputFolder, [name, '_GA_convergence.png']);
    exportgraphics(figs(1), filename, 'Resolution', 300);
    % close(figs(1));
end

% Prepare outputs
x = xbest(:)';
chord = x(1:nSections);
beta  = x(nSections+1:end);

% Best achieved weighted power (turbineObj returns negative weighted power)
if isfinite(fbest) && (fbest < 1e5)
    best_weighted_power = -fbest;
else
    best_weighted_power = NaN;
end

result.best_design = x;
result.chord = chord;
result.beta = beta;
result.weighted_power = best_weighted_power;
result.info = struct('nSections', nSections, 'B', B);

% Nested generator curve used by evaluateTurbine
function RPM = generator(Q)
    if Q > 4.8
        RPM = 314.0*Q-1200.0;
    elseif Q >= 0
        RPM = 1.25*(279-sqrt(77841.0-16000.0*Q));
    else
        RPM = -generator(-Q);
    end
end
end
