clear all; close all;
load ('data.mat');

gold_label = '';
pred_label = '';
for id=1:5
    test_file = strcat('../data/test_img',num2str(id),'.txt');
    X = load(test_file);
    gold_label = strcat(gold_label,test_label(id));
    node_potentials = f_params*X';
    num_potentials = size(node_potentials,2);
    num_char = size(t_params,1); % number of considered characters
    clique_potentials = zeros(num_char,num_char,num_potentials-1);
    for i=1:num_potentials-1,
        clique_potentials(:,:,i) = t_params + repmat(node_potentials(:,i),1,num_char);
    end
    % calculate clique potentials
    clique_potentials(:,:,num_potentials-1) = ...
        clique_potentials(:,:,num_potentials-1) + repmat(node_potentials(:,num_potentials)',num_char,1);
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
acc_num = sum(gold_label==pred_label)/size(pred_label,2);