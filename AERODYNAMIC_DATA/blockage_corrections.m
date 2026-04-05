function data_corrected = blockage_corrections(data, tailOff, At, TCStar)
    % Calculate the blockage correction for propOn using 
    % At - Tunnel area
    % TCStar - Thrust Coefficient wrt prop
    CLw      = tailOff.Cl;
    Ksb      = data.Ksb;
    V_model  = data.V_model;
    S_wing   = data.S;
    CD       = data.CD;
    eps_sb   = Ksb* V_model/ (At^(3/2));
    alpha_up = 0;
    
    % eps_wb = 0.25 * data.CD;   % placeholder, replace if needed
    eps_wb  = (S_wing * CD) / (4 * At); % attached flow, separated eps = 0
    eps_ss  = slipstream_interference(TCStar);
    eps_tot = eps_sb + eps_wb + eps_ss;

    
    % ---------- 2) Recompute coefficients ----------
    data_corrected.q       = data.q       .* (1 + eps_tot).^2;
    data_corrected.CL      = data.CL      ./ (1 + eps_tot).^2;
    data_corrected.CD      = data.CD      ./ (1 + eps_tot).^2;
    data_corrected.CY      = data.CY      ./ (1 + eps_tot).^2;
    data_corrected.CMroll  = data.CMroll  ./ (1 + eps_tot).^2;
    data_corrected.CMpitch = data.CMpitch ./ (1 + eps_tot).^2;
    data_corrected.CMyaw   = data.CMyaw   ./ (1 + eps_tot).^2;

    dalpha_w           = data.delta .* CLw .* 57.3;
    dalpha_up_rad      = deg2rad(alpha_up);
    data_corrected.AoA = data.AoA + alpha_up + dalpha_w;


    dCD_up = CLw .* dalpha_up_rad;
    dCD_w  = data.delta .* CLw.^2;
    data_corrected.CD = CDu + dCD_up + dCD_w;

    % data_corrected.CMpitch = data_corrected.CMpitch - dCm_dCL .* data_corrected.CMroll; % What is dCM_dCL value
    
end