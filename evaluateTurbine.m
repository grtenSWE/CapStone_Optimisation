function [obj, speed] = evaluateTurbine(fx, c, beta)
    % This function evaluates a turbine design, given a set of properties in a
    % format suitable for optimisation using metaheuristics.
    %
    % Inputs:  f - A fast (er than xFoil) function that we return the lift and
    %              drag coefficients of our aerofoil for a given angle of
    %              attack
    %           c - A 1D array of length nSections, containing the chord length
    %               for each section
    %           beta - a 1D array of length nSections, containing the blade
    %                  setting angle for each section
    % Outputs:  obj = objective value of interest, to be defined for the
    %                 application. Usually, Cp.
    %           speed = The RPM of the turbine
    %
    % Author: Chris Oliver
    % UPI: coli772
    % ID: 921085653
    % Date: 23/03/2026
    
    % Constants (to go into params)
    global Vu rho eta nSections clearance B R Curve
    
    % Radial positions
    r = linspace(clearance, R, nSections);
    
    % Initial tip speed ratio
    lambda = 1.0;
    tol = 1e-6;
    maxIter = 1000;
    
    % Relaxation factors
    xi_inner = 0.2;
    xi_outer = 0.3;
    
    % Stability
    sigma = (B .* c) ./ (2 * pi .* r);
    
    % Initial induction factors
    a  = 0.33 * ones(1, nSections);
    ap = zeros(1, nSections);
    
    % Outer loop for tip-speed ratio
    for outer = 1:maxIter
        % Local TSR
        lambda_r = lambda .* (r ./ R);
        
        % Inner loop for induction convergence
        for inner = 1:maxIter
            % Flow angle
            phi = atan2((1 - a), (lambda_r .* (1 + ap)));
            phi = max(phi, 1e-4);
            
            % Angle of attack
            alpha = phi - beta;
            
            % Aero coefficients
            [Cl, Cd] = fx(alpha);
            
            % Force coefficients
            Cn = Cl .* cos(phi) + Cd .* sin(phi);
            Ct = Cl .* sin(phi) - Cd .* cos(phi);
            
            % Denominator protection
            den_a  = 4 .* sin(phi).^2 + sigma .* Cn;
            den_ap = 4 .* sin(phi) .* cos(phi) - sigma .* Ct;
            den_a  = sign(den_a)  .* max(abs(den_a), 1e-6);
            den_ap = sign(den_ap) .* max(abs(den_ap), 1e-6);
    
            a_new  = (sigma .* Cn) ./ den_a;
            ap_new = (sigma .* Ct) ./ den_ap;
    
            % Physical Limitations
            a_new = clip(a_new, 0, 0.5);
    
            ae  = max(abs(a_new - a));
            ape = max(abs(ap_new - ap));
            
            % Relaxation
            a  = a  + xi_inner .* (a_new  - a);
            ap = ap + xi_inner .* (ap_new - ap);
            
            % Convergence check
            if max(ae, ape) < tol
                break;
            end
        end
        
        % Torque per unit length
        pT = (rho * Vu^2 .* ((1 - a).^2 .* Ct .* c) ./ (2 .* sin(phi).^2));
        
        % Total torque
        Q = B * trapz(r, pT .* r);
        
        % Generator curve
        speed = Curve(Q);
        
        % Updated TSR
        lambda_new = (pi * R * speed) / (30 * Vu);
        
        % Outer relaxation    
        lambda_e = abs(lambda_new - lambda);
        lambda = lambda + xi_outer .* (lambda_new - lambda);
        
        if lambda_e < tol
            break;
        end
    end
    
    % Final power
    Omega = speed * pi / 30;
    PE = Q * Omega * eta;
    
    % Outputs
    obj = PE;
end