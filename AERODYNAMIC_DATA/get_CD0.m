function CD_0 = get_CD0(corrected_data)
% input corrected data for obtaining CD_0

% Find indices of data that
filter_idx = data.rudder == 0 & abs(data.V - 40) <=  0.1 & abs(data.beta) <= 0.1
CL = data.CL(filter_idx)
CD = data.CD(filter_idx)

p = polyfit(CD, CL.^2, 1) % CD = CD_0 + kCL^2
CD_0 = p(2);


end