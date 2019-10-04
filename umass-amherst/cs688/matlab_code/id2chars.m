function [ chars ] = id2chars( cid )
%ID2CHARS return char of id from the given most frequent chars
%etainoshrd
keys = {'e','t','a','i','n','o','s','h','r','d'};
values = {1,2,3,4,5,6,7,8,9,10};
charMap = containers.Map(values,keys);
chars = [];
for i=1:size(cid,2),
    chars = [chars, charMap(cid(i))];
end
end

