function [TCWing, TCStar, TC, C_T] = thrust_DNW(propOn, propOff, tailOff)
% Outputs [TCWing, TCStar, TC, C_T] based on the DNW's Method
TCWing = zeros(size(propOn.AoA, 1)); %thrust coefficient wrt wing
TCStar = zeros(size(propOn.AoA, 1)); %thrust coefficient wrt prop
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
    n = propOn.rpsM1(i);

    k = .6;
    S_wing = propOff.S;
    b = 0.576;
    AR = 3.87;
    D = 0.2032;
    A_prop = pi/4 * D^2;

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

    T = (CT_propOn - CT_propOff) * q * S_wing
    CT_guess = T / (2* A_prop * q);

    iter_max = 1e3;
    tol = 1e-4;
    iter_counter = 0;
    CT_iter = 1e5; % unrealistic high value

    while (iter_counter < iter_max) && (abs(CT_iter - CT_guess))
        % q_ ratio = q_e / q_inf
        q_ratio = 1 + 2 * k * D/b * ...
        sqrt((sqrt(1+CT_guess)+1)/(2 * sqrt(1 + CT_guess))) * CT_guess;
        CL_CT = (CL_propOff - CL_tailOff) * q_ratio;
        CD_CT = (CD_propOff - CD_tailOff) - CL_CT^2/(pi*AR) * (q_ratio^2 - 1);
        
        % Thrust Components in Wind Axes
        CT_X = cd - CD_propOff - CD_CT; % Thrust in X = Drag
        CT_Z = cl - CL_propOff - CL_CT; % Thrust in Z = Lift
        CT_Y =  sqrt((CT_X^2 + CT_Z^2) / (cosd(AoA)*sind(AoS)^-2 - 1));


        TCWing_guess = sqrt(CT_X^2 + CT_Y^2 + CT_Z^2);
        CT_iter = (TCWing_guess/2) * S_wing / A_prop;

        iter_counter = iter_counter + 1;
    end

    TCWing(i) = TCWing_guess; 
    TCStar(i) = 0.5 * TCWing(i) * S_wing/A_prop; 
    C_T(i) = TCWing_guess * S_wing * V^2/2 / (2 * n^2 * D^4);
    % Per propeller 
    TC(i) = C_T(i)/J^2;

end
end