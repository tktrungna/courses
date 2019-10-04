function [ error, logLikelihood ] = test_model( f_weights, t_weights )
%TEST_MODEL Summary of this function goes here
%   Detailed explanation goes here
load ('data.mat');
x = [f_weights(:);t_weights(:)];
logLikelihood = avgLogLikelihood(x');
gold_label = '';
pred_label = '';
for id=1:size(test_label,1)
    gold_label = strcat(gold_label,test_label(id));
    X = cell2mat(test_data(id));
    node_potentials = f_weights*X';
    num_potentials = size(node_potentials,2);
    num_labels = size(t_weights,1);
    clique_potentials = zeros(num_labels,num_labels,num_potentials-1);
    for i=1:num_potentials-1,
        clique_potentials(:,:,i) = t_params + repmat(node_potentials(:,i),1,num_labels);
    end
    % calculate clique potentials
    clique_potentials(:,:,num_potentials-1) = ...
        clique_potentials(:,:,num_potentials-1) + repmat(node_potentials(:,num_potentials)',num_labels,1);
    num_cliques = num_potentials - 1;
    num_messages = num_cliques - 1;
    
    [forward_messages, backward_messages] = messages(clique_potentials);
    beliefs = calBeliefs(clique_potentials, forward_messages, backward_messages);

    [pos_probs, trans_probs] = calMarginals(clique_potentials, beliefs);
    
    [maxVal maxInd] = max(pos_probs);
    cid = reshape(maxInd,1,size(pos_probs,3));
    chars = id2chars(cid);
    pred_label = strcat(pred_label,chars);
end
gold_label = char(gold_label);
pred_label = char(pred_label);
error = 1-sum(gold_label==pred_label)/size(pred_label,2);