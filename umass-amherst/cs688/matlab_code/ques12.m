clear all; close all;
load ('data.mat');
seq=[1,2,3];

res = [];
for id=1:size(seq,2)
    file = strcat('../data/test_img',num2str(id),'.txt');
    X = load(file);
    chars = char(test_label{id});
    cid = chars2id(chars);
    neg_ene = negEnergy(cid, X, t_params, f_params);
    res = [res, neg_ene];
end
res
