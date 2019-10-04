function [ pos_probs, trans_probs ] = calMarginals( clique_potentials, beliefs )
%CALMARGINALS Summary of this function goes here
%   Detailed explanation goes here

num = size(beliefs,3);

%logZs = zeros(size(beliefs));

for i=1:num,
    trans_probs(:,:,i) = exp(beliefs(:,:,i)-logSumExp(beliefs(:,:,i),0));
end
pos_probs = sum(trans_probs,2);
pos_probs = permute(pos_probs, [2 1 3]);

%pos_probs(:,:,num+1) = zeros(size(beliefs,1),size(beliefs,2));
%sum(trans_probs(:,:,num))
for i=1:num
    pos_probs(:,:,i) + sum(trans_probs(:,:,num));
end
pos_probs = cat(3, pos_probs, sum(trans_probs(:,:,num)));
end

