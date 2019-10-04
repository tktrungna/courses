clear all; close all;
load ('data.mat');

for id=1:1
    file = strcat('../data/test_img',num2str(id),'.txt');
    X = load(file);
    node_potentials = nodePotential(f_params, X);
    node_potentials = exp(node_potentials);
    marginals = diag(1./sum(node_potentials,2))*node_potentials;
end
