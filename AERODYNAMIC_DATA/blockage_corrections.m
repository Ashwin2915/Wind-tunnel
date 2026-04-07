function data_corrected = blockage_corrections(data, tailOff, At, TCStar)
    % Calculate the blockage correction for propOn using 
    % At - Tunnel area
    % TCStar - Thrust Coefficient wrt prop
    CLw      = reshape(tailOff.CL, 1, []);
    Ksb      = reshape(data.Ksb, 1, []);
    V_model  = reshape(data.Vol_model, 1, []);
    CD       = reshape(data.CD, 1, []);
    S_wing   = data.S;
    eps_sb   = Ksb* V_model/ (At^(3/2));
    alpha_up = 0;
    c        = data.c;
    
    % eps_wb = 0.25 * data.CD;   % placeholder, replace if needed
    eps_wb  = (S_wing * CD) / (4 * At); % attached flow, separated eps = 0
    eps_ss  = slipstream_interference(TCStar);
    eps_tot = eps_sb + eps_wb + eps_ss;

    
    % ---------- 2) Recompute coefficients ----------
    data_corrected.q       = reshape(data.q,1,[])       .* (1 + eps_tot).^2;
    data_corrected.CL      = reshape(data.CL,1,[])      ./ (1 + eps_tot).^2; % corrected lift coefficient
    data_corrected.CD      = reshape(data.CD,1,[])      ./ (1 + eps_tot).^2; 
    data_corrected.CY      = reshape(data.CY,1,[])      ./ (1 + eps_tot).^2; % corrected side-force coefficient
    data_corrected.CMroll  = reshape(data.CMroll,1,[])  ./ (1 + eps_tot).^2; % corrected rolling-moment coefficient
    data_corrected.CMpitch = reshape(data.CMpitch,1,[]) ./ (1 + eps_tot).^2; % corrected pitching-moment coefficient
    data_corrected.CMyaw   = reshape(data.CMyaw,1,[])   ./ (1 + eps_tot).^2;

    dalpha_w           = data.delta .* CLw .* 57.3;
    dalpha_up_rad      = deg2rad(alpha_up);
    data_corrected.AoA = data.AoA + alpha_up + dalpha_w;
    data_corrected.AoS = data.AoS;


    dCD_up = CLw .* dalpha_up_rad;
    dCD_w  = data.delta .* CLw.^2;
    CDu = data_corrected.CD;
    data_corrected.CD = reshape(CDu, 1,[]) + dCD_up + dCD_w;

    % data_corrected.CMpitch = data_corrected.CMpitch - dCm_dCL .* data_corrected.CMroll;  % corrected pitching-moment coefficient
    % What is dCM_dCL value ^


    %% Downwash Correction
    % del_alphaT = delta S_wing/c

end


