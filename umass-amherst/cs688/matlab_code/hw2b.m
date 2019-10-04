%%
clear all; close all;
load ('data.mat');

train_data = {};
test_data = {};
for id=1:size(train_label,1)
    train_file = strcat('../data/train_img',num2str(id),'.txt');
    X = load(train_file);
    train_data{id} = X;
end
for id=1:size(test_label,1)
    test_file = strcat('../data/test_img',num2str(id),'.txt');
    X = load(test_file);
    test_data{id} = X;
end

train_sizes = [5, 100., 150, 200, 250, 300, 350, 400];
train_model(train_sizes(1), train_data, train_label);
