function [alpha, Cl, Cd] = liftAndDrag(varargin)
    % This function evaluates a turbine design, given a set of properties in a
    % format suitable for optimisation using metaheuristics.
    % 1 Input:  x - either a string that contains the ONE aerofoil type to be
    %               used, or else a cell array that contains the aerofoil type
    %               at each cross-section.
    %            -- OR --
    % 4 Inputs: for aerofoil information already found from elsewhere
    %           Inputs must be in correct order. 
    %           1. x = 1 x n matrix containing the sequence number (1...k) of the 
    %                aerofoil to be used at each section. n == nSections
    %           2. CL = 1 x k matrix containing lift coefficient for each of k
    %           aerofoils
    %           3. CD = 1 x k matrix containing drag coefficient at optimal angle
    %           of attack for each of k aerofoils.
    %           4. alpha = 1 x k matrix containing optimal angle of attack for
    %           each of k aerofoils
    % Outputs:  alpha - A 1D array of length nSections, containing the optimal
    %                 angle of attack for the aerofoil present at each section
    %           Cl - A 1D array of length nSection, containing the lift
    %                 coefficient C_l at the optimal angle of attack for the
    %                 aerofoil at that section
    %           Cd - A 1D array of length nSection, containing the drag
    %                 coefficient C_d at the optimal angle of attack for the
    %                 aerofoil at that section
    %
    % Note: xFoil takes a long time to run! We shouldn't call it more than
    % neccessary!
    % Author: Chris Oliver
    % UPI: coli772
    % ID: 921085653
    % Date: 18/03/2026
    
    global nSections Re
    
    % CASE 1: Aerofoil(s) provided
    if nargin == 1
        x = varargin{1};
        
        % Check if multipxle aerofoils are provided (cell array)
        if isa(x, 'cell') 
    
            % Preallocate output arrays
            alpha = zeros(1, nSections);
            Cl = zeros(1, nSections);
            Cd = zeros(1, nSections);
        
            % Identify unique aerofoils to avoid redundant xFoil calls
            uniqueFoils = unique(x);
        
            % Structure to store computed results for each unique aerofoil
            foilData = struct();
        
            % Range of angles of attack (degrees) to test in xFoil
            alphaRange = 0:1:15;
        
            % Loop through each unique aerofoil and compute optimal values
            for i = 1:length(uniqueFoils)
                foil = uniqueFoils{i};
        
                % Call xFoil to get polar data
                [pol, ~] = callXfoil(foil, alphaRange, Re, 0);
        
                % Compute lift-to-drag ratio
                ratio = pol.CL ./ pol.CD;
        
                % Find index of maximum Cl/Cd
                [~, idx] = max(ratio);
        
                % Store optimal values (convert alpha to radians)
                foilData(i).name = foil;
                foilData(i).alpha = deg2rad(alphaRange(idx));
                foilData(i).Cl = pol.CL(idx);
                foilData(i).Cd = pol.CD(idx);
            end
        
            % Assign computed values to each blade section
            for i = 1:nSections
                for j = 1:length(uniqueFoils)
                    % Match section aerofoil with stored results
                    if strcmp(x{i}, foilData(j).name)
                        alpha(i) = foilData(j).alpha;
                        Cl(i) = foilData(j).Cl;
                        Cd(i) = foilData(j).Cd;
                    end
                end
            end
            
        else % Single aerofoil used across all sections
    
            % Define angle range for xFoil
            alphaRange = 0:1:15;
    
            % Run xFoil once
            [pol, ~] = callXfoil(x, alphaRange, Re, 0);
            
            % Compute lift-to-drag ratio
            ratio = pol.CL ./ pol.CD;
            
            % Find optimal angle index
            [~, idx] = max(ratio);
            
            % Extract optimal values (convert alpha to radians)
            alpha_opt = deg2rad(pol.alpha(idx));
            Cl_opt = pol.CL(idx);
            Cd_opt = pol.CD(idx);
            
            % Assign same values to all sections
            alpha = alpha_opt * ones(1, nSections);
            Cl = Cl_opt * ones(1, nSections);
            Cd = Cd_opt * ones(1, nSections);
    
        end   
    
    % CASE 2: Precomputed inputs
    elseif nargin == 4
    
        % Extract inputs
        x = varargin{1};             % Section-to-aerofoil mapping
        LiftCoeffs = varargin{2};    % CL values for each aerofoil
        DragCoeffs = varargin{3};    % CD values for each aerofoil
        Alphas = varargin{4};        % Optimal alpha values (radians)
    
        % Preallocate outputs
        alpha = zeros(1, nSections);
        Cl = zeros(1, nSections);
        Cd = zeros(1, nSections);
    
        % Assign values to each section based on mapping
        for i = 1:nSections
            idx = x(i); % Index of aerofoil used at this section
            alpha(i) = Alphas(idx);
            Cl(i) = LiftCoeffs(idx);
            Cd(i) = DragCoeffs(idx);
        end
        
    % ERROR HANDLING
    else
        error("Incorrect number of inputs")
    end
end