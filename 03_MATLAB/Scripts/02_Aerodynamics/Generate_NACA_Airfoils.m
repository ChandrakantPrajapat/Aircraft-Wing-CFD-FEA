clc
clear
close all

%% ----------------------------------------------------
% Aircraft Wing CAD Airfoil Generation
%% ----------------------------------------------------

Chord = 100;

%% Root Airfoil (NACA 2412)

[rootX,rootY] = generateNACA4_CAD(0.02,0.40,0.12,Chord);

Root = [rootX(:) rootY(:)];

exportFolder = fullfile(fileparts(mfilename('fullpath')),'..','..','Exports');

if ~exist(exportFolder,'dir')
    mkdir(exportFolder);
end

writematrix(Root,...
    fullfile(exportFolder,'Root_Airfoil_100pts.csv'));

figure('Color','w')
plot(rootX,rootY,'b-','LineWidth',1.8)
hold on
plot(rootX,rootY,'r.','MarkerSize',10)
axis equal
grid on
xlabel('X (mm)')
ylabel('Y (mm)')
title('Root Airfoil - NACA 2412')
figureFolder = fullfile(fileparts(mfilename('fullpath')),'..','..','Figures');

if ~exist(figureFolder,'dir')
    mkdir(figureFolder);
end

exportgraphics(gcf,...
    fullfile(figureFolder,'Root_Airfoil_100pts.png'),...
    'Resolution',300);

%% Tip Airfoil (NACA 2409)

[tipX,tipY] = generateNACA4_CAD(0.02,0.40,0.09,Chord);

Tip = [tipX(:) tipY(:)];

writematrix(Tip,'Tip_Airfoil_100pts.csv');

figure('Color','w')
plot(tipX,tipY,'b-','LineWidth',1.8)
hold on
plot(tipX,tipY,'r.','MarkerSize',10)
axis equal
grid on
xlabel('X (mm)')
ylabel('Y (mm)')
title('Tip Airfoil - NACA 2409')
exportgraphics(gcf,'Tip_Airfoil_100pts.png','Resolution',300);

disp('--------------------------------------')
disp('CAD Airfoil Generation Complete')
disp('Files Generated:')
disp('Root_Airfoil_100pts.csv')
disp('Tip_Airfoil_100pts.csv')
disp('Root_Airfoil_100pts.png')
disp('Tip_Airfoil_100pts.png')
disp('--------------------------------------')