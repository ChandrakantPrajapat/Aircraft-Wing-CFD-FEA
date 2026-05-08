clc;
clear;
close all;

%% =====================================
% WING GEOMETRY
%% =====================================

S = 17.73;

AR = 9;

lambda = 0.4;

b = sqrt(AR * S);

c_root = 2.005;

c_tip = lambda * c_root;

%% =====================================
% SPAR LOCATIONS
%% =====================================

front_spar = 0.25;

rear_spar = 0.65;

fprintf('Front Spar = %.0f%% chord\n',...
    front_spar*100);

fprintf('Rear Spar = %.0f%% chord\n',...
    rear_spar*100);

%% =====================================
% ROOT SECTION DIMENSIONS
%% =====================================

front_spar_root = front_spar * c_root;

rear_spar_root = rear_spar * c_root;

wingbox_width_root = ...
    rear_spar_root - front_spar_root;

fprintf('\nRoot Wing Box Width = %.3f m\n',...
    wingbox_width_root);

%% =====================================
% TIP SECTION DIMENSIONS
%% =====================================

front_spar_tip = front_spar * c_tip;

rear_spar_tip = rear_spar * c_tip;

wingbox_width_tip = ...
    rear_spar_tip - front_spar_tip;

fprintf('Tip Wing Box Width = %.3f m\n',...
    wingbox_width_tip);

%% =====================================
% RIB SPACING
%% =====================================

rib_spacing = 0.5;

semi_span = b/2;

num_ribs = floor(semi_span / rib_spacing);

fprintf('\nNumber of Ribs per Half Wing = %d\n',...
    num_ribs);

%% =====================================
% SKIN THICKNESS
%% =====================================

skin_thickness = 0.003;

fprintf('\nSkin Thickness = %.1f mm\n',...
    skin_thickness*1000);

%% =====================================
% RIB LOCATIONS
%% =====================================

rib_locations = ...
    linspace(0, semi_span, num_ribs);

%% =====================================
% STRUCTURAL LAYOUT PLOT
%% =====================================

figure;

hold on;
axis equal;
grid on;

%% =====================================
% LEADING EDGE SWEEP
%% =====================================

sweep_LE = 5;

x_le_tip = tand(sweep_LE) * semi_span;

%% =====================================
% WING CORNERS
%% =====================================

x_root_LE = 0;
x_root_TE = c_root;

x_tip_LE = x_le_tip;
x_tip_TE = x_tip_LE + c_tip;

%% =====================================
% WING OUTLINE
%% =====================================

x_wing = [...
    0,...
    semi_span,...
    semi_span,...
    0];

y_wing = [...
    x_root_LE,...
    x_tip_LE,...
    x_tip_TE,...
    x_root_TE];

fill(x_wing,...
     y_wing,...
     [0.85 0.85 0.85]);

%% =====================================
% FRONT SPAR
%% =====================================

front_spar_x_root = ...
    x_root_LE + front_spar*c_root;

front_spar_x_tip = ...
    x_tip_LE + front_spar*c_tip;

plot([0 semi_span],...
     [front_spar_x_root front_spar_x_tip],...
     'b','LineWidth',3);

%% =====================================
% REAR SPAR
%% =====================================

rear_spar_x_root = ...
    x_root_LE + rear_spar*c_root;

rear_spar_x_tip = ...
    x_tip_LE + rear_spar*c_tip;

plot([0 semi_span],...
     [rear_spar_x_root rear_spar_x_tip],...
     'r','LineWidth',3);

%% =====================================
% RIBS
%% =====================================

for i = 1:length(rib_locations)

    eta = rib_locations(i)/semi_span;

    local_chord = ...
        c_root - (c_root-c_tip)*eta;

    y_le_local = ...
        tand(sweep_LE) * rib_locations(i);

    y_te_local = ...
        y_le_local + local_chord;

    plot([rib_locations(i) rib_locations(i)],...
         [y_le_local y_te_local],...
         'k--');

end

%% =====================================
% POINT MARKERS
%% =====================================

plot(0,x_root_LE,...
    'ko','MarkerFaceColor','k');

plot(0,x_root_TE,...
    'ko','MarkerFaceColor','k');

plot(semi_span,x_tip_LE,...
    'ko','MarkerFaceColor','k');

plot(semi_span,x_tip_TE,...
    'ko','MarkerFaceColor','k');

%% =====================================
% LABELS
%% =====================================

text(0,x_root_LE,...
    ' Root LE',...
    'FontWeight','bold');

text(0,x_root_TE,...
    ' Root TE',...
    'FontWeight','bold');

text(semi_span,x_tip_LE,...
    ' Tip LE',...
    'FontWeight','bold');

text(semi_span,x_tip_TE,...
    ' Tip TE',...
    'FontWeight','bold');

text(0,...
     front_spar_x_root,...
     ' Front Spar',...
     'Color','b',...
     'FontWeight','bold');

text(0,...
     rear_spar_x_root,...
     ' Rear Spar',...
     'Color','r',...
     'FontWeight','bold');

%% =====================================
% COORDINATE ANNOTATIONS
%% =====================================

text(0,...
     front_spar_x_root,...
     sprintf('(%.2f, %.2f)',...
     0,...
     front_spar_x_root),...
     'FontSize',8,...
     'Color','b');

text(semi_span,...
     front_spar_x_tip,...
     sprintf('(%.2f, %.2f)',...
     semi_span,...
     front_spar_x_tip),...
     'FontSize',8,...
     'Color','b');

%% =====================================
% AXES
%% =====================================

xlabel('Spanwise Direction (m)');

ylabel('Chordwise Direction (m)');

title('Wing Box Structural Layout');

legend(...
    'Wing Planform',...
    'Front Spar',...
    'Rear Spar');

set(gca,...
    'FontSize',12,...
    'LineWidth',1.2);

%% =====================================
% SAVE FIGURE
%% =====================================

output_png = fullfile(...
    projectRoot(),...
    '03_MATLAB',...
    'Figures',...
    'Structures',...
    'wing_box_layout.png');

saveas(gcf, output_png);