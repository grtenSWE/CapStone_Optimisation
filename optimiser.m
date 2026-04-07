clear all; close all; clc;

global Vu rho eta nSections clearance B Re R Curve

% Setup globals (will be overwritten inside function but needed for surrogate)
Vu = 6; R = 0.75; rho = 1.29; eta = 0.6;
nSections = 15; clearance = 0.1; B = 5; Re = 100000;
Curve = @generator;

% Build surrogate for NACA0012
fprintf('Building surrogate...\n');
name = 'NACA2412';
[fx, success] = createSurrogate(name);

if ~success
    error('Surrogate failed');
end

fprintf('Surrogate ready. Running optimisation...\n');

% Run inner loop optimisation
[result, x] = optimiseTurbineGivenShape(name, fx, 5);

% Print summary
fprintf('\nChord distribution:\n');
disp(result.chord)
fprintf('Beta distribution (rad):\n');
disp(result.beta)

function RPM = generator(Q)
    if Q > 4.8
        RPM = 314.0*Q-1200.0;
    elseif Q >= 0
        RPM = 1.25*(279-sqrt(77841.0-16000.0*Q));
    else
        RPM = -generator(-Q);
    end
end