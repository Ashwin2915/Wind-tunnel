function combined_files = blocks_superglue(disjointedBlock_struct)
% Join all the blocks

block_names = fieldnames(disjointedBlock_struct); 
% returns cell array {} with all block names

combined_files = struct();

data_fields = fieldnames(disjointedBlock_struct.(block_names{1}));

for j = 5:numel(data_fields) % skipping run and time
    field = data_fields{j};
    % fprintf("fieldname: %s\n",field) % For debugging
    % Accounting for constants
    if size(disjointedBlock_struct.(block_names{1}).(field),1) * ...
       size(disjointedBlock_struct.(block_names{1}).(field),2) == 1
        combined_files.(field) = disjointedBlock_struct.(block_names{1}).(field);
        continue
    end
    for i = 1:numel(block_names)
        if ~isfield(combined_files, field)
            combined_files.(field) = []; %all data saved as lists, initialise empty list
        end
        combined_files.(field) = [combined_files.(field);...
            disjointedBlock_struct.(block_names{i}).(field)];
    end
end
end