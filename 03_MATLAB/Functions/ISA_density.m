function rho = ISA_density(h)

T0 = 288.15;
P0 = 101325;
L = 0.0065;
R = 287.05;
g = 9.81;

T = T0 - L*h;

P = P0 * (T/T0)^(g/(R*L));

rho = P / (R*T);

end