function results = interpolate(filename)

% Initialize results struct
results = struct();

% Read data from the Excel file
data = readtable(filename);
data_struct = table2struct(data, 'ToScalar', true);

% Rename 'Vinf' to 'V' if it exists (not found in our files yet)
% if isfield(data_struct, 'Vinf')
%     data_struct.V = data_struct.Vinf;
%     data_struct = rmfield(data_struct, 'Vinf');
% end

% TODO - remove ^ if no errors show up

% Identify field names and check for presence of V and dE
field_names = fieldnames(data_struct);
has_dE = isfield(data_struct, 'dE');
has_v = isfield(data_struct, 'V');

% Prop off has elevation deflection (dE) - we test only at dE = 0
if has_dE 
    filter = (data_struct.dE == 0);
    filtered_struct = struct();
    for i = 1:numel(field_names)
        field = field_names{i};
        filtered_struct.(field) = data_struct.(field)(filter);
    end
    data_struct = filtered_struct;
end

% If 'V' exists, separate dataset into V = 30 and V = 40 subsets 
if has_v 
    v30_filter = (abs(data_struct.V - 30) < 1);
    v40_filter = (abs(data_struct.V - 40) < 1);
    data_V30 = struct();
    data_V40 = struct();
    for i = 1:numel(field_names)
        
        field = field_names{i};
        data_V30.(field) = data_struct.(field)(v30_filter);
        data_V40.(field) = data_struct.(field)(v40_filter);
    end
end

% Define test points for interpolation
AoA_test = [8, 8, 8, 4, 4, 4, 8, 4];
AoS_test = [-6, 6, 0, 0, -6, 6, -4, 4];
V_test = [30, 40];
dR_test = [0, 5, -10];

% Store test points in the results structure
results.AoA = AoA_test;
results.AoS = AoS_test;
if has_v
    results.V = V_test;
    if has_dE 
        results.dR = dR_test;
    end
end
% Create interpolants for each dependent variable
interpolants = struct();
for i = 1:numel(field_names)
    field = field_names{i};
    
    % TODO - if ~ismember(field, {'AoA', 'AoS', 'Vinf', 'V', 'dE', 'dR'})
    % We assume linear interpolation for ease
    if ~ismember(field, {'AoA', 'AoS', 'V', 'dE', 'dR'})
        if has_dE
            interpolants_V30.(field) = scatteredInterpolant( ...
                data_V30.AoA, data_V30.AoS, data_V30.dR, data_V30.(field), 'linear', 'nearest');
            interpolants_V40.(field) = scatteredInterpolant( ...
                data_V40.AoA, data_V40.AoS, data_V40.dR, data_V40.(field), 'linear', 'nearest');
        elseif has_v
            interpolants_V30.(field) = scatteredInterpolant( ...
                data_V30.AoA, data_V30.AoS, data_V30.(field), 'linear', 'nearest');
            interpolants_V40.(field) = scatteredInterpolant( ...
                data_V40.AoA, data_V40.AoS, data_V40.(field), 'linear', 'nearest');
        else
            interpolants.(field) = scatteredInterpolant( ...
                data_struct.AoA, data_struct.AoS, data_struct.(field), 'linear', 'nearest');
        end
    end
end

% Evaluate the interpolants at test points
for i = 1:numel(field_names)
    field = field_names{i};
    % Skip independent variables
    % if ~ismember(field, {'AoA', 'AoS', 'Vinf', 'V', 'dE', 'dR'})
    if ~ismember(field, {'AoA', 'AoS', 'V', 'dE', 'dR'})
        if has_dE
            results.(field) = zeros(1, length(AoS_test), 2, 3); % (AoA, AoS, V, dR)
            for j = 1:length(dR_test)
                dR_val = dR_test(j) * ones(1, length(AoA_test));
                results.(field)(:, :, 1, j) = interpolants_V30.(field)(AoA_test, AoS_test, dR_val);
                results.(field)(:, :, 2, j) = interpolants_V40.(field)(AoA_test, AoS_test, dR_val);
            end
        elseif has_v
            results.(field) = zeros(1, length(AoS_test), 2); % (AoA, AoS, V)
            results.(field)(:, :, 1) = interpolants_V30.(field)(AoA_test, AoS_test);
            results.(field)(:, :, 2) = interpolants_V40.(field)(AoA_test, AoS_test);
        else
            results.(field) = interpolants.(field)(AoA_test, AoS_test);
        end
    end
end
end