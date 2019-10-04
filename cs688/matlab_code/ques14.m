clear all; close all;
load ('data.mat');

for id=1:3,%size(seq,2)
    file = strcat('../data/test_img',num2str(id),'.txt');
    X = load(file);
    length = size(char(test_label{id}),2);
    allseqs = unique(nchoosek(repmat([1:10], 1,length+1), length), 'rows');
    energies = zeros(size(allseqs,1),1);
    for i=1:size(allseqs,1),
        neg_ene = negEnergy(allseqs(i,:), X, t_params, f_params);
        energies(i,1) = neg_ene;
    end
    [m,index] = max(energies);
    t = exp(energies-m);
    seq_probability  = exp(m)/(sum(exp(energies)))
    id2chars(allseqs(index,:))
end
