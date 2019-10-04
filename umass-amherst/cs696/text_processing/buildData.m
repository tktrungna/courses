% divide data set to 5 subset, combine and create 
% train/test sets for cross-validation
clear; close all
load('../mat/bow_vector.mat');
load('../mat/attribute.mat');

data1 = bow_vector(1:40,:);
data2 = bow_vector(41:80,:);
data3 = bow_vector(81:120,:);
data4 = bow_vector(121:160,:);
data5 = bow_vector(161:200,:);

feat1 = attribute(1:40,:);
feat2 = attribute(41:80,:);
feat3 = attribute(81:120,:);
feat4 = attribute(121:160,:);
feat5 = attribute(161:200,:);

DATA.TRAIN = {};
DATA.TRAIN{1} = [data2;data3;data4;data5];
DATA.TRAIN{2} = [data1;data3;data4;data5];
DATA.TRAIN{3} = [data1;data2;data4;data5];
DATA.TRAIN{4} = [data1;data2;data3;data5];
DATA.TRAIN{5} = [data1;data2;data3;data4];
DATA.TEST = {};
DATA.TEST{1} = data1;
DATA.TEST{2} = data2;
DATA.TEST{3} = data3;
DATA.TEST{4} = data4;
DATA.TEST{5} = data5;

FEAT.TRAIN = {};
FEAT.TRAIN{1} = [feat2;feat3;feat4;feat5];
FEAT.TRAIN{2} = [feat1;feat3;feat4;feat5];
FEAT.TRAIN{3} = [feat1;feat2;feat4;feat5];
FEAT.TRAIN{4} = [feat1;feat2;feat3;feat5];
FEAT.TRAIN{5} = [feat1;feat2;feat3;feat4];
FEAT.TEST = {};
FEAT.TEST{1} = feat1;
FEAT.TEST{2} = feat2;
FEAT.TEST{3} = feat3;
FEAT.TEST{4} = feat4;
FEAT.TEST{5} = feat5;
save('../mat/crossvalid.mat','DATA','FEAT');