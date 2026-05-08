clc;
clear;
close all;

%% =====================================
% AIRCRAFT PARAMETERS
%% =====================================

g = 9.81;

MTOW = 4500;

W = MTOW * g;

AR = 9;

S = 17.73;

%% =====================================
% WING GEOMETRY
%% =====================================

b = sqrt(AR * S);

fprintf('Wing Span = %.2f m\n', b);

%% =====================================
% HALF SPAN ANALYSIS
%% =====================================
%% =====================================
% SPANWISE LOCATION
%% =====================================

N = 500;

y = linspace(0, b/2, N)';

disp(class(y))
disp(size(y))

%% =====================================
% ELLIPTICAL LIFT DISTRIBUTION
%% =====================================

L_total = W;

L_prime = ...
    ((4 * L_total) / (pi * b)) .* ...
    sqrt(1 - (2*y/b).^2);

disp(class(L_prime))
disp(size(L_prime))

%% =====================================
% SHEAR FORCE CALCULATION
%% =====================================

V = flipud( ...
    cumtrapz( ...
        flipud(y), ...
        flipud(L_prime)));

%% =====================================
% BENDING MOMENT CALCULATION
%% =====================================

M = flipud( ...
    cumtrapz( ...
        flipud(y), ...
        flipud(V)));

%% =====================================
% ROOT LOADS
%% =====================================

Root_Shear = max(V);

Root_Bending_Moment = max(M);

fprintf('\nRoot Shear Force = %.2f N\n', ...
    Root_Shear);

fprintf('Root Bending Moment = %.2f N-m\n', ...
    Root_Bending_Moment);

%% =====================================
% SHEAR FORCE PLOT
%% =====================================

figure;

plot(y, V,...
    'LineWidth',2);

xlabel('Spanwise Location y (m)');

ylabel('Shear Force V(y) [N]');

title('Wing Shear Force Distribution');

grid on;

output_png = fullfile(...
    projectRoot(),...
    '03_MATLAB',...
    'Figures',...
    'Structures',...
    'shear_force_distribution.png');

saveas(gcf, output_png);

%% =====================================
% BENDING MOMENT PLOT
%% =====================================

figure;

plot(y, M,...
    'LineWidth',2);

xlabel('Spanwise Location y (m)');

ylabel('Bending Moment M(y) [N-m]');

title('Wing Bending Moment Distribution');

grid on;

output_png = fullfile(...
    projectRoot(),...
    '03_MATLAB',...
    'Figures',...
    'Structures',...
    'bending_moment_distribution.png');

saveas(gcf, output_png);

%% =====================================
% EXPORT RESULTS
%% =====================================

Load_Data = table(...
    y',...
    L_prime',...
    V',...
    M',...
    'VariableNames',...
    {'Spanwise_Location_m',...
     'Lift_Distribution_N_per_m',...
     'Shear_Force_N',...
     'Bending_Moment_Nm'});

output_csv = fullfile(...
    projectRoot(),...
    '03_MATLAB',...
    'Results',...
    'Structures',...
    'structural_load_distribution.csv');

writetable(Load_Data, output_csv);

fprintf('\nStructural load data exported.\n'); 