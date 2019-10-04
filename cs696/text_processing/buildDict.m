% Read and normalize articles, segment to words, building dictionary and
% bag-of-word vector for each article
clear all; close all;
load('../mat/classes.mat');
text = classes(1).text;

for i = 1:200,
    text = strcat(text,' ',classes(i).text);
end
C = strsplit(lower(text),{' ','(',')','[',']','.',',',...
        '=','\n','\t','"',':',';','-','&'});
[C,sortIdx] = sort(C);
[dicts,u,v] = unique(C);
%%
bow_vector = [];
for i = 1:200,
    cur = classes(i);
    C = strsplit(lower(cur.text),{' ','(',')','[',']','.',',',...
        '=','\n','\t','"',':',';','-','&'});
    words = cellfun(@(x) sum(ismember(C,x)), dicts);
    bow_vector = [bow_vector,words'];
end
bow_vector = bow_vector';
%%
save('../mat/bow_vector.mat', 'bow_vector');