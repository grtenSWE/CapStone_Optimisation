function [pol, foil] = callXfoil(coord, alpha, Re, Mach)
% This function acts as a general interface to xfoil.m by Louis Edelmann:
% https://au.mathworks.com/matlabcentral/fileexchange/49706-xfoil-interface-updated
%
% Inputs: coord = coordinates of aerofoil.
%                     3 cases: 1. 'NACAxxxxx' for NACA 4 or 5 digits
%                              2. 'xxxx.dat' for an aerofoil in the airfoil
%                              bank. 
%                              3. an n by 2 array of x and y
%                              coordinates.
%                   For non NACA cases, 300 panel points are interpolated to
%                   hopefully give convergence. In all cases, max 100
%                   iterations are run.
%         alpha = angle(s) of attack to consider Re = Reynold's number of
%         interest. Mach = Mach number of interest. Typically 0 for
%         incompressible flow.
% Outputs: see xfoil.m
%
% This code is supplied with an adapted version of the UIUC Airfoil
% Database (http://m-selig.ae.illinois.edu/ads/coord_database.html) by
% Michael Selig. Divahar Jayaraman adapted these to a consistent format in
% her code for 2D Potential Flows, as found below...
% http://au.mathworks.com/matlabcentral/fileexchange/12790-panel-method-based-2-d-potential-flow-simulator
% This is used by loading the 'airfoil bank' folder into the path when
% needed.
%
% Kevin Jia, UoA EngSci, 2017-2019.
% Edited / fixed by Nick Wright 2025/2026

% Add xfoil subdirectory to path
xfoilDir = fullfile(fileparts(mfilename('fullpath')), 'xfoil');
addpath(xfoilDir);

if isa(coord, 'char') == true && strcmp(coord(1:4), 'NACA') == true
    % A built in NACA airfoil.
    pol = xfoil(coord, alpha, Re, Mach, 'pane n 2000/', 'oper/iter 100');
elseif isa(coord, 'char') == true && strcmp(coord(length(coord)-3:length(coord)), '.dat')
    % An aerofoil in the airfoil bank folder.
    addpath('airfoil bank')
    if exist(coord, 'file')
        % Import data, first remove heading.
        data = importdata(coord, ' ', 1);
        coordinates = data.data;
        pol = xfoil(coordinates, alpha, Re, Mach, 'pane n 2000/', 'oper/iter 100');
    else
        error('.dat file does not exist')
    end
    
else
    % 2D array of coordinates
    pol = xfoil(coord, alpha, Re, Mach, 'pane n 2000/', 'oper/iter 100');
end

pol = checkPol(pol, alpha);
foil = 0;
return

function polOut = checkPol(polIn, alpha)

if length(polIn.alpha) ~= length(alpha)
    % Lengths do not match, need to do an interpolation for some angle(s).
    
    % Copy structure
    polOut = polIn; 
    % Find missing angles
    existingInds = ismembertol(alpha', polIn.alpha, 1e-4);
    missingInds = ~ismembertol(alpha', polIn.alpha, 1e-4);
    needToFind = alpha(missingInds);
    missingLifts = interp1(polIn.alpha, polIn.CL, needToFind, 'linear', 'extrap'); 
    missingDrags = interp1(polIn.alpha, polIn.CD, needToFind, 'linear', 'extrap'); 
    
    allLifts(existingInds) = polIn.CL;
    allLifts(missingInds) = missingLifts;
    
    allDrags(existingInds) = polIn.CD;
    allDrags(missingInds) = missingDrags;
    
    polOut.CL = allLifts';
    polOut.CD = allDrags';
    polOut.alpha = alpha';
    
else
    polOut = polIn;
end

return
