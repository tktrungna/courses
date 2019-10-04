clear all; close all;
load ('data.mat');

for id=1:1
    test_file = strcat('../data/test_img',num2str(id),'.txt');
    X = load(test_file);
    node_potentials = nodePotential(f_params, X);
end