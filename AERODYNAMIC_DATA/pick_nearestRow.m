function idx = pick_nearestRow(struct_1, struct_2)
% if we are not expecting to find matching AoA and AoS  
% in the two structs
% matches Velocity, and rudder angle
% #### Must have AOA and AoS as fields in the struct ####

vector_distance = (struct_1.AoA - struct_2.AoA).^2 + (struct_1.AoS - struct_2.AoS).^2;
[~, idx_angles] = min(vector_distance);

% Match rudder deflection
% find those values in 
idx_dR = find(abs(struct_1.dR - struct_2.dR) <= 0.01); 
idx_V  = find(abs(struct_1.V(idx_dR) - struct_2.V(idx_dR)) <= 0.05);


idx = intersect(idx_angles, idx_V);

end