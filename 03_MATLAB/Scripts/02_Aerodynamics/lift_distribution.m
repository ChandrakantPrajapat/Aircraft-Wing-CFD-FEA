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
% SPANWISE LOCATION
%% =====================================

N = 200;

y = linspace(-b/2, b/2, N);

%% =====================================
% ELLIPTICAL LIFT DISTRIBUTION
%% =====================================

L_total = W;

L_prime = ...
    (4 * L_total) / (pi * b) .* ...
    sqrt(1 - (2*y/b).^2);

%% =====================================
% PLOT LIFT DISTRIBUTION
%% =====================================

figure;

plot(y, L_prime,...
    'LineWidth',2);

xlabel('Spanwise Location y (m)');

ylabel('Lift Distribution L''(y) [N/m]');

title('Elliptical Lift Distribution');

grid on;

output_png = fullfile(...
    projectRoot(),...
    '03_MATLAB',...
    'Figures',...
    'Aerodynamics',...
    'lift_distribution.png');

saveas(gcf, output_png);

%% =====================================
% TOTAL LIFT VALIDATION
%% =====================================

Lift_Check = trapz(y, L_prime);

fprintf('\nIntegrated Lift = %.2f N\n', Lift_Check);

fprintf('Aircraft Weight = %.2f N\n', W);

%% =====================================
% EXPORT DATA
%% =====================================

Lift_Data = table(y', L_prime',...
    'VariableNames',...
    {'Spanwise_Location_m',...
    'Lift_Distribution_N_per_m'});

output_csv = fullfile(...
    projectRoot(),...
    '03_MATLAB',...
    'Results',...
    'Aerodynamics',...
    'lift_distribution.csv');

writetable(Lift_Data, output_csv);

fprintf('\nLift distribution exported.\n');