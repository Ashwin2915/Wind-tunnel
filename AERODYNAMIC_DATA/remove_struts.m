function [propOn_strut_removed, propOff_strut_removed, ...
    tailOff_strut_removed] = remove_struts(propOn, propOff, ...
    tailOff, modelOff)
    
propOn_strut_removed    = zeros(size(propOn));
propOff_strut_removed   = zeros(size(propOff));
tailOff_strut_removed   = zeros(size(propOff));

% correcting data over AoA
for i = 1:length(modelOff.AoA)
    fields_propOn = intersect(fieldnames(modelOff), fieldnames(propOn)); 
    fields_propOff = intersect(fieldnames(modelOff), fieldnames(propOff)); 
    fields_tailOff = intersect(fieldnames(modelOff),fieldnames(tailOff));
end
end
      