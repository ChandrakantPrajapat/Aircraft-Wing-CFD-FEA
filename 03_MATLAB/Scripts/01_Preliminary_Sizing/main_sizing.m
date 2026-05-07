clc;
clear;
close all;

%% =====================================
% AIRCRAFT PARAMETERS
%% =====================================

g = 9.81;

MTOW = 4500;
W = MTOW * g;

V_cruise = 130;
altitude = 7000;

CL_cruise = 0.5;

AR = 9;
lambda = 0.4;

CL_max = 2.0;

%% =====================================
% ATMOSPHERIC CONDITIONS
%% =====================================

rho = ISA_density(altitude);

fprintf('Air Density = %.3f kg/m^3\n', rho);

%% =====================================
% WING AREA
%% =====================================

S = W / (0.5 * rho * V_cruise^2 * CL_cruise);

fprintf('\nWing Area = %.2f m^2\n', S);

%% =====================================
% WING GEOMETRY
%% =====================================

[b, c_root, c_tip, MAC] = wing_geometry(S, AR, lambda);

fprintf('\nWing Span = %.2f m\n', b);
fprintf('Root Chord = %.2f m\n', c_root);
fprintf('Tip Chord = %.2f m\n', c_tip);
fprintf('MAC = %.2f m\n', MAC);

%% =====================================
% STALL SPEED
%% =====================================

V_stall = stall_speed(W, S, CL_max);

fprintf('\nStall Speed = %.2f m/s\n', V_stall);

%% =====================================
% DRAG ESTIMATION
%% =====================================

e = 0.82;

CD0 = 0.025;

CDi = induced_drag(CL_cruise, AR, e);

CD_total = CD0 + CDi;

fprintf('\nInduced Drag Coefficient = %.4f\n', CDi);
fprintf('Total Drag Coefficient = %.4f\n', CD_total);

%% =====================================
% L/D RATIO
%% =====================================

LD = CL_cruise / CD_total;

fprintf('\nLift-to-Drag Ratio = %.2f\n', LD);

%% =====================================
% WING LOADING
%% =====================================

Wing_Loading = W / S;

fprintf('\nWing Loading = %.2f N/m^2\n', Wing_Loading);

%% =====================================
% RESULTS TABLE
%% =====================================

Results = table(...
    S,...
    b,...
    c_root,...
    c_tip,...
    MAC,...
    V_stall,...
    LD,...
    Wing_Loading);

disp(Results);

%% =====================================
% EXPORT RESULTS
%% =====================================

output_csv = fullfile(...
    projectRoot(),...
    '03_MATLAB',...
    'Results',...
    'Aerodynamics',...
    'initial_sizing_results.csv');

writetable(Results, output_csv);

%% =====================================
% NORMALIZED PARAMETER PLOT
%% =====================================

Parameters = [S b MAC Wing_Loading];

Normalized_Parameters = ...
    Parameters ./ max(Parameters);

figure;

bar(Normalized_Parameters);

xticklabels({...
    'Wing Area',...
    'Span',...
    'MAC',...
    'Wing Loading'});

ylabel('Normalized Value');

title('Normalized Wing Parameters');

grid on;

output_png = fullfile(...
    projectRoot(),...
    '03_MATLAB',...
    'Figures',...
    'Aerodynamics',...
    'normalized_initial_sizing.png');

saveas(gcf, output_png);