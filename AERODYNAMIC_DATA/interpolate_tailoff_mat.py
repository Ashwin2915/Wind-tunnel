import os
import numpy as np
import pandas as pd
from scipy.interpolate import interp1d
from scipy.io import loadmat, savemat

# --------------------------------------------------
# USER PATHS
# --------------------------------------------------
folder = r'C:\Group_16_Redo_BAL\BAL_redo'
tailoff_mat_file = os.path.join(folder, 'TailOff_BAL.mat')

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
# HELPERS TO READ MATLAB STRUCTS
# --------------------------------------------------
def matstruct_to_dict(matobj):
    if hasattr(matobj, '_fieldnames'):
        out = {}
        for field in matobj._fieldnames:
            out[field] = matstruct_to_dict(getattr(matobj, field))
        return out
    elif isinstance(matobj, np.ndarray):
        if matobj.dtype == object:
            return [matstruct_to_dict(x) for x in matobj]
        else:
            return np.asarray(matobj).squeeze()
    else:
        return matobj


def ensure_1d(x):
    return np.asarray(x, dtype=float).squeeze().ravel()


def matlab_safe_name(filename):
    name = os.path.splitext(filename)[0]
    name = name.replace('-', '_').replace(' ', '_')
    if name.startswith('raw_'):
        name = name[4:]
    return name


def find_coefficient_field(cfg, candidates):
    for c in candidates:
        if c in cfg:
            return c
    raise KeyError(f'None of these fields were found in config: {candidates}')


# --------------------------------------------------
# LOAD TAIL-OFF DATA FROM .MAT
# --------------------------------------------------
mat_data = loadmat(tailoff_mat_file, squeeze_me=True, struct_as_record=False)
print("Top-level keys in .mat file:", mat_data.keys())

tailoff_struct = mat_data['BAL']
tailoff_dict = matstruct_to_dict(tailoff_struct)

wind_on = tailoff_dict['windOn']

# --------------------------------------------------
# BUILD DATAFRAME FROM THE .MAT CONTENT
# --------------------------------------------------
all_rows = []

for config_name, cfg in wind_on.items():
    aoa = ensure_1d(cfg['AoA'])
    aos = ensure_1d(cfg['AoS'])
    vel = ensure_1d(cfg['V'])

    cl_field = find_coefficient_field(cfg, ['CL', 'Cl', 'C_L'])
    ct_field = find_coefficient_field(cfg, ['CT', 'Ct', 'C_T'])
    cd_field = find_coefficient_field(cfg, ['CD', 'Cd', 'C_D'])

    cl = ensure_1d(cfg[cl_field])
    ct = ensure_1d(cfg[ct_field])
    cd = ensure_1d(cfg[cd_field])

    n = min(len(aoa), len(aos), len(vel), len(cl), len(ct), len(cd))

    for i in range(n):
        all_rows.append({
            'config': config_name,
            'AoA': aoa[i],
            'AoS': aos[i],
            'Vinf': vel[i],
            'CL': cl[i],
            'CT': ct[i],
            'CD': cd[i]
        })

tail_df = pd.DataFrame(all_rows)
tail_df['Vround'] = tail_df['Vinf'].round().astype(int)

tail_aos0 = tail_df[np.isclose(tail_df['AoS'], 0.0, atol=0.1)].copy()
tail_aosvar = tail_df[~np.isclose(tail_df['AoS'], 0.0, atol=0.1)].copy()

# --------------------------------------------------
# GENERIC INTERPOLATION HELPERS
# --------------------------------------------------
def interpolate_coeff_aos0(alpha, v_target, tail_df, coeff_name):
    v_round = int(round(v_target))
    df_v = tail_df[tail_df['Vround'] == v_round].copy()

    if df_v.empty:
        raise ValueError(f'No AoS=0 tail-off data found for V ~ {v_target} m/s')

    df_v = df_v.groupby('AoA', as_index=False)[coeff_name].mean().sort_values('AoA')

    f = interp1d(
        df_v['AoA'].values,
        df_v[coeff_name].values,
        kind='linear',
        fill_value='extrapolate'
    )

    return float(f(alpha))


def interpolate_coeff_2d(alpha, beta, v_target, tail_df, coeff_name):
    v_round = int(round(v_target))
    df_v = tail_df[tail_df['Vround'] == v_round].copy()

    if df_v.empty:
        raise ValueError(f'No AoS-variation tail-off data found for V ~ {v_target} m/s')

    df_v = df_v.groupby(['AoA', 'AoS'], as_index=False)[coeff_name].mean()

    aoa_levels = np.sort(df_v['AoA'].unique())
    coeff_vs_aoa = []

    for aoa_val in aoa_levels:
        sub = df_v[df_v['AoA'] == aoa_val].sort_values('AoS')

        if len(sub) < 2:
            continue

        f_beta = interp1d(
            sub['AoS'].values,
            sub[coeff_name].values,
            kind='linear',
            fill_value='extrapolate'
        )

        coeff_at_beta = float(f_beta(beta))
        coeff_vs_aoa.append((aoa_val, coeff_at_beta))

    if len(coeff_vs_aoa) == 0:
        raise ValueError(f'No usable AoS-varying data found for V ~ {v_target} m/s')

    if len(coeff_vs_aoa) == 1:
        return coeff_vs_aoa[0][1]

    aoa_used = np.array([x[0] for x in coeff_vs_aoa], dtype=float)
    coeff_used = np.array([x[1] for x in coeff_vs_aoa], dtype=float)

    f_alpha = interp1d(
        aoa_used,
        coeff_used,
        kind='linear',
        fill_value='extrapolate'
    )

    return float(f_alpha(alpha))


def get_coeff(alpha, beta, v_target, coeff_name, beta_tol=0.1):
    if abs(beta) < beta_tol:
        return interpolate_coeff_aos0(alpha, v_target, tail_aos0, coeff_name)
    else:
        return interpolate_coeff_2d(alpha, beta, v_target, tail_aosvar, coeff_name)

# --------------------------------------------------
# MAIN LOOP THROUGH ALL RAW FILES
# --------------------------------------------------
lookup_data = {}
summary_rows = []

for fname in raw_files:
    raw_path = os.path.join(folder, fname)

    raw = pd.read_csv(
        raw_path,
        sep=r'\s+',
        skiprows=2,
        names=raw_cols
    )

    raw['Vround'] = raw['V'].round().astype(int)

    raw['CLw'] = raw.apply(
        lambda row: get_coeff(
            alpha=row['Alpha'],
            beta=row['Beta'],
            v_target=row['V'],
            coeff_name='CL'
        ),
        axis=1
    )

    raw['CTw'] = raw.apply(
        lambda row: get_coeff(
            alpha=row['Alpha'],
            beta=row['Beta'],
            v_target=row['V'],
            coeff_name='CT'
        ),
        axis=1
    )

    raw['CDw'] = raw.apply(
        lambda row: get_coeff(
            alpha=row['Alpha'],
            beta=row['Beta'],
            v_target=row['V'],
            coeff_name='CD'
        ),
        axis=1
    )

    key = matlab_safe_name(fname)

    # Save coefficient arrays
    lookup_data[key] = raw['CLw'].to_numpy()
    lookup_data[f'{key}_CT'] = raw['CTw'].to_numpy()
    lookup_data[f'{key}_CD'] = raw['CDw'].to_numpy()

    # Save operating-point arrays
    lookup_data[f'{key}_AoA'] = raw['Alpha'].to_numpy()
    lookup_data[f'{key}_AoS'] = raw['Beta'].to_numpy()
    lookup_data[f'{key}_V']   = raw['V'].to_numpy()

    summary_rows.append({
        'file': fname,
        'n_points': len(raw),
        'CLw_min': raw['CLw'].min(),
        'CLw_max': raw['CLw'].max(),
        'CTw_min': raw['CTw'].min(),
        'CTw_max': raw['CTw'].max(),
        'CDw_min': raw['CDw'].min(),
        'CDw_max': raw['CDw'].max()
    })

# --------------------------------------------------
# SAVE FOR MATLAB
# --------------------------------------------------
out_mat = os.path.join(folder, 'CLw_CTw_CDw_lookup_from_mat.mat')
savemat(out_mat, lookup_data)

summary_df = pd.DataFrame(summary_rows)
summary_csv = os.path.join(folder, 'CLw_CTw_CDw_summary_from_mat.csv')
summary_df.to_csv(summary_csv, index=False)

print('Saved MATLAB file to:', out_mat)
print('Saved summary CSV to:', summary_csv)
print(summary_df)