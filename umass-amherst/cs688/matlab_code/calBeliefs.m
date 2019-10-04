function [ beliefs ] = calBeliefs( clique_potentials, forward_messages, backward_messages )
%MESSAGES calculate beliefs from forward and backward messages and clique potentials

num_char = size(clique_potentials,2);
num_cliques = size(clique_potentials,3);
num_messages = num_cliques-1;

forward = [zeros(1,num_char);forward_messages]';
forward = repmat(forward,[1 1 num_char]);
forward = permute(forward, [1 3 2]);

backward = [backward_messages;zeros(1,num_char)];
backward = repmat(backward,[1 1 num_char]);
backward = permute(backward, [3 2 1]);

beliefs = clique_potentials + forward + backward;

