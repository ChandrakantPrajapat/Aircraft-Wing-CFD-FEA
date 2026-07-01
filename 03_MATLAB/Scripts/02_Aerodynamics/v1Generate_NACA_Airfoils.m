clc;
clear;
close all;

%% PARAMETERS

N = 51;                 % target CAD point count
c = 100;                % normalized chord (mm)

%% ROOT AIRFOIL
m = 0.02;               % 2% camber
p = 0.4;                % 40% camber location
t = 0.12;               % 12% thickness

[x2412,y2412] = generateNACA4(m,p,t,N,c);

%% TIP AIRFOIL
m = 0.02;
p = 0.4;
t = 0.09;               % 9% thickness

[x2409,y2409] = generateNACA4(m,p,t,N,c);

%% SAVE FILES

rootData = [x2412(:) y2412(:)];
tipData  = [x2409(:) y2409(:)];

% writematrix(rootData,...
% '../../Exports/Root_Airfoil_CAD.csv');

% writematrix(tipData,...
% '../../Exports/Tip_Airfoil_CAD.csv');

%% PLOT

figure
plot(x2412,y2412,'LineWidth',2)
axis equal
grid on
title('NACA 2412 Root Airfoil')

figure
plot(x2409,y2409,'LineWidth',2)
axis equal
grid on
title('NACA 2409 Tip Airfoil')

% ==========================
% CATIA REDUCED POINT SET
% ==========================

nKeep = 51;

idx = round(linspace(1,length(x2412),nKeep));

X_catia = x2412(idx);
Y_catia = y2412(idx);

CATIA_Data = [X_catia(:) Y_catia(:)];

% writematrix(rootData,...
% '../../Exports/Root_Airfoil_CAD.csv');

% writematrix(tipData,...
% '../../Exports/Tip_Airfoil_CAD.csv');

disp(size(CATIA_Data))

disp(CATIA_Data(1:10,:))

disp(CATIA_Data(end-9:end,:))

writematrix(CATIA_Data,'Root_Airfoil_CATIA.csv');