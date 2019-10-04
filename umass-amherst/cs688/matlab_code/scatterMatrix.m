function [ subMat ] = scatterMatrix( Mat, indices )
%SCATTERMATRIX get scatter matrix base on indies
sub = [];
for i=1:size(indices,2)
    sub = [sub, Mat(:,indices(i))];
end
subMat = [];
for i=1:size(indices,2)
    subMat = [subMat; sub(indices(i),:)];
end
end

