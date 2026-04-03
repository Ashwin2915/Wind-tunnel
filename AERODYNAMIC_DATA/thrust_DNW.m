function [TCWing, TCStar, TC, C_T] = thrust_DNW(propOn, propOff, tailOff)
% Outputs [TCWing, TCStar, TC, C_T] based on the DNW's Method
TCWing = zeros(size(propOn.AoA, 1));
TCStar = zeros(size(propOn.AoA, 1));
TC     = zeros(size(propOn.AoA, 1));
C_T    = zeros(size(propOn.AoA, 1));

for i = 1:length(propOn.AoA)
    AoA = propOn.AoA(i); 
    AoS = propOn.AoS(i); 
    V = propOn.V(i);
    dR = propOn.dR(i);
    rho = propOn.rho(i);
    q = propOn.q(i);
    J = propOn.J(i);
    cd = propOn.CD(i);
    cl = propOn.CL(i);
    CT_propOn = propOn.CT(i);


    vector_distance = (AoA - propOff.AoA).^2 + (AoS - propOff.AoS).^2;
    [~, idx_angles] = min(vector_distance);
    
    % Match rudder deflection
    % find those values in velocity
    idx_dR = find(abs(dR - propOff.dR) <= 0.01);
    idx_V  = find(abs(V - propOff.V(idx_dR)) <= 0.05);
    
    idx = intersect(idx_angles, idx_V);
    CT_propOff = propOff.CT(idx); CT_tailOff = tailOff.CT(idx);
    CL_propOff = propOff.CL(idx); CL_tailOff = tailOff.CL(idx);
    CD_propOff = propOff.CD(idx); CD_tailOff = tailOff.CD(idx);

    % T = (ct_propOn - )

end