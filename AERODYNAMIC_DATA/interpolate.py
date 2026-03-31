import os
import numpy as np
import pandas as pd
from scipy.interpolate import interp1d, LinearNDInterpolator
from scipy.io import savemat

# --------------------------------------------------
# USER PATHS
# --------------------------------------------------
folder = r'C:\Group_16_Redo_BAL\BAL_redo'
tailoff_file = os.path.join(folder, 'TailOffData.xlsx')

raw_files = [
    'raw_rudder_0_block1.txt',
    'raw_rudder_0_block3.txt',
    'raw_rudder_0_block4.txt',
    'raw_rudder_m10_block6_7.txt',
    'raw_rudder_p5_block7b.txt',
    'raw_rudder_p10_block1.txt',
    'raw_rudder_p10_block5.txt'
]

# --------------------------------------------------
# RAW FILE COLUMN NAMES
# --------------------------------------------------
raw_cols = [
    'Run_nr','Time','Alpha','Beta','Delta_Pb','P_bar','T',
    'B1','B2','B3','B4','B5','B6',
    'rpm','Rho','Q','V','Re','nrotor1','nrotor2',
    'I1','I2','dptq',
    'Extra1','Extra2','Extra3','Extra4','Extra5',
    'Extra6','Extra7','Extra8','Extra9','Extra10'
]

# --------------------------------------------------
# LOAD TAIL-OFF DATA
# --------------------------------------------------
xls = pd.ExcelFile(tailoff_file)
tail_aos0 = pd.read_excel(xls, sheet_name='AoS = 0 deg')
tail_aosvar = pd.read_excel(xls, sheet_name='AoS variations')

# round speeds so 39.99 and 40.0 are treated the same
tail_aos0['Vround'] = tail_aos0['Vinf'].round().astype(int)
tail_aosvar['Vround'] = tail_aosvar['Vinf'].round().astype(int)

# --------------------------------------------------
# INTERPOLATION HELPERS
# --------------------------------------------------
def interpolate_clw_aos0(alpha, v_target, tail_df):
    """
    For near-zero sideslip: use AoS = 0 sheet
    and interpolate CL as a function of AoA.
    """
    df_v = tail_df[tail_df['Vround'] == int(round(v_target))].copy()

    if df_v.empty:
        raise ValueError(f'No AoS=0 tail-off data found for V ~ {v_target} m/s')

    # average duplicate AoA values if present
    df_v = df_v.groupby('AoA', as_index=False)['CL'].mean().sort_values('AoA')

    f = interp1d(
        df_v['AoA'].values,
        df_v['CL'].values,
        kind='linear',
        fill_value='extrapolate'
    )

    return float(f(alpha))


def interpolate_clw_2d(alpha, beta, v_target, tail_df):
    """
    Interpolate CLw for nonzero sideslip in two steps:
    1) interpolate in AoS at each available AoA
    2) interpolate/extrapolate in AoA
    """
    df_v = tail_df[tail_df['Vround'] == int(round(v_target))].copy()

    if df_v.empty:
        raise ValueError(f'No AoS-variation tail-off data found for V ~ {v_target} m/s')

    # average duplicates if any
    df_v = df_v.groupby(['AoA', 'AoS'], as_index=False)['CL'].mean()

    aoa_levels = np.sort(df_v['AoA'].unique())
    cl_vs_aoa = []

    for aoa_val in aoa_levels:
        sub = df_v[df_v['AoA'] == aoa_val].sort_values('AoS')

        f_beta = interp1d(
            sub['AoS'].values,
            sub['CL'].values,
            kind='linear',
            fill_value='extrapolate'
        )

        cl_at_beta = float(f_beta(beta))
        cl_vs_aoa.append(cl_at_beta)

    f_alpha = interp1d(
        aoa_levels,
        cl_vs_aoa,
        kind='linear',
        fill_value='extrapolate'
    )

    return float(f_alpha(alpha))


def get_clw(alpha, beta, v_target, beta_tol=0.1):
    """
    Decide which sheet to use.
    """
    if abs(beta) < beta_tol:
        return interpolate_clw_aos0(alpha, v_target, tail_aos0)
    else:
        return interpolate_clw_2d(alpha, beta, v_target, tail_aosvar)


def matlab_safe_name(filename):
    """
    Convert filename to a MATLAB-safe field name.
    Example: raw_rudder_0_block1.txt -> raw_rudder_0_block1
    """
    name = os.path.splitext(filename)[0]
    name = name.replace('-', '_').replace(' ', '_')

    if name.startswith('raw_'):
        name = name[4:]   # remove 'raw_'
        
    return name

# --------------------------------------------------
# MAIN LOOP THROUGH ALL RAW FILES
# --------------------------------------------------
CLw_lookup = {}      # final dictionary for MATLAB
summary_rows = []    # optional summary table for checking

for fname in raw_files:
    raw_path = os.path.join(folder, fname)

    raw = pd.read_csv(
        raw_path,
        sep=r'\s+',
        skiprows=2,
        names=raw_cols
    )

    # round speed for easier matching/debugging if needed
    raw['Vround'] = raw['V'].round().astype(int)

    # interpolate CLw row by row
    raw['CLw'] = raw.apply(
        lambda row: get_clw(
            alpha=row['Alpha'],
            beta=row['Beta'],
            v_target=row['V']
        ),
        axis=1
    )

    # store only the CLw list in a MATLAB-friendly structure
    key = matlab_safe_name(fname)
    CLw_lookup[key] = raw['CLw'].to_numpy()

    # optional: also store matching Alpha/Beta/V so later you can verify
    CLw_lookup[f'{key}_AoA'] = raw['Alpha'].to_numpy()
    CLw_lookup[f'{key}_AoS'] = raw['Beta'].to_numpy()
    CLw_lookup[f'{key}_V']   = raw['V'].to_numpy()

    # optional summary for checking
    summary_rows.append({
        'file': fname,
        'n_points': len(raw),
        'CLw_min': raw['CLw'].min(),
        'CLw_max': raw['CLw'].max()
    })

# --------------------------------------------------
# SAVE FOR MATLAB
# --------------------------------------------------
out_mat = os.path.join(folder, 'CLw_lookup.mat')
savemat(out_mat, CLw_lookup)

# optional CSV summary
summary_df = pd.DataFrame(summary_rows)
summary_csv = os.path.join(folder, 'CLw_summary.csv')
summary_df.to_csv(summary_csv, index=False)

print('Saved MATLAB file to:', out_mat)
print('Saved summary CSV to:', summary_csv)
print(summary_df)