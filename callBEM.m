% Example calls to evaluateTurbine()
% Defines required global vars.

global Vu rho eta nSections clearance B Re R Curve optimise_c

Vu = 5;             % Design speed, e.g. 5m/s
R = 0.75;           % Outside radius of the turbine
Curve = @generator; % Function relating torque to RPM of the generator
rho = 1.29;         % Density of air
eta = 1;            % System efficiency
nSections = 15;
clearance = 0.1;    % Radius of hub + any further distance with no blade section allowed.
B = 5;              % Number of blades
Re = 100000;        % Approximate Reynolds number for design
optimise_c = false;

% ----------------------------------
% Example 1: Single Airfoil
% ----------------------------------
[alpha, Cl, Cd] = liftAndDrag('NACA0012');
[obj1, design1] = BEM(alpha, Cl, Cd);

disp(obj1)
disp(design1)

fprintf('Example 1 (fixed airfoil):\nPE  = %7.3f\nRPM = %7.3f\nCp  = %7.3f\n\n', obj1, design1.RPM, design1.Cp);
% ----------------------------------
% Example 2: Multiple Airfoils
% ----------------------------------
testArray = {'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', ...
     'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat'};
[alpha, Cl, Cd] = liftAndDrag(testArray);
[obj2, design2] = BEM(alpha, Cl, Cd);

fprintf('Example 2 (multiple airfoils):\nPE  = %7.3f\nRPM = %7.3f\nCp  = %7.3f\n\n', obj2, design2.RPM, design2.Cp);

% ----------------------------------
% Example 3: Arbitrary CL, CD, alpha
% ----------------------------------
CL = [1.3054    0.8773    0.6231];
CD = [0.0126    0.0110    0.0123];
Alphas = [0.0873    0.0785    0.0873]; % in radians
x = [1 1 1 1 2 2 2 2 2 2 3 3 3 3 1];

[alpha, Cl, Cd] = liftAndDrag(x, CL, CD, Alphas);
[obj3, design3] = BEM(alpha, Cl, Cd);

fprintf('Example 3 (arbitrary CL, CD, alpha):\nPE  = %7.3f\nRPM = %7.3f\nCp  = %7.3f\n\n', obj3, design3.RPM, design3.Cp);

% Helper function for generator curve.
function RPM = generator(Q)
    if Q > 4.8
        % Outside the practical range for the generator.
        RPM = 314.0*Q-1200.0;
    elseif Q >= 0
        RPM = 1.25*(279-sqrt(77841.0-16000.0*Q));
    else
        % This is bad news, but allowing the generator to deal with
        % negative torque can help with convergence
        RPM = -generator(-Q);
    end
end