function combined_files = blocks_superglue(disjointedBlock_struct)
% Join all the blocks

block_names = fieldnames(disjointedBlock_struct); 
% returns cell array {} with all block names

combined_files = struct();

data_fields = fieldnames(disjointedBlock_struct.(block_names{1}));

for j = 1:numel(data_fields)
    field = data_fields{j};
    % Accounting for constants
    if size(disjointedBlock_struct.(block_names{1}).(field),1) * ...
            size(disjointedBlock_struct.(block_names{1}).(field),2) == 1
        combined_files.(field) = disjointedBlock_struct.(block_names{1}).(field);
    end
    for i = 1:numel(block_names)
        combined_files.(field) = [combined_files.(field);...
            disjointedBlock_struct.(block_names{i}).(field)];
    end
end
end