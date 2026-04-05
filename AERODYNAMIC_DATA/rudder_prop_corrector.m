function [propOn, propOff] = rudder_prop_corrector(dataStruct)
block_names = fieldnames(dataStruct);

propOff = struct();
propOn = struct();
for i = 1:numel(block_names) 
    block = block_names{i};
    block_length = length(dataStruct.(block).AoA);
    % Rudder deflection variables
    if contains(block, "0")
        if contains(block, "m10")
            dataStruct.(block).dR = -10 * ones(block_length,1);
        elseif contains(block, "p10")
            dataStruct.(block).dR = 10 * ones(block_length,1);
        else
            dataStruct.(block).dR = zeros(block_length,1);
        end
    elseif contains(block, "5")
        dataStruct.(block).dR = 5 * ones(block_length,1);
    end

    % combining blocks
    if contains(block, "block1") % block 1 is propOff measurements
        propOff.(block) = dataStruct.(block);
    else
        propOn.(block) = dataStruct.(block);
    end
end
end