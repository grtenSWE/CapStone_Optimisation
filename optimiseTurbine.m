function results = optimiseTurbine()
% OPTIMISETURBINE Outer-loop scaffold for comparing candidate airfoils.
%
% Suggested core steps:
%   1. choose a small list of candidate airfoils
%   2. build a surrogate for each one
%   3. call optimiseTurbineGivenShape
%   4. store the best result for each airfoil
%   5. identify the best overall candidate

results = struct();

% Suggested starting list:
% airfoil_candidates = {
%     'NACA0012', ...
%     'NACA2412', ...
%     'NACA4415'
% };

% TODO: implement this file.
% Keep the core case simple:
%   - one blade count, e.g. B = 5
%   - one constant airfoil shape across the blade
%   - basic error handling if surrogate construction fails

error('optimiseTurbine:NotImplemented', 'Complete optimiseTurbine.m before using it.');
end
