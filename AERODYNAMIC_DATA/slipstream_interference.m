function eps_ss = slipstream_interference(TCStar)
    % Performs Slipstream blockage calculation. TCStar values must be aligned 
    % with the values in combined blocks
    At = 2.07;
    dia_prop = 0.2032;
    Sp = pi * dia_prop^2/4;
    eps_ss = -TCStar / (2 * sqrt(1+2*TCStar))  * Sp/At;
    % tunnel area (formula is C, we use At)
    
end