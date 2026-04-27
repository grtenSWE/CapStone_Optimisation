function [result, x] = optimiseTurbineGivenShape(name, fx, num_blades, num_sections, popSize, maxGens)
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

% Set globals used by liftAndDrag and BEM
global Vu rho eta nSections clearance B R Curve optimise_c Re

Vu = 6.0;
R = 0.72;
Curve = @generator;
rho = 1.29;
eta = 0.6;
nSections = num_sections;
clearance = 0.17;
B = num_blades;

% BEM Values
Re = 100000;        % Approximate Reynolds number for design
optimise_c = false;

% BEM Optimal Beta Shape
[alpha, Cl, Cd] = liftAndDrag(name);
[~, bemOptDesign] = BEM(alpha, Cl, Cd);
disp(bemOptDesign)

% Determine optimal shape for chord distribution
r = linspace(clearance, R, nSections);
s = linspace(0, 1, nSections);   % normalised span

% End constraints from BEM
c_root = bemOptDesign.chord(1);
c_tip  = bemOptDesign.chord(end);

% Peak location (1/4 of span)
s_peak = 1/4;

% Choose peak magnitude (relative to root)
c_peak = 3 * c_root;   % tune this (1.1–1.5 is reasonable)

chord_ref = zeros(1, nSections);

for i = 1:nSections
    if s(i) <= s_peak
        % --- Smooth rise (cosine easing) ---
        t = s(i) / s_peak;
        chord_ref(i) = c_root + (c_peak - c_root) * (1 - cos(pi*t)) / 2;
    else
        % --- Smooth decay (cosine easing) ---
        t = (s(i) - s_peak) / (1 - s_peak);
        chord_ref(i) = c_peak + (c_tip - c_peak) * (1 - cos(pi*t)) / 2;
    end
end

% Safety clamps (optional but recommended)
chord_ref = max(chord_ref, 0.05);
chord_ref = min(chord_ref, 0.5);

beta_ref = bemOptDesign.beta;

% Bounds around the reference design
chord_lb = 0.5 .* chord_ref;       % lower bound on chord
chord_ub = 1.75 .* chord_ref;       % upper bound on chord
beta_lb  = beta_ref - (10*pi/180);
beta_ub  = beta_ref + (10*pi/180);

lb = [chord_lb, beta_lb];
ub = [chord_ub, beta_ub];

function obj = objective(design)
    [obj, ~] = objectivePenalties(design, false, false);
end

function [obj, rpm] = objectivePenalties(design, skipPenalties, returnRPM)
    [obj, Vu, rpm] = turbineObj(design, fx, Vu, rho, eta, nSections, clearance, B, R, Curve, skipPenalties, returnRPM);
end

nvars = 2 * nSections;

% Initial guess (used for pop matrix)
% x0 = [chord_ref, beta_ref];

% GA tuning (reduced population/generations, remove plot, seed initial population)
eliteCount = floor(popSize / 10);
maxStall = floor(maxGens / 10);

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
    'EliteCount',              eliteCount, ...
    'CrossoverFraction',       0.5, ...
    'FunctionTolerance',       1e-4, ...
    'MaxStallGenerations',     maxStall, ...
    'UseParallel',             true, ...
    'InitialPopulationMatrix', init_pop);

[xbest, ~] = ga(@objective, nvars, [], [], [], [], lb, ub, [], opts);

outputFolder = 'GAResults';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

figs = findall(0, 'Type', 'figure');
if ~isempty(figs)
    fig = figs(1);
    theme(fig, "light")
    filename = fullfile(outputFolder, [name, '_Blades', num2str(B), '_nSections', num2str(nSections), '_GA_convergence.png']);
    exportgraphics(fig, filename, 'Resolution', 300);
    close(fig);
end

% Prepare outputs
x = xbest(:)';
chord = x(1:nSections);
beta  = x(nSections+1:end);

% Rerun turbineObj to get true weighted Power
[fbest, rpm] = objectivePenalties(x, true, true);

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
sol = calculateSolidity(chord, r, B);
result.info = struct('nSections', nSections, 'B', B, ...
    'solidity', sol',...
    'rpm', rpm);

% Create output folder if needed
distFolder = 'Distributions';
if ~exist(distFolder, 'dir')
    mkdir(distFolder);
end

% Radial stations (non-dimensional or just index-based)
r = linspace(clearance, R, nSections);
beta_deg = beta * 180/pi;
fig = figure('Visible', 'off');
theme(fig, "light")

% --- Chord plot ---
subplot(2,1,1);
hold on;
plot(r, chord_lb, 'Color', [0.6 0.6 1], 'LineWidth', 1);
plot(r, chord_ub, 'Color', [0.6 0.6 1], 'LineWidth', 1);
plot(r, chord,    'Color', [0 0 1],     'LineWidth', 1.5, ...
    'MarkerSize', 4, 'Marker', 'o');
grid on;
xlabel('Radius (m)');
ylabel('Chord (m)');
title('Chord Distribution');

% --- Beta plot ---
subplot(2,1,2);
hold on;
beta_lb_deg = rad2deg(beta_lb);
beta_ub_deg = rad2deg(beta_ub);
plot(r, beta_lb_deg,  'Color', [1 0.6 0.6], 'LineWidth', 1);
plot(r, beta_ub_deg,  'Color', [1 0.6 0.6], 'LineWidth', 1);
plot(r, beta_deg, 'Color', [1 0 0],     'LineWidth', 1.5, ...
    'MarkerSize', 4, 'Marker', 'o');
grid on;
xlabel('Radius (m)');
ylabel('Beta (deg)');
title('Twist (Beta) Distribution');

filename = fullfile(distFolder, [name, '_Blades', num2str(B), '_nSections', num2str(nSections), '_ChordBeta.png']);
exportgraphics(fig, filename, 'Resolution', 300);

close(fig);

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
