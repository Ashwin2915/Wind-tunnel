%% Main processing file LTT data AE4115 lab exercise
% T Sinnige
% updated: 19 December 2024

%% Initialization
clear
close all
clc

addpath("AERODYNAMIC_DATA")
addpath("BAL_redo")
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
% BAL = BAL_process(diskPath,fn_BAL,fn0,idxB,D,S,b,c,XmRefB,XmRefM,dAoA,dAoS,modelType,modelPos,testSec);
load("BAL.mat")
% load("TailOff_BAL.mat")

% [tailOff_on_disjoint, tailOff_off_disjoint] = rudder_prop_corrector(TailOff_BAL.windOn);
% tailOff_full = blocks_superglue(tailOff_on_disjoint);

% load("AERODYNAMIC_DATA/TailOff_BAL.mat")
clear diskPath fn0 fn_BAL idxB

%% separating data

[propOn_uncorrected_disjoint, propOff_uncorrected_disjoint] = rudder_prop_corrector(BAL.windOn);
%%
propOff_uncorrected = blocks_superglue(propOff_uncorrected_disjoint);
propOn_uncorrected = blocks_superglue(propOn_uncorrected_disjoint);
clear propOff_uncorrected_disjoint propOn_uncorrected_disjoint
% freeing up memory ^


%% Model-off correction (FIRST correction)
% @nakul add this file when running 
modelOff = load_modeloff_data('modelOffData.xlsx');


propOn_uncorrected  = apply_modeloff_correction(propOn_uncorrected,  modelOff);
propOff_uncorrected = apply_modeloff_correction(propOff_uncorrected, modelOff);
%%

propOff_uncorrected.Vol_model = 0.022;
propOn_uncorrected.Vol_model = 0.022;
propOff_uncorrected.Ksb =  0.964;
propOn_uncorrected.Ksb = 0.964;
%% User inputs for corrections

At = 2.07;      % tunnel test-section area [m^2]
alpha_up = 0.0; % tunnel upflow correction [deg]

%% not including struts

delta = struct();
%% what should be the value of delta??? its used in corrections later 
%% ########################################
delta.rudder_0_block1     = 0.0;
delta.rudder_0_block3     = 0.0;
delta.rudder_0_block4     = 0.0;
delta.rudder_m10_block6_7 = 0.0;
delta.rudder_p5_block7b   = 0.0;
delta.rudder_p10_block1   = 0.0;
delta.rudder_p10_block5   = 0.0;

propOn_uncorrected.delta  = 0.10375;
propOff_uncorrected.delta = 0.10375;

dCm_dCL = struct();
dCm_dCL.rudder_0_block1     = 0.0;
dCm_dCL.rudder_0_block3     = 0.0;
dCm_dCL.rudder_0_block4     = 0.0;
dCm_dCL.rudder_m10_block6_7 = 0.0;
dCm_dCL.rudder_p5_block7b   = 0.0;
dCm_dCL.rudder_p10_block1   = 0.0;
dCm_dCL.rudder_p10_block5   = 0.0;

%% Apply corrections

% Load the .mat file
data = load('CLw_lookup.mat');
CLw_data = struct();

% === Block 1 (rudder_0_block1) ===
CLw_data.rudder_0_block1.AoA = data.rudder_0_block1_AoA;
CLw_data.rudder_0_block1.AoS = data.rudder_0_block1_AoS;
CLw_data.rudder_0_block1.V   = data.rudder_0_block1_V;
CLw_data.rudder_0_block1.CL  = data.rudder_0_block1;
CLw_data.rudder_0_block1.CT  = data.rudder_0_block1_CT;
CLw_data.rudder_0_block1.CD  = data.rudder_0_block1_CD;


% === Block 3 (rudder_0_block3) ===
CLw_data.rudder_0_block3.AoA = data.rudder_0_block3_AoA;
CLw_data.rudder_0_block3.AoS = data.rudder_0_block3_AoS;
CLw_data.rudder_0_block3.V   = data.rudder_0_block3_V;
CLw_data.rudder_0_block3.CL  = data.rudder_0_block3;
CLw_data.rudder_0_block3.CT  = data.rudder_0_block3_CT;
CLw_data.rudder_0_block3.CD  = data.rudder_0_block3_CD;


% === Block 4 (rudder_0_block4) ===
CLw_data.rudder_0_block4.AoA = data.rudder_0_block4_AoA;
CLw_data.rudder_0_block4.AoS = data.rudder_0_block4_AoS;
CLw_data.rudder_0_block4.V   = data.rudder_0_block4_V;
CLw_data.rudder_0_block4.CL  = data.rudder_0_block4;
CLw_data.rudder_0_block4.CT  = data.rudder_0_block4_CT;
CLw_data.rudder_0_block4.CD  = data.rudder_0_block4_CD;


% === Block m10 (rudder_m10_block6_7) ===
CLw_data.block_m10.AoA = data.rudder_m10_block6_7_AoA;
CLw_data.block_m10.AoS = data.rudder_m10_block6_7_AoS;
CLw_data.block_m10.V   = data.rudder_m10_block6_7_V;
CLw_data.block_m10.CL  = data.rudder_m10_block6_7;
CLw_data.block_m10.CT  = data.rudder_m10_block6_7_CT;
CLw_data.block_m10.CD  = data.rudder_m10_block6_7_CD;


% === Block p5 (rudder_p5_block7b) ===
CLw_data.block_p5.AoA = data.rudder_p5_block7b_AoA;
CLw_data.block_p5.AoS = data.rudder_p5_block7b_AoS;
CLw_data.block_p5.V   = data.rudder_p5_block7b_V;
CLw_data.block_p5.CL  = data.rudder_p5_block7b;
CLw_data.block_p5.CT  = data.rudder_p5_block7b_CT;
CLw_data.block_p5.CD  = data.rudder_p5_block7b_CD;


% === Block p10_1 (rudder_p10_block1) ===
CLw_data.block_p10_block1.AoA = data.rudder_p10_block1_AoA;
CLw_data.block_p10_block1.AoS = data.rudder_p10_block1_AoS;
CLw_data.block_p10_block1.V   = data.rudder_p10_block1_V;
CLw_data.block_p10_block1.CL  = data.rudder_p10_block1;
CLw_data.block_p10_block1.CT  = data.rudder_p10_block1_CT;
CLw_data.block_p10_block1.CD  = data.rudder_p10_block1_CD;


% === Block p10_5 (rudder_p10_block5) ===
CLw_data.block_p10_5.AoA = data.rudder_p10_block5_AoA;
CLw_data.block_p10_5.AoS = data.rudder_p10_block5_AoS;
CLw_data.block_p10_5.V   = data.rudder_p10_block5_V;
CLw_data.block_p10_5.CL  = data.rudder_p10_block5;
CLw_data.block_p10_5.CT  = data.rudder_p10_block5_CT;
CLw_data.block_p10_5.CD  = data.rudder_p10_block5_CD;

[tailOff_on_disjoint, tailOff_off_disjoint] = rudder_prop_corrector(CLw_data);
tailOff_on = blocks_superglue(tailOff_on_disjoint, true);
tailOff_off = blocks_superglue(tailOff_off_disjoint, true);

clear data CLW_data

%% fieldnames(CLw_data)
%% cfgNames

% Ensure propOn and propOff have same fieldnames
propOn_fields = fieldnames(propOn_uncorrected);
proOff_fields = fieldnames(propOff_uncorrected);

if ~isequal(propOn_fields, proOff_fields)
    missing_fields = [setdiff(propOn_fields, proOff_fields); setdiff(proOff_fields, propOn_fields)];
    error("Data sets do not have the same fields: %s", strjoin(string(missing_fields), ", "))
end

cfgNames = propOn_fields;
nCfg = numel(cfgNames);

clear propOn_fields proOff_fields
% CLw = tailOff.CL;
nm = size(propOn_uncorrected.AoA, 1);
TCWing = zeros(nm);
TCStar = zeros(nm);
TC     = zeros(nm);
C_T    = zeros(nm);

propOn_uncorrected.J  = 0.5 * (propOn_uncorrected.J_M1  + propOn_uncorrected.J_M2);
propOff_uncorrected.J = 0.5 * (propOff_uncorrected.J_M1 + propOff_uncorrected.J_M2);

% [TCWing, TCStar, TC, C_T] = thrust_DNW(propOn_uncorrected, propOff_uncorrected, tailOff_full);
[TCWing, TCStar, TC, C_T] = thrust_DNW(propOn_uncorrected, propOff_uncorrected, tailOff_on);
propOn_corrected  = blockage_corrections(propOn_uncorrected, tailOff_on, At, TCStar);
propOff_corrected = blockage_corrections(propOff_uncorrected, tailOff_off, At, TCStar);


%% Pitching moment wall correction (report-style)

%% Pitching moment wall correction

% temporary estimate of lift-curve slope [1/rad]
%% Value lifted from a python script 
CL_alpha = 5.000694 * ones(size(CLw));

% upwash correction at the wing [rad]
dalpha_uw = propOn_uncorrected.delta * (S/At) .* CLw;

propOn_corrected.dalpha_uw_deg = rad2deg(dalpha_uw);
propOn_corrected.AoA_corr = propOn_corrected.AoA + alpha_up + propOn_corrected.dalpha_uw_deg;

propOff_corrected.dalpha_uw_deg = rad2deg(dalpha_uw);
propOff_corrected.AoA_corr = propOff_corrected.AoA + alpha_up + propOff_corrected.dalpha_uw_deg;

% wing upwash-gradient correction
[dalpha_sc, dCM_025_uw] = upwash_gradient_wing_custom(dalpha_uw, CL_alpha);

% tail downwash correction
[dalpha_t, dCM_025_t] = downwash_tail_custom(CLw);

% total pitching moment correction
dCM_025c = dCM_025_uw + dCM_025_t;

% corrected pitching moment
propOn_corrected.CMpitch_corr = propOn_corrected.CMpitch + dCM_025c;

% optional: save intermediate values
propOn_corrected.dalpha_uw  = dalpha_uw;
propOn_corrected.dalpha_sc  = dalpha_sc;
propOn_corrected.dalpha_t   = dalpha_t;
propOn_corrected.dCM_025_uw = dCM_025_uw;
propOn_corrected.dCM_025_t  = dCM_025_t;
propOn_corrected.dCM_025c   = dCM_025c;

% Approve this part @Nakul 


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
