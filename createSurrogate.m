function [fx, success] = createSurrogate(airfoil, force_construct, alpha_range)
% CREATESURROGATE Create or load a cached surrogate for an airfoil.
%
% Inputs:
%   airfoil - e.g. 'NACA2412'
%   force_construct - optional logical, default false
%   alpha_range - optional sweep in degrees, default -10:1:12
%
% Output:
%   fx - function handle returning [CL, CD] for alpha in radians
%   success - true if the surrogate was loaded or built successfully

if nargin < 2
    force_construct = false;
end
if nargin < 3
    alpha_range = -10:1:12;
end

alpha_range = alpha_range(:)';
cache_file = fullfile(fileparts(mfilename('fullpath')), 'surrogate_cache.mat');

Re = 60000;
Mach = 0;
MIN_VALID_POINTS = 3;

success = false;
if ~force_construct
    cached_entry = loadCachedSurrogate(cache_file, airfoil, alpha_range, Re, Mach);
    if ~isempty(cached_entry)
        fx = buildFastSurrogate(cached_entry.alpha, cached_entry.CL, cached_entry.CD);
        fprintf('Loaded surrogate for %s from cache.\n', airfoil);
        success = true;
        return;
    end
end

fprintf('Creating surrogate for %s...\n', airfoil);

try
    min_alpha = min(alpha_range);
    max_alpha = max(alpha_range);

    if numel(alpha_range) > 1
        diffs = diff(sort(alpha_range));
        step_size = min(diffs(diffs > 0));
    else
        step_size = 1;
    end

    fprintf('  Sweep 1: Positive angles (0 to %.1f) with step size %.2f...\n', max_alpha, step_size);
    alpha_pos = 0:step_size:max_alpha;
    if ~isempty(alpha_pos)
        polar_pos = callXfoil(airfoil, alpha_pos, Re, Mach);
        valid_idx_pos = ~isnan(polar_pos.CL) & ~isnan(polar_pos.CD);
        alpha_valid_pos = polar_pos.alpha(valid_idx_pos);
        CL_valid_pos = polar_pos.CL(valid_idx_pos);
        CD_valid_pos = polar_pos.CD(valid_idx_pos);
        fprintf('    Found %d valid points in positive sweep\n', sum(valid_idx_pos));
    else
        alpha_valid_pos = [];
        CL_valid_pos = [];
        CD_valid_pos = [];
        fprintf('    No positive angles requested\n');
    end

    fprintf('  Sweep 2: Negative angles (%.1f to %.1f) with step size %.2f...\n', -step_size, min_alpha, step_size);
    alpha_neg = -step_size:-step_size:min_alpha;
    if ~isempty(alpha_neg)
        polar_neg = callXfoil(airfoil, alpha_neg, Re, Mach);
        valid_idx_neg = ~isnan(polar_neg.CL) & ~isnan(polar_neg.CD);
        alpha_valid_neg = polar_neg.alpha(valid_idx_neg);
        CL_valid_neg = polar_neg.CL(valid_idx_neg);
        CD_valid_neg = polar_neg.CD(valid_idx_neg);
        fprintf('    Found %d valid points in negative sweep\n', sum(valid_idx_neg));
    else
        alpha_valid_neg = [];
        CL_valid_neg = [];
        CD_valid_neg = [];
        fprintf('    No negative angles requested\n');
    end

    alpha_valid = [alpha_valid_neg; alpha_valid_pos];
    CL_valid = [CL_valid_neg; CL_valid_pos];
    CD_valid = [CD_valid_neg; CD_valid_pos];

    num_valid = length(alpha_valid);
    fprintf('  Total valid data points: %d\n', num_valid);

    if num_valid < MIN_VALID_POINTS
        error('XFOIL_CONVERGENCE:InsufficientData', ...
            'Failed to create surrogate for %s: only %d valid points (minimum %d required).', ...
            airfoil, num_valid, MIN_VALID_POINTS);
    end

    fprintf('XFOIL runs successful. Creating surrogate...\n');
    fx = buildFastSurrogate(alpha_valid, CL_valid, CD_valid);

    saveCachedSurrogate(cache_file, airfoil, alpha_range, Re, Mach, alpha_valid, CL_valid, CD_valid);

    fprintf('Successfully created and cached surrogate for %s.\n', airfoil);
    success = true;
catch ME
    fx = @(x) deal(zeros(size(x)), zeros(size(x)));
    fprintf('Error: %s\n', ME.message);
    success = false;
end

end

function cached_entry = loadCachedSurrogate(cache_file, airfoil, alpha_range, Re, Mach)
cached_entry = [];
if ~exist(cache_file, 'file')
    return;
end

loaded = load(cache_file);
if ~isfield(loaded, 'surrogate_cache')
    return;
end

surrogate_cache = loaded.surrogate_cache;
for i = 1:numel(surrogate_cache)
    entry = surrogate_cache(i);
    if strcmpi(entry.airfoil, airfoil) && isequal(entry.alpha_range, alpha_range) && ...
            isequal(entry.Re, Re) && isequal(entry.Mach, Mach)
        cached_entry = entry;
        return;
    end
end
end

function saveCachedSurrogate(cache_file, airfoil, alpha_range, Re, Mach, alpha, CL, CD)
if exist(cache_file, 'file')
    loaded = load(cache_file);
    if isfield(loaded, 'surrogate_cache')
        surrogate_cache = loaded.surrogate_cache;
    else
        surrogate_cache = struct('airfoil', {}, 'alpha_range', {}, 'Re', {}, 'Mach', {}, ...
            'alpha', {}, 'CL', {}, 'CD', {});
    end
else
    surrogate_cache = struct('airfoil', {}, 'alpha_range', {}, 'Re', {}, 'Mach', {}, ...
        'alpha', {}, 'CL', {}, 'CD', {});
end

new_entry = struct('airfoil', airfoil, 'alpha_range', alpha_range, 'Re', Re, 'Mach', Mach, ...
    'alpha', alpha, 'CL', CL, 'CD', CD);

replaced = false;
for i = 1:numel(surrogate_cache)
    entry = surrogate_cache(i);
    if strcmpi(entry.airfoil, airfoil) && isequal(entry.alpha_range, alpha_range) && ...
            isequal(entry.Re, Re) && isequal(entry.Mach, Mach)
        surrogate_cache(i) = new_entry;
        replaced = true;
        break
    end
end

if ~replaced
    surrogate_cache(end+1) = new_entry; %#ok<AGROW>
end

save(cache_file, 'surrogate_cache');
end

function fx = buildFastSurrogate(alpha_valid_deg, CL_valid, CD_valid)
[alpha_sorted, sort_idx] = sort(alpha_valid_deg);
CL_sorted = CL_valid(sort_idx);
CD_sorted = CD_valid(sort_idx);

pp_CL = pchip(alpha_sorted, CL_sorted);
pp_CD = pchip(alpha_sorted, CD_sorted);

n_pts = length(alpha_sorted);
n_low = min(3, n_pts);
n_high = min(3, n_pts);

p_CL_low = polyfit(alpha_sorted(1:n_low), CL_sorted(1:n_low), 1);
p_CD_low = polyfit(alpha_sorted(1:n_low), CD_sorted(1:n_low), 1);
p_CD_high = polyfit(alpha_sorted(end-n_high+1:end), CD_sorted(end-n_high+1:end), 1);

CL_max = CL_sorted(end);
alpha_min = alpha_sorted(1);
alpha_max = alpha_sorted(end);
decay_factor = 0.95;

fx = @(alpha_rad) fastInterp(alpha_rad, pp_CL, pp_CD, alpha_min, alpha_max, ...
    p_CL_low, p_CD_low, p_CD_high, CL_max, decay_factor);
end

function [CL, CD] = fastInterp(alpha_rad, pp_CL, pp_CD, alpha_min, alpha_max, ...
    p_CL_low, p_CD_low, p_CD_high, CL_max, decay_factor)
alpha_deg = alpha_rad * 180 / pi;

CL = zeros(size(alpha_deg));
CD = zeros(size(alpha_deg));

in_range = (alpha_deg >= alpha_min) & (alpha_deg <= alpha_max);
below = alpha_deg < alpha_min;
above = alpha_deg > alpha_max;

if any(in_range)
    CL(in_range) = ppval(pp_CL, alpha_deg(in_range));
    CD(in_range) = ppval(pp_CD, alpha_deg(in_range));
end

if any(below)
    CL(below) = polyval(p_CL_low, alpha_deg(below));
    CD(below) = polyval(p_CD_low, alpha_deg(below));
end

if any(above)
    CL(above) = CL_max * decay_factor;
    CD(above) = polyval(p_CD_high, alpha_deg(above));
end
end
