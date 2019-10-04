function [ cid ] = chars2id( chars )
%FUNCTIONS return id of character from the given most frequent chars
%etainoshrd
keys = {'e','t','a','i','n','o','s','h','r','d'};
values = {1,2,3,4,5,6,7,8,9,10};
charMap = containers.Map(keys, values);
cid = [];
for i=1:size(chars,2),
    cid = [cid, charMap(chars(i))];
end
end