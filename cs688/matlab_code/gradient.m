function [ grad ] = gradient( x, train_size, train_data, train_label )
%GRADIENT Summary of this function goes here
%   Detailed explanation goes here
num_char = 10;
num_features = 321;
f_params = x(:,1:num_features);
t_params = x(:,num_features+1:end);
[all_pos_probs, all_trans_probs] = get_sum_prod_marginals(train_size, f_params, t_params, train_data);
  
%all_pos_probs = all_marginals[:,0]
    
%all_pairwise_probs = all_marginals[:,1]
    
f_gradient = zeros(num_char,num_features);
t_gradient = zeros(num_char,num_char);
for id=1:train_size
    example = cell2mat(train_data(id));
    pos_probs = cell2mat(all_pos_probs(id));
    trans_probs = cell2mat(all_trans_probs(id));
    indicators = zeros(num_char,size(example,1));
    cid = chars2id(char(train_label(id)));
    for i=1:size(cid,2)
        indicators(cid(i),i) = 1.0;
    end
    
    tmp = indicators - pos_probs(1);
    f_gradient = f_gradient + (indicators - pos_probs(1))*example;
    
    indicators = zeros(num_char,num_char,size(example,1)-1);
    for i=1:size(cid,2)-1
        indicators(cid(i),cid(i+1),i) = 1.0;
    end
    %f_gradient = f_gradient + 
    %f_gradient += np.transpose(np.matrix([indicators[i]-all_pos_probs[idx][i] for i in range(len(example))]))*example
    t_gradient = t_gradient + sum(indicators-trans_probs,3);
end
f_gradient = f_gradient/train_size;
t_gradient = t_gradient/train_size;
t_gradient
grad = [f_gradient,t_gradient];
end

