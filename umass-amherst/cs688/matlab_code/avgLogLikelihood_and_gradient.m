function [ f, df ] = avgLogLikelihood_and_gradient( x,train_size, train_data, train_label )
%AVGLOGLIKELIHOOD_AND_GRADIENT Summary of this function goes here
%   Detailed explanation goes here
train_size
f = avgLogLikelihood(x,train_size, train_data, train_label);
df = gradient(x,train_size, train_data, train_label);

end

