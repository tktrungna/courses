function [ potential ] = nodePotential( f_params, X )
%NODEPOTENTIAL return node potentials obtained by conditioning 
% the CRF on the observed image sequence
potential = f_params*X';
end

