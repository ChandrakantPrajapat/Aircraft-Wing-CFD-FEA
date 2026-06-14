function [X,Y] = generateNACA4(m,p,t,N,c)

beta = linspace(0,pi,N);

x = (1-cos(beta))/2;

yt = 5*t*( ...
0.2969*sqrt(x) ...
-0.1260*x ...
-0.3516*x.^2 ...
+0.2843*x.^3 ...
-0.1015*x.^4);

yc = zeros(size(x));
dyc = zeros(size(x));

for i=1:length(x)

    if x(i) < p

        yc(i)=m/p^2*(2*p*x(i)-x(i)^2);

        dyc(i)=2*m/p^2*(p-x(i));

    else

        yc(i)=m/(1-p)^2*((1-2*p)+...
        2*p*x(i)-x(i)^2);

        dyc(i)=2*m/(1-p)^2*(p-x(i));

    end

end

theta = atan(dyc);

xu = x - yt.*sin(theta);
yu = yc + yt.*cos(theta);

xl = x + yt.*sin(theta);
yl = yc - yt.*cos(theta);

X = [flip(xu) xl(2:end)]*c;
Y = [flip(yu) yl(2:end)]*c;

end