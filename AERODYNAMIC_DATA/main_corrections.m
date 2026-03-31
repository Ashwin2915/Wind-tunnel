%% Main processing file LTT data AE4115 lab exercise
% T Sinnige
% updated: 19 December 2024

%% Initialization
clear
close all
clc

%% Inputs

% define root path on disk where data is stored
diskPath = 'C:\Group_16_Redo_BAL\BAL_redo';

% get indices balance and pressure data files
[idxB] = SUP_getIdx;

% filename(s) of the raw balance files
fn_BAL = {'raw_rudder_0_block1.txt','raw_rudder_0_block3.txt','raw_rudder_0_block4.txt', ...
          'raw_rudder_m10_block6_7.txt','raw_rudder_p5_block7b.txt', ...
          'raw_rudder_p10_block1.txt','raw_rudder_p10_block5.txt'};

% filename(s) of the zero-measurement (tare) data files
fn0 = {'z.txt', 'z.txt', 'z.txt', 'z.txt', 'z.txt', 'z.txt', 'z.txt'};

% wing geometry
b     = 1.4*cosd(4); % span [m]
cR    = 0.222;       % root chord [m]
cT    = 0.089;       % tip chord [m]
S     = b/2*(cT+cR); % reference area [m^2]
taper = cT/cR;       % taper ratio
c     = 2*cR/3*(1+taper+taper^2)/(1+taper); % mean aerodynamic chord [m]

% prop geometry
D = 0.2032; % propeller diameter [m]
R = D/2;    % propeller radius [m]

% moment reference points
XmRefB = [0,0,0.0465/c];
XmRefM = [0.25,0,0];

% incidence angle settings
dAoA      = 0.0;
dAoS      = 0.0;
modelType = 'aircraft'; % options: aircraft, 3dwing, halfwing
modelPos  = 'inverted'; % options: normal, inverted
testSec   = 5;          % test-section number

%% Run the processing code to get balance and pressure data
BAL = BAL_process(diskPath,fn_BAL,fn0,idxB,D,S,b,c,XmRefB,XmRefM,dAoA,dAoS,modelType,modelPos,testSec);

%% User inputs for corrections

At = 2.07;      % tunnel test-section area [m^2]
alpha_up = 0.0; % tunnel upflow correction [deg]


%% not including struts
%% 0.0259787

V_model = struct();
V_model.rudder_0_block1     = 0.022;
V_model.rudder_0_block3     = 0.022;
V_model.rudder_0_block4     = 0.022;
V_model.rudder_m10_block6_7 = 0.022;
V_model.rudder_p5_block7b   = 0.022;
V_model.rudder_p10_block1   = 0.022;
V_model.rudder_p10_block5   = 0.022;


%% what should this be ?
Ksb = struct();
Ksb.rudder_0_block1     = 0.90;
Ksb.rudder_0_block3     = 0.90;
Ksb.rudder_0_block4     = 0.90;
Ksb.rudder_m10_block6_7 = 0.90;
Ksb.rudder_p5_block7b   = 0.90;
Ksb.rudder_p10_block1   = 0.90;
Ksb.rudder_p10_block5   = 0.90;

delta = struct();
delta.rudder_0_block1     = 0.0;
delta.rudder_0_block3     = 0.0;
delta.rudder_0_block4     = 0.0;
delta.rudder_m10_block6_7 = 0.0;
delta.rudder_p5_block7b   = 0.0;
delta.rudder_p10_block1   = 0.0;
delta.rudder_p10_block5   = 0.0;

dCm_dCL = struct();
dCm_dCL.rudder_0_block1     = 0.0;
dCm_dCL.rudder_0_block3     = 0.0;
dCm_dCL.rudder_0_block4     = 0.0;
dCm_dCL.rudder_m10_block6_7 = 0.0;
dCm_dCL.rudder_p5_block7b   = 0.0;
dCm_dCL.rudder_p10_block1   = 0.0;
dCm_dCL.rudder_p10_block5   = 0.0;

%% Apply corrections

cfgNames = fieldnames(BAL.windOn);
nCfg = numel(cfgNames);

BALc = BAL; % corrected copy

% -------------------------------------------------------------
% Store all data in separate lists
% -------------------------------------------------------------

cfg_list = cfgNames;

% raw data
AoA_list     = cell(nCfg,1);
AoS_list     = cell(nCfg,1);
q_list       = cell(nCfg,1);
CL_list      = cell(nCfg,1);
CD_list      = cell(nCfg,1);
CY_list      = cell(nCfg,1);
CMroll_list  = cell(nCfg,1);
CMpitch_list = cell(nCfg,1);
CMyaw_list   = cell(nCfg,1);

% corrected data
q_corr_list       = cell(nCfg,1);
AoA_corr_list     = cell(nCfg,1);
CL_corr_list      = cell(nCfg,1);
CD_corr_list      = cell(nCfg,1);
CY_corr_list      = cell(nCfg,1);
CMroll_corr_list  = cell(nCfg,1);
CMpitch_corr_list = cell(nCfg,1);
CMyaw_corr_list   = cell(nCfg,1);

% correction terms
eps_sb_list  = cell(nCfg,1);
eps_wb_list  = cell(nCfg,1);
eps_tot_list = cell(nCfg,1);


CLw_data = load('CLw_lookup.mat');
%% fieldnames(CLw_data)
%% cfgNames

for i = 1:nCfg
    nm = cfgNames{i};
    D0 = BAL.windOn.(nm);

    CLw = CLw_data.(nm);
    CLw = CLw(:);

    if numel(CLw) ~= numel(D0.AoA)
        error('Size mismatch for %s: CLw has %d points, raw data has %d points.', ...
            nm,numel(CLw), numel(D0.AoA));
    end

    % ---------- 1) Blockage corrections ----------
    eps_sb = Ksb.(nm) * V_model.(nm) / (At^(3/2));
    %% eps_wb = 0.25 * D0.CD;   % placeholder, replace if needed
    eps_wb = (S * D0.CD) / (4 * At);
    eps_tot = eps_sb + eps_wb;

    q_old = D0.q;
    q_corr = q_old .* (1 + eps_tot).^2;

    % ---------- 2) Recompute coefficients with corrected q ----------
    CLu = D0.CL      .* (q_old ./ q_corr);
    CDu = D0.CD      .* (q_old ./ q_corr);
    CYu = D0.CY      .* (q_old ./ q_corr);
    Clu = D0.CMroll  .* (q_old ./ q_corr);
    Cmu = D0.CMpitch .* (q_old ./ q_corr);
    Cnu = D0.CMyaw   .* (q_old ./ q_corr);

    % ---------- 3) Wall corrections ----------
    dalpha_w = delta.(nm) .* CLw .* 57.3;
    dalpha_up_rad = deg2rad(alpha_up);

    AoA_corr = D0.AoA + alpha_up + dalpha_w;

    dCD_up = CLw .* dalpha_up_rad;
    dCD_w  = delta.(nm) .* CLw.^2;
    CDc = CDu + dCD_up + dCD_w;

    CLc = CLu;
    CYc = CYu;
    Clc = Clu;
    %% DOUBLE CHECK
    Cmc = Cmu - dCm_dCL.(nm) .* CLu;   %% Clu or Clw ??????? #####################################################################
    %% DOUBLE CHECK
    Cnc = Cnu;

    % ---------- store corrected data in BALc ----------
    BALc.windOn.(nm).eps_sb       = eps_sb;
    BALc.windOn.(nm).eps_wb       = eps_wb;
    BALc.windOn.(nm).eps_tot      = eps_tot;
    BALc.windOn.(nm).q_corr       = q_corr;

    BALc.windOn.(nm).AoA_corr     = AoA_corr;
    BALc.windOn.(nm).CL_corr      = CLc;
    BALc.windOn.(nm).CD_corr      = CDc;
    BALc.windOn.(nm).CY_corr      = CYc;
    BALc.windOn.(nm).CMroll_corr  = Clc;
    BALc.windOn.(nm).CMpitch_corr = Cmc;
    BALc.windOn.(nm).CMyaw_corr   = Cnc;

    % ---------- save raw data ----------
    AoA_list{i}     = D0.AoA;
    AoS_list{i}     = D0.AoS;
    q_list{i}       = D0.q;
    CL_list{i}      = D0.CL;
    CD_list{i}      = D0.CD;
    CY_list{i}      = D0.CY;
    CMroll_list{i}  = D0.CMroll;
    CMpitch_list{i} = D0.CMpitch;
    CMyaw_list{i}   = D0.CMyaw;

    % ---------- save corrected data ----------
    q_corr_list{i}       = q_corr;
    AoA_corr_list{i}     = AoA_corr;
    CL_corr_list{i}      = CLc;
    CD_corr_list{i}      = CDc;
    CY_corr_list{i}      = CYc;
    CMroll_corr_list{i}  = Clc;
    CMpitch_corr_list{i} = Cmc;
    CMyaw_corr_list{i}   = Cnc;

    % ---------- save correction terms ----------
    eps_sb_list{i}  = eps_sb;
    eps_wb_list{i}  = eps_wb;
    eps_tot_list{i} = eps_tot;
end

%% Optional: save all extracted lists to a .mat file
save('Extracted_BAL_Data.mat', ...
    'cfg_list', ...
    'AoA_list','AoS_list','q_list','CL_list','CD_list','CY_list', ...
    'CMroll_list','CMpitch_list','CMyaw_list', ...
    'q_corr_list','AoA_corr_list','CL_corr_list','CD_corr_list','CY_corr_list', ...
    'CMroll_corr_list','CMpitch_corr_list','CMyaw_corr_list', ...
    'eps_sb_list','eps_wb_list','eps_tot_list','BALc');

%% Example visualization

figure; box on; hold on; grid on
for i = 1:nCfg
    nm = cfgNames{i};
    idx = abs(BALc.windOn.(nm).AoS) < 0.01;
    plot(BALc.windOn.(nm).AoA_corr(idx), BALc.windOn.(nm).CL_corr(idx), 'o-', ...
        'DisplayName', nm)
end
xlabel('Corrected angle of attack \alpha_c [deg]')
ylabel('Corrected lift coefficient C_L')
legend('Location','best')

figure; box on; hold on; grid on
for i = 1:nCfg
    nm = cfgNames{i};
    idx = abs(BALc.windOn.(nm).AoS) < 0.01;
    plot(BALc.windOn.(nm).AoA_corr(idx), BALc.windOn.(nm).CD_corr(idx), 'o-', ...
        'DisplayName', nm)
end
xlabel('Corrected angle of attack \alpha_c [deg]')
ylabel('Corrected drag coefficient C_D')
legend('Location','best')

figure; box on; hold on; grid on
for i = 1:nCfg
    nm = cfgNames{i};
    idx = abs(BALc.windOn.(nm).AoS) < 0.01;
    plot(BALc.windOn.(nm).AoA_corr(idx), BALc.windOn.(nm).CMpitch_corr(idx), 'o-', ...
        'DisplayName', nm)
end
xlabel('Corrected angle of attack \alpha_c [deg]')
ylabel('Corrected pitching moment coefficient C_m')
legend('Location','best')

disp(eps_sb_list)