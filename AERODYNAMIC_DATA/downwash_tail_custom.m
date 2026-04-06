function [dalpha_t, dCM_025_t] = downwash_tail_custom(CL_wing)
% DOWNWASH_TAIL_CUSTOM
% Pitching moment correction due to tail downwash.
%
% Input:
%   CL_wing : wing lift coefficient (tail-off lift coefficient)
%
% Outputs:
%   dalpha_t : downwash correction at tail [rad]
%   dCM_025_t: pitching moment correction due to tail downwash

S    = 0.2172;   % wing area [m^2]
C    = 2.07;     % tunnel cross-sectional area [m^2]
S_t  = 0.0858;   % horizontal tail area [m^2]
l_t  = 0.535;    % tail arm [m]
c    = 0.165;    % mean aerodynamic chord [m]
AR   = 8.98;     % wing aspect ratio
AR_t = 3.87;     % tail aspect ratio

delta      = 0.10375;
tau_2_tail = 0.7;

dalpha_t = delta * S / C .* CL_wing .* (1 + tau_2_tail);

dCM_025_dalpha_t = -((S_t * l_t) / (S * c)) * ((0.1 * AR) / (AR_t + 2));
dCM_025_t        = dCM_025_dalpha_t .* dalpha_t;

end