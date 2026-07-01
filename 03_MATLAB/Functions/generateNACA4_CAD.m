function [X,Y] = generateNACA4_CAD(m,p,t,c)

%% ----------------------------------------------------
% 100-Point CAD Airfoil Generator
% Output:
% 50 Upper + 50 Lower = 100 points
% Cosine spacing for smooth CATIA spline
%% ----------------------------------------------------

N = 50;

beta = linspace(0,pi,N);

x = (1-cos(beta))/2;

%% Thickness

yt = 5*t*( ...
0.2969*sqrt(x) ...
-0.1260*x ...
-0.3516*x.^2 ...
+0.2843*x.^3 ...
-0.1015*x.^4);

%% Camber

yc = zeros(size(x));
dyc = zeros(size(x));

for i = 1:length(x)

    if x(i) <= p

        yc(i)=m/p^2*(2*p*x(i)-x(i)^2);
        dyc(i)=2*m/p^2*(p-x(i));

    else

        yc(i)=m/(1-p)^2*((1-2*p)+2*p*x(i)-x(i)^2);
        dyc(i)=2*m/(1-p)^2*(p-x(i));

    end

end

theta = atan(dyc);

%% Upper Surface

xu = x - yt.*sin(theta);
yu = yc + yt.*cos(theta);

%% Lower Surface

xl = x + yt.*sin(theta);
yl = yc - yt.*cos(theta);

%% Assemble

X_upper = flip(xu);
Y_upper = flip(yu);

X_lower = xl;
Y_lower = yl;

% Remove duplicated leading edge only
X_lower(1) = [];
Y_lower(1) = [];

X = [X_upper X_lower];
Y = [Y_upper Y_lower];

% Duplicate trailing edge to obtain 100 points
X(end+1)=X(1);
Y(end+1)=Y(1);

%% Scale

X = X*c;
Y = Y*c;

end