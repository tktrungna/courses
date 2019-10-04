function [ output ] = logSumExp( input, dimen )
%LOGSUMEXP Computing Log-Sum-Exp of a vector
%   https://hips.seas.harvard.edu/blog/2013/01/09/computing-log-sum-exp/
if dimen == 0 % for the whole matrix
    m = max(max(input));
    e = exp(input-m);
    output = m + log(sum(e(:)));
else
    m = max(input); % for an array
    output = m + log(sum(exp(input-m), dimen));
end
end

