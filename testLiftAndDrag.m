% Test script for liftAndDrag
clear; clc;

global nSections Re
nSections = 5;
Re = 100000;

fprintf('==============================\n');
fprintf('TEST 1: Single Aerofoil Input\n');
fprintf('==============================\n');

[a, cl, cd] = liftAndDrag('NACA4412');

disp('Alpha (rad):'); disp(a)
disp('Cl:'); disp(cl)
disp('Cd:'); disp(cd)

fprintf('Expected behaviour:\n');
fprintf('- All values identical across %d sections\n\n', nSections);



fprintf('==============================\n');
fprintf('TEST 2: Multiple Aerofoils (Cell Array)\n');
fprintf('==============================\n');

foils = {'NACA4412','NACA4412','NACA0012','NACA0012','NACA2412'};

[a, cl, cd] = liftAndDrag(foils);

disp('Alpha (rad):'); disp(a)
disp('Cl:'); disp(cl)
disp('Cd:'); disp(cd)

fprintf('Expected behaviour:\n');
fprintf('- Sections 1–2 identical\n');
fprintf('- Sections 3–4 identical\n');
fprintf('- Section 5 different\n\n');



fprintf('==============================\n');
fprintf('TEST 3: Precomputed Aerofoil Data\n');
fprintf('==============================\n');

% Pretend we already computed these elsewhere
LiftCoeffs = [1.2 0.9 1.4];
DragCoeffs = [0.02 0.03 0.015];
Alphas = [0.1 0.2 0.15];

% Blade uses aerofoils in this order
x = [1 1 2 3 2];

[a, cl, cd] = liftAndDrag(x, LiftCoeffs, DragCoeffs, Alphas);

disp('Alpha (rad):'); disp(a)
disp('Cl:'); disp(cl)
disp('Cd:'); disp(cd)

fprintf('Expected:\n');
fprintf('alpha = [0.1 0.1 0.2 0.15 0.2]\n');
fprintf('Cl    = [1.2 1.2 0.9 1.4 0.9]\n');
fprintf('Cd    = [0.02 0.02 0.03 0.015 0.03]\n\n');



fprintf('==============================\n');
fprintf('TEST 4: Output Size Check\n');
fprintf('==============================\n');

[a, cl, cd] = liftAndDrag('NACA4412');

fprintf('Length(alpha) = %d (expected %d)\n', length(a), nSections);
fprintf('Length(Cl)    = %d (expected %d)\n', length(cl), nSections);
fprintf('Length(Cd)    = %d (expected %d)\n\n', length(cd), nSections);



fprintf('==============================\n');
fprintf('All tests completed\n');
fprintf('==============================\n');