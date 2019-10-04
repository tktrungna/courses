function [ f_weights, t_weights, t1, ll ] = train_model( train_size, train_data, train_label )
%TRAIN_MODEL Summary of this function goes here
%   Detailed explanation goes here
num_char = 10;
num_features = 321;
disp('training model')
x = zeros(num_char,num_char + num_features);
size(x);
avgLogLikelihood(x, train_size, train_data, train_label);
grad = gradient( x, train_size, train_data, train_label);
options = optimset('GradObj','on');
x0 = zeros(num_char,num_char + num_features);


f = @(x)avgLogLikelihood_and_gradient(x,train_size, train_data, train_label);
[x,fval] = fminunc(f,x0,options);

%[xfinal fval exitflag output] = fmincon(@avg_log_likelihood,x0,...
%    train_size,train_data, train_label,@gradient);

end

