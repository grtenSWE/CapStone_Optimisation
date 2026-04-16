global Vu rho eta nSections clearance B R Curve

Vu = 6.0;
R = 0.75;
Curve = @generator;
rho = 1.29;
eta = 0.6;
nSections = 15;
clearance = 0.1;
B = 3;

chord = linspace(0.30, 0.14, nSections);
beta = linspace(40, 14, nSections) * pi/180;
design = [chord, beta];

name = 'NACA0012';
[fx, success] = createSurrogate(name, -10:25);
obj = turbineObj(design, fx);
disp(obj);

function RPM = generator(Q)
    if Q > 4.8
        RPM = 314.0*Q-1200.0;
    elseif Q >= 0
        RPM = 1.25*(279-sqrt(77841.0-16000.0*Q));
    else
        RPM = -generator(-Q);
    end
end