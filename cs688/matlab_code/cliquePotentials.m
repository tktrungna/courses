function [ clique_potentials ] = cliquePotentials( t_params, node_potentials )
%CLIQUEPOTENTIALS Summary of this function goes here
%   Detailed explanation goes here
num_potentials = size(node_potentials,2);
num_char = size(t_params,1);
clique_potentials = zeros(num_char,num_char,num_potentials-1);
for i=1:num_potentials-1,
	clique_potentials(:,:,i) = t_params + repmat(node_potentials(:,i),1,num_char);
end
% calculate clique potentials
clique_potentials(:,:,num_potentials-1) = ...
	clique_potentials(:,:,num_potentials-1) + repmat(node_potentials(:,num_potentials)',num_char,1);
end

