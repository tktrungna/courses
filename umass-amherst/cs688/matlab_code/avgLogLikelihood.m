function [ avgloglikelihood ] = avg_log_likelihood (x, train_size, train_data, train_label)
%AVG_LOG_LIKELIHOOD return average log likelihood
num_features = 321;
f_params = x(:,1:num_features);
t_params = x(:,num_features+1:end);
[all_pos_probs, all_trans_probs] = get_sum_prod_marginals(train_size, f_params, t_params, train_data);

total = 0;
for id=1:train_size
    cid = chars2id(char(train_label(id)));
    for i=1:size(cid,2)
        pos_probs = cell2mat(all_pos_probs(id));
        total = total + log(pos_probs(1,cid(i),i));
    end
end
avgloglikelihood = -total/train_size;