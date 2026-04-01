function [obj, design] = BEM(alpha, Cl, Cd)
    % This function evaluates a turbine design, given a set of properties in a
    % format suitable for optimisation using metaheuristics.
    %
    % Inputs:  alpha - A 1D array of length nSections, containing the optimal
    %                 angle of attack for the aerofoil present at each section
    %           Cl - A 1D array of length nSection, containing the lift
    %                 coefficient C_l at the optimal angle of attack for the
    %                 aerofoil at that section
    %           Cd - A 1D array of length nSection, containing the drag
    %                 coefficient C_d at the optimal angle of attack for the
    %                 aerofoil at that section
    % Outputs:  obj = objective value of interest, to be defined for the
    %                 application. Usually, PE.
    %           design = structure with turbine design features, specifically
    %               r = cross-sectional radii
    %               chord = chord length
    %               Cp = power coefficient
    %               alpha = angle of attack of aerofoil
    %               beta = setting angle
    %               RPM = RPM of the turbine spin
    %               Q = torque of the turbine
    %
    % Author: Chris Oliver
    % UPI: coli772
    % ID: 921085653
    % Date: 18/03/2026
    
    % Globals
    global Vu rho eta nSections clearance B R Curve optimise_c
    
    % Radial positions of blade sections
    r = linspace(clearance, R, nSections);
    
    % Initial tip speed ratio guess
    lambda = 1;
    tol = 1e-6;
    maxIter = 1000;
    
    % Initial chord (fixed unless optimisation enabled)
    c = 0.5/B * ones(1,nSections);
    
    for outer = 1:maxIter
        
        % Compute angular velocity
        Omega = lambda * Vu / R;
        lambda_r = Omega .* r ./ Vu;
        
        % Initial guesses for induction factors
        a = 0.33 * ones(1, nSections);
        ap = zeros(1, nSections);
        
        for inner = 1:maxIter
            
            a_old = a;
            ap_old = ap;
            
            % Wind angle
            phi = atan2((1 - a), (lambda_r .* (1 + ap)));
            
            % Avoid singularities
            phi = max(phi, 1e-4);
            
            if optimise_c
                c = ((8 * pi .* r) ./ (B .* Cl)) .* (1 - cos(phi));
            end
            
            sigma = (B .* c) ./ (2 * pi .*  r);
            
            % Force coefficients
            Cn = Cl .* cos(phi) + Cd .* sin(phi);
            Ct = Cl .* sin(phi) - Cd .* cos(phi);
            
            % Update equations
            a_new = (sigma .* Cn) ./ (4 .* sin(phi).^2 + sigma .* Cn);
            ap_new = (sigma .* Ct) ./ (4 .* sin(phi) .* cos(phi) - sigma .* Ct);
            
            % Physical limits
            a = max(0, min(a_new, 0.5));
            ap = max(-1, min(ap_new, 1));
            
            % Proper convergence check
            if all(abs(a - a_old) < tol) && all(abs(ap - ap_old) < tol)
                break;
            end
        end
        
        % Tangential load
        pT = (rho * Vu^2 .* ((1 - a).^2 .* Ct .* c) ./ (2 .* sin(phi).^2));
        
        % Integrate torque
        Q = B * trapz(r, pT .* r);
        
        RPM = Curve(Q);
        
        lambda_new = pi * R * RPM / (30 * Vu);
        
        % Check convergence
        if abs(lambda_new - lambda) < tol
            lambda = lambda_new;
            break;
        end
        
        lambda = lambda_new;
    end
    
    % Final power calculation
    Omega = lambda * Vu / R;
    PE = eta * Q .* Omega;
    
    PT = 0.5 * rho * pi * R^2 * Vu^3;
    Cp = PE ./ PT;
    
    % Objective
    obj = PE;
    
    beta = phi - alpha;
    
    design.r = r;
    design.chord = c;
    design.Cp = Cp;
    design.alpha = alpha;
    design.beta = beta;
    design.RPM = RPM;
    design.Q = Q;
end