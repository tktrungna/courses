%% display label of each attributes
load('crossvalid.mat')
load('all_doc.mat');
load('feature.mat');
a = sum(feature);
b = ones(1,312)*200-sum(feature);
y = [a;b]';
a1 = a(1:50);
b1 = b(1:50);
y1 = [a1;b1]';
bar(y1,'stacked')