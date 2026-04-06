function modelOff = load_modeloff_data(filename)
% Load model-off correction data from Excel sheet

T1 = readtable(filename, 'Sheet', 1, 'Range', 'A12:H31', 'VariableNamingRule', 'preserve');
T2 = readtable(filename, 'Sheet', 1, 'Range', 'J12:Q32', 'VariableNamingRule', 'preserve');

T1.Properties.VariableNames = {'AoA','AoS','CD','Cy','CL','CMroll','CMpitch','CMyaw'};
T2.Properties.VariableNames = {'AoA','AoS','CD','Cy','CL','CMroll','CMpitch','CMyaw'};

% remove empty rows
T1 = rmmissing(T1, 'DataVariables', {'AoA','AoS'});
T2 = rmmissing(T2, 'DataVariables', {'AoA','AoS'});

modelOff.alpha0 = T1;   % varying AoA, beta = 0
modelOff.beta0  = T2;   % varying AoS, alpha = 0
end