clear all; close all;

f_params = load('../model/feature-params.txt');
t_params = load('../model/transition-params.txt');
'etainoshrd';

keys = {'e','t','a','i','n','o','s','h','r','d'};
values = {1,2,3,4,5,6,7,8,9,10};
charMap = containers.Map(keys, values);

fid = fopen('../data/train_words.txt');
train_label = textscan(fid,'%s','Delimiter','\n');
train_label = train_label{:};
fclose(fid);

fid = fopen('../data/test_words.txt');
test_label = textscan(fid,'%s','Delimiter','\n');
test_label = test_label{:};
fclose(fid);

save ('data.mat', 'charMap', 'train_label', 'test_label', 'f_params', 't_params');
