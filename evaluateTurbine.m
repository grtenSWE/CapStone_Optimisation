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
    
    % Constants (to go into params)
    global Vu rho eta nSections clearance B R Curve
    
    % Radius accross the sections of the blades
    r = linspace(clearance, R, nSections);
    
    % Initialising lambda as the tip speed ratio and starting at ideal value 
    lambda = 1;
    
    % Initialising axial induction factor accross sections at ideal value
    a = ones(1, nSections) * 0.33;
    
    % Initialising tangential induction factor accross sections at ideal value
    a_prime = zeros(1, nSections);
    
    % Convergence speed to be altered as a hyperparameter
    conv_speed = 0.1;
    
    % convergence_outer initialised to be used for loop exit later on
    converged_outer = false;
    
    
    % Capped at a set number of iterations
    for i = 1:100
        
        % Calculating rotational speed of the rotor (rad/s)
        Omega = lambda * Vu / R;
    
        % Calculating local speed ratio at each blade section
        lambda_r = Omega .* r / Vu;
        
        % convergence_outer initialised to be used for loop exit later on
        converged_inner = false;
        
    
        % Capped at a set number of iterations
        for j = 1:300
    
            % Calculating safe denominator for wind angle for convergence
            denom_wind = max(lambda_r .* (1 + a_prime), 1e-4);
            
            % Calculating safe wind_angle for convergence
            wind_angle = max((atan((1 - a) ./ denom_wind)), 1e-4);
            
            % Calculating current alpha
            alpha_current = wind_angle - beta;
    
            % Calculating lift and drag coefficients using surrogate model
            [Cl, Cd] = fx(alpha_current);
            
            % Calculating solidity accross airfoil sections
            solidity = (B * c) ./ (2 * pi .* r);
    
            % Calculating normal and tangential coefs using trig
            Cn = Cl .* cos(wind_angle) + Cd .* sin(wind_angle);
            Ct = Cl .* sin(wind_angle) - Cd .* cos(wind_angle);
            
            % Storing previous values of a values
            a_old = a;
            a_prime_old = a_prime;
            
            % Calculating safe denominator for a update
            denom_a = max(4 * sin(wind_angle).^2 + solidity .* Cn, 1e-3);
    
            % Calculating new a value
            a_new = (solidity .* Cn) ./ denom_a;
            
            % Calculating safe denominator for a prime
            denom_a_prime = 4 .* sin(wind_angle) .* cos(wind_angle) - solidity .* Ct;
            denom_a_prime = sign(denom_a_prime) .* max(abs(denom_a_prime), 1e-3);
    
            % Calculating new a prime
            a_prime_new = (solidity .* Ct) ./ denom_a_prime;
            
            % Updating actual a values based on convergence hyperparameter
            a = (1 - conv_speed) * a_old + conv_speed * a_new;
            a_prime = (1 - conv_speed) * a_prime_old + conv_speed * a_prime_new;
    
            % Clamp axial induction factor
            a = max(min(a, 0.5), 0);
            
            % Exit condition for inner loop
            if max(abs(a_old - a)) < 1e-4 && max(abs(a_prime_old - a_prime)) < 1e-4
                converged_inner = true;
                break
            end
        end
    
        % Sin floor for convergence safety
        sin_phi = max(sin(wind_angle), 0.05);
        
        % Calculating tangential load and 
        tangential_load = Ct .* c .* 0.5 * rho .* (Vu^2 * (1 - a).^2) ./ sin_phi.^2;
        Q = B * trapz(r, tangential_load .* r);
        
        % Safe lambda updates
        lambda_old = lambda;
        lambda_new = (pi * R * Curve(Q)) / (30 * Vu);
        lambda = (1 - conv_speed) * lambda_old + conv_speed * lambda_new;
        
        % Outer loop exit condition
        if abs(lambda_old - lambda) < 1e-4
            converged_outer = true;
            break
        end
    end
    
    % Graceful failure
    if ~converged_outer || ~converged_inner
        obj = 0;
        speed = 0;
        return
    end
    
    % Negative RPM check
    rpm = Curve(Q);
    if rpm < 0
        obj = 0;
        speed = rpm;
        return
    end
    
    % Final updates of values before function end
    Omega = lambda * Vu / R;
    Pe = eta * Q * Omega;
    obj = Pe;
    speed = rpm;
end