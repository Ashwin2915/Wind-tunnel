function [TCWing, TCStar, TC, C_T] = thrust_DNW(propOn, propOff, tailOff)
% Outputs [TCWing, TCStar, TC, C_T] based on the DNW method

nPts = numel(propOn.AoA);

TCWing = zeros(1,nPts);   % thrust coefficient wrt wing
TCStar = zeros(1,nPts);   % thrust coefficient wrt prop disk
TC     = zeros(1,nPts);
C_T    = zeros(1,nPts);

for i = 1:nPts
    AoA = propOn.AoA(i);
    AoS = propOn.AoS(i);
    V   = propOn.V(i);
    dR  = propOn.dR(i);
    rho = propOn.rho(i);
    q   = propOn.q(i);
    J   = propOn.J(i);
    cd  = propOn.CD(i);
    cl  = propOn.CL(i);
    CT_propOn = propOn.CT(i);
    n   = propOn.rpsM1(i);

    k = 0.6;
    S_wing = propOff.S;
    b = 0.576;
    AR = 3.87;
    D = 0.2032;
    A_prop = pi/4 * D^2;

    % -------------------------------------------------------------
    % Find matching point in propOff
    % -------------------------------------------------------------
    idx_propOff = find_match_index(propOff, AoA, AoS, V, dR);

    % -------------------------------------------------------------
    % Find matching point in tailOff
    % -------------------------------------------------------------
    idx_tailOff = find_match_index(tailOff, AoA, AoS, V, dR);

    % Extract matched coefficients
    CT_propOff = propOff.CT(idx_propOff);
    CL_propOff = propOff.CL(idx_propOff);
    CD_propOff = propOff.CD(idx_propOff);

    CT_tailOff = tailOff.CT(idx_tailOff);
    CL_tailOff = tailOff.CL(idx_tailOff);
    CD_tailOff = tailOff.CD(idx_tailOff);

    % Initial thrust estimate
    T = (CT_propOn - CT_propOff) * q * S_wing;
    CT_guess = T / (2 * A_prop * q);

    if isempty(CT_guess) || ~isfinite(CT_guess)
        error('CT_guess invalid at i = %d', i);
    end

    iter_max = 1000;
    tol = 1e-4;
    iter_counter = 0;
    CT_iter = 1e5;

    TCWing_guess = NaN;

    while (iter_counter < iter_max) && (abs(CT_iter - CT_guess) > tol)

        q_ratio = 1 + 2 * k * D/b * ...
            sqrt((sqrt(1 + CT_guess) + 1) / (2 * sqrt(1 + CT_guess))) * CT_guess;

        CL_CT = (CL_propOff - CL_tailOff) * q_ratio;
        CD_CT = (CD_propOff - CD_tailOff) - CL_CT^2/(pi * AR) * (q_ratio^2 - 1);

        % Thrust components in wind axes
        CT_X = cd - CD_propOff - CD_CT;
        CT_Z = cl - CL_propOff - CL_CT;

        % Safer handling near AoS = 0
        sAoS = sind(AoS);
        denom = cosd(AoA) * (1 / (sAoS^2)) - 1;

        if abs(sAoS) < 1e-8 || denom <= 0
            CT_Y = 0;
        else
            CT_Y = sqrt((CT_X^2 + CT_Z^2) / denom);
        end

        TCWing_guess = sqrt(CT_X^2 + CT_Y^2 + CT_Z^2);
        CT_iter = 0.5 * TCWing_guess * S_wing / A_prop;

        CT_guess = CT_iter;
        iter_counter = iter_counter + 1;
    end

    if isnan(TCWing_guess)
        error('Iteration failed before TCWing_guess was computed at i = %d', i);
    end

    TCWing(i) = TCWing_guess;
    TCStar(i) = 0.5 * TCWing(i) * S_wing / A_prop;
    C_T(i)    = TCWing_guess * S_wing * V^2 / 2 / (2 * n^2 * D^4);
    TC(i)     = C_T(i) / J^2;
end

end


function idx_best = find_match_index(dataStruct, AoA, AoS, V, dR)

tol_V = 0.05;

idx_candidates = find(abs(dataStruct.V - V) <= tol_V);

if isempty(idx_candidates)
    error('No V match found. Requested V = %.3f', V);
end

dist = (dataStruct.AoA(idx_candidates) - AoA).^2 + ...
       (dataStruct.AoS(idx_candidates) - AoS).^2;

[~, kbest] = min(dist);
idx_best = idx_candidates(kbest);

end


% % function [TCWing, TCStar, TC, C_T] = thrust_DNW(propOn, propOff, tailOff)
% % Outputs [TCWing, TCStar, TC, C_T] based on the DNW's Method
% TCWing = zeros(size(propOn.AoA, 1)); %thrust coefficient wrt wing
% TCStar = zeros(size(propOn.AoA, 1)); %thrust coefficient wrt prop
% TC     = zeros(size(propOn.AoA, 1));
% C_T    = zeros(size(propOn.AoA, 1));
% 
% for i = 1:length(propOn.AoA)
%     AoA = propOn.AoA(i); 
%     AoS = propOn.AoS(i); 
%     V = propOn.V(i);
%     dR = propOn.dR(i);
%     rho = propOn.rho(i);
%     q = propOn.q(i);
%     J = propOn.J(i);
%     cd = propOn.CD(i);
%     cl = propOn.CL(i);
%     CT_propOn = propOn.CT(i);
%     n = propOn.rpsM1(i);
% 
%     k = .6;
%     S_wing = propOff.S;
%     b = 0.576;
%     AR = 3.87;
%     D = 0.2032;
%     A_prop = pi/4 * D^2;
% 
%     vector_distance = (AoA - propOff.AoA).^2 + (AoS - propOff.AoS).^2;
%     [~, idx_angles] = min(vector_distance);
% 
%     % Match rudder deflection
%     % find those values in velocity
%     idx_dR = find(abs(dR - propOff.dR) <= 0.01);
%     idx_V  = find(abs(V - propOff.V(idx_dR)) <= 0.05);
% 
%     idx = intersect(idx_angles, idx_V);
%     CT_propOff = propOff.CT(idx); CT_tailOff = tailOff.CT(idx);
%     CL_propOff = propOff.CL(idx); CL_tailOff = tailOff.CL(idx);
%     CD_propOff = propOff.CD(idx); CD_tailOff = tailOff.CD(idx);
% 
%     T = (CT_propOn - CT_propOff) * q * S_wing;
%     CT_guess = T / (2* A_prop * q);
% 
%     iter_max = 1e3;
%     tol = 1e-4;
%     iter_counter = 0;
%     CT_iter = 1e5; % unrealistic high value
% 
%     while (iter_counter < iter_max) && (abs(CT_iter - CT_guess))
%         % q_ ratio = q_e / q_inf
%         q_ratio = 1 + 2 * k * D/b * ...
%         sqrt((sqrt(1+CT_guess)+1)/(2 * sqrt(1 + CT_guess))) * CT_guess;
%         CL_CT = (CL_propOff - CL_tailOff) * q_ratio;
%         CD_CT = (CD_propOff - CD_tailOff) - CL_CT^2/(pi*AR) * (q_ratio^2 - 1);
% 
%         % Thrust Components in Wind Axes
%         CT_X = cd - CD_propOff - CD_CT; % Thrust in X = Drag
%         CT_Z = cl - CL_propOff - CL_CT; % Thrust in Z = Lift
%         CT_Y =  sqrt((CT_X^2 + CT_Z^2) / (cosd(AoA)*sind(AoS)^-2 - 1));
% 
% 
%         TCWing_guess = sqrt(CT_X^2 + CT_Y^2 + CT_Z^2);
%         CT_iter = (TCWing_guess/2) * S_wing / A_prop;
% 
%         iter_counter = iter_counter + 1;
%     end
% 
%     TCWing(i) = TCWing_guess; 
%     TCStar(i) = 0.5 * TCWing(i) * S_wing/A_prop; 
%     C_T(i) = TCWing_guess * S_wing * V^2/2 / (2 * n^2 * D^4);
%     % Per propeller 
%     TC(i) = C_T(i)/J^2;
% 
% end
% end 
