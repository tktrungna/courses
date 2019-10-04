% based on labeled attributes, attribute that the rate of labeled
% as "present" (1) larger than threshold would be set as 1, otherwise
% would be set as 0. 
% generate feature vector 
close all; clear;
% load classes
load('../text_mat/classes.mat');
% load attr_type
load('../text_mat/attr_type.mat');

thredhold = 0.3;
attribute=[];
for i=1:200,
    cur = classes(i);
    att = [];
    for i=1:size(cur.images,1),
        att = [att,cur.images(i).is_present.*cur.images(i).certainty_id];
    end
    att = sum(att,2);
    att = att/max(att);
    att(att>=thredhold)=1;
    att(att<thredhold)=0;
    attribute = [attribute, att];
end
attribute = attribute';
save('../text_mat/attribute.mat', 'attribute');