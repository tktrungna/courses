function [ f, df ] = fun( x )
%AVGLOGLIKELIHOOD_AND_GRADIENT Summary of this function goes here
%   Detailed explanation goes here
f = -avgLogLikelihood(x');
df = -gradient(x');
end

