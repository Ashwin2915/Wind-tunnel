
function dataOut = apply_modeloff_correction(dataIn, modelOff)
% Apply model-off correction using:
% Cx(a,b) = Cx(a,0) + Cx(0,b) - Cx(0,0)

dataOut = dataIn;

AoA = dataIn.AoA(:);
AoS = dataIn.AoS(:);

coeffNames = {'CD','CY','CL','CMroll','CMpitch','CMyaw'};

for k = 1:numel(coeffNames)
    nm = coeffNames{k};

    % force interpolation tables to columns too
    alphaA = modelOff.alpha0.AoA(:);
    alphaC = modelOff.alpha0.(nm)(:);

    betaB  = modelOff.beta0.AoS(:);
    betaC  = modelOff.beta0.(nm)(:);

    % interpolated model-off terms
    C_a0 = interp1(alphaA, alphaC, AoA, 'linear', 'extrap');
    C_0b = interp1(betaB,  betaC,  AoS, 'linear', 'extrap');

    % make sure both are columns
    C_a0 = C_a0(:);
    C_0b = C_0b(:);

    % value at alpha = 0, beta = 0
    C_00_a = interp1(alphaA, alphaC, 0, 'linear', 'extrap');
    C_00_b = interp1(betaB,  betaC,  0, 'linear', 'extrap');
    C_00 = 0.5 * (C_00_a + C_00_b);

    % total model-off correction
    C_modeloff = C_a0 + C_0b - C_00;

    % subtract from measured coefficient
    dataOut.(nm) = dataIn.(nm)(:) - C_modeloff;

    % optional: store correction itself
    dataOut.([nm '_modeloff']) = C_modeloff;
end
end

% function dataOut = apply_modeloff_correction(dataIn, modelOff)
% % Apply model-off correction using:
% % Cx(a,b) = Cx(a,0) + Cx(0,b) - Cx(0,0)

% dataOut = dataIn;

% AoA = dataIn.AoA(:);
% AoS = dataIn.AoS(:);

% coeffNames = {'CD','CY','CL','CMroll','CMpitch','CMyaw'};

% for k = 1:numel(coeffNames)
%     nm = coeffNames{k};

%     % values from AoA sweep at beta = 0
%     C_a0 = interp1(modelOff.alpha0.AoA, modelOff.alpha0.(nm), AoA, 'linear', 'extrap');

%     % values from AoS sweep at alpha = 0
%     C_0b = interp1(modelOff.beta0.AoS, modelOff.beta0.(nm), AoS, 'linear', 'extrap');

%     % value at alpha = 0, beta = 0
%     C_00_a = interp1(modelOff.alpha0.AoA, modelOff.alpha0.(nm), 0, 'linear', 'extrap');
%     C_00_b = interp1(modelOff.beta0.AoS, modelOff.beta0.(nm), 0, 'linear', 'extrap');
%     C_00 = 0.5 * (C_00_a + C_00_b);   % average the two estimates

%     % total model-off correction
%     C_modeloff = C_a0 + C_0b - C_00;

%     % subtract from measured coefficient
%     dataOut.(nm) = dataIn.(nm) - C_modeloff;

%     % optional: store correction itself
%     dataOut.([nm '_modeloff']) = C_modeloff;
% end
% end
