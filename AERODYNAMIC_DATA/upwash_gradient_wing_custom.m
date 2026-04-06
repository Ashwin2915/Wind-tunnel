function [dalpha_sc, dCM_025_uw] = upwash_gradient_wing_custom(dalpha_uw, CL_alpha)
% UPWASH_GRADIENT_WING_CUSTOM
% Pitching moment correction due to upwash gradient at the wing.
%
% Inputs:
%   dalpha_uw : upwash correction to angle of attack [rad]
%   CL_alpha  : lift curve slope [1/rad]
%
% Outputs:
%   dalpha_sc  : streamline-curvature angle correction [rad]
%   dCM_025_uw : pitching moment correction due to upwash gradient

tau_2_wing_05c = 0.14;

dalpha_sc  = tau_2_wing_05c .* dalpha_uw;
dCM_025_uw = 0.125 .* dalpha_sc .* CL_alpha;

end