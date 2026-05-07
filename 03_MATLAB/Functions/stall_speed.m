function V_stall = stall_speed(W, S, CL_max)

rho0 = 1.225;

V_stall = sqrt((2*W)/(rho0*S*CL_max));

end