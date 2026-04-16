% TESTCREATESURROGATE Basic check for the provided surrogate code.
clear all; close all; clc;

airfoil = 'NACA0015';
default_range = -10:1:12;
wide_range = -15:1:15;
alpha_test_deg = -25:0.5:25;
alpha_test_rad = alpha_test_deg * pi/180;

fprintf('Testing createSurrogate for %s\n', airfoil);

[fx_default, success_default] = createSurrogate(airfoil, false, default_range);
[fx_wide, success_wide] = createSurrogate(airfoil, false, wide_range);

if ~success_default || ~success_wide
    error('Could not build the requested surrogate(s). Check your XFOIL setup first.');
end

[CL_default, CD_default] = fx_default(alpha_test_rad);
[CL_wide, CD_wide] = fx_wide(alpha_test_rad);

figure('Position', [100, 100, 950, 420]);

subplot(1,2,1);
plot(alpha_test_deg, CL_default, 'b-', 'LineWidth', 2); hold on;
plot(alpha_test_deg, CL_wide, 'r--', 'LineWidth', 2);
grid on;
xlabel('Angle of attack (deg)');
ylabel('C_L');
title(['Lift coefficient - ' airfoil]);
legend('default range', 'wider range', 'Location', 'best');

subplot(1,2,2);
plot(alpha_test_deg, CD_default, 'b-', 'LineWidth', 2); hold on;
plot(alpha_test_deg, CD_wide, 'r--', 'LineWidth', 2);
grid on;
xlabel('Angle of attack (deg)');
ylabel('C_D');
title(['Drag coefficient - ' airfoil]);
legend('default range', 'wider range', 'Location', 'best');

fprintf('\nSample values at 5 degrees:\n');
[cl_default_5, cd_default_5] = fx_default(5*pi/180);
[cl_wide_5, cd_wide_5] = fx_wide(5*pi/180);
fprintf('  default range: CL = %.4f, CD = %.4f\n', cl_default_5, cd_default_5);
fprintf('  wider range:   CL = %.4f, CD = %.4f\n', cl_wide_5, cd_wide_5);

fprintf('\nNote: createSurrogate takes angle ranges in degrees, but fx expects radians.\n');
