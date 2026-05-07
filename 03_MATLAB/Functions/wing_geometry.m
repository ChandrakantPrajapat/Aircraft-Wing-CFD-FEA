function [b, c_root, c_tip, MAC] = wing_geometry(S, AR, lambda)

b = sqrt(AR * S);

c_root = (2*S) / (b*(1 + lambda));

c_tip = lambda * c_root;

MAC = (2/3) * c_root * ...
      ((1 + lambda + lambda^2) / (1 + lambda));

end