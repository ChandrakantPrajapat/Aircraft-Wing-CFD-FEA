clc;
clear;
close all;

%% =====================================
% INPUT PARAMETERS
%% =====================================

g = 9.81;

MTOW = 4500;

W = MTOW * g;

S = 17.73;

AR = 9;

b = sqrt(AR * S);

%% =====================================
% LOAD FACTORS
%% =====================================

n_limit = 3.8;

n_ultimate = 1.5 * n_limit;

fprintf('Ultimate Load Factor = %.2f\n', n_ultimate);

%% =====================================
% ROOT BENDING MOMENT
%% =====================================

M_root = (n_ultimate * W * b) / 8;

fprintf('\nRoot Bending Moment = %.2f N-m\n', M_root);

%% =====================================
% SPAR GEOMETRY ASSUMPTIONS
%% =====================================

spar_height = 0.24;     % meters

fprintf('\nSpar Height = %.3f m\n', spar_height);

%% =====================================
% MATERIAL PROPERTIES
%% =====================================

sigma_yield = 300e6;    % Pa

FS = 1.5;

sigma_allow = sigma_yield / FS;

fprintf('\nAllowable Stress = %.2f MPa\n',...
    sigma_allow/1e6);

%% =====================================
% REQUIRED SECTION MODULUS
%% =====================================

Z_required = M_root / sigma_allow;

fprintf('\nRequired Section Modulus = %.6f m^3\n',...
    Z_required);

%% =====================================
% SPAR CAP AREA ESTIMATION
%% =====================================

A_cap = Z_required / spar_height;

fprintf('\nEstimated Spar Cap Area = %.6f m^2\n',...
    A_cap);

fprintf('Estimated Spar Cap Area = %.2f cm^2\n',...
    A_cap * 1e4);

%% =====================================
% WEB SHEAR ESTIMATION
%% =====================================

V_root = (n_ultimate * W) / 2;

fprintf('\nRoot Shear Force = %.2f N\n', V_root);

tau_allow = 0.5 * sigma_allow;

web_thickness = ...
    V_root / (tau_allow * spar_height);

fprintf('\nEstimated Web Thickness = %.4f mm\n',...
    web_thickness * 1000);

%% =====================================
% RESULTS TABLE
%% =====================================

Results = table(...
    M_root,...
    Z_required,...
    A_cap,...
    web_thickness,...
    V_root);

disp(Results);

%% =====================================
% EXPORT RESULTS
%% =====================================

output_csv = fullfile(...
    projectRoot(),...
    '03_MATLAB',...
    'Results',...
    'Structures',...
    'preliminary_spar_sizing.csv');

writetable(Results, output_csv);

%% =====================================
% ENGINEERING BAR PLOT
%% =====================================

Values = [...
    M_root/1000,...
    A_cap*1e4,...
    web_thickness*1000];

Labels = {...
    'Root Moment (kN-m)',...
    'Cap Area (cm^2)',...
    'Web Thickness (mm)'};

figure;

b = bar(Values);

xticklabels(Labels);

ylabel('Magnitude');

title('Preliminary Spar Sizing');

grid on;

%% =====================================
% VALUE LABELS
%% =====================================

xtips = b.XEndPoints;

ytips = b.YEndPoints;

value_labels = string(round(Values,2));

text(xtips,...
     ytips,...
     value_labels,...
     'HorizontalAlignment','center',...
     'VerticalAlignment','bottom',...
     'FontWeight','bold');

%% =====================================
% SAVE FIGURE
%% =====================================

output_png = fullfile(...
    projectRoot(),...
    '03_MATLAB',...
    'Figures',...
    'Structures',...
    'preliminary_spar_sizing.png');

saveas(gcf, output_png);