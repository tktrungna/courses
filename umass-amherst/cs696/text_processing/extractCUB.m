% Extract data (featuress, labels, properties, values...) from CUB dataset
clear all; close all;

% reading classes id and content
classes_path = '../../CUB_200_2011/CUB_200_2011/classes.txt';
fid = fopen(classes_path);
tmp = textscan(fid,'%s','Delimiter','\n');
tmp = tmp{:};
class = regexp(tmp, ' ', 'split');
class = vertcat(class{:});
fclose(fid);

% reading images id and content
images_path = '../../CUB_200_2011/CUB_200_2011/images.txt';
fid = fopen(images_path);
tmp = textscan(fid,'%s','Delimiter','\n');
tmp = tmp{:};
image = regexp(tmp, ' ', 'split');
image = vertcat(image{:});
fclose(fid);

% reading images id and classes id information and combine to cells
%  images = {id, name, class_id}
images_class_path = '../../CUB_200_2011/CUB_200_2011/image_class_labels.txt';
fid = fopen(images_class_path);
tmp = textscan(fid,'%s','Delimiter','\n');
tmp = tmp{:};
tmp = regexp(tmp, ' ', 'split');
tmp = vertcat(tmp{:});
image = [image(:,:),tmp(:,2)]; 
fclose(fid);

% reading training/testing information and combine to cells
%  images = {id, name, class_id, type(0/1)}
images_path = '../../CUB_200_2011/CUB_200_2011/train_test_split.txt';
fid = fopen(images_path);
tmp = textscan(fid,'%s','Delimiter','\n');
tmp = tmp{:};
tmp = regexp(tmp, ' ', 'split');
tmp = vertcat(tmp{:});
image = [image(:,:),tmp(:,2)]; 
fclose(fid);

%% reading image id attributes lables (original data got format error and need to modified)
attributes_path = '../../CUB_200_2011/CUB_200_2011/attributes/image_attribute_labels.txt.new';
fid = fopen(attributes_path);
tmp = textscan(fid,'%s','Delimiter','\n');
tmp = tmp{:};
%tmp = tmp(1:500,:);
attr = regexp(tmp, ' *', 'split');% may have multi space
attr = vertcat(attr{:});
fclose(fid);
attr=cell2mat(cellfun(@str2num,attr(:,:),'un',0));
%save('attr.mat', 'attr');
% save image structure to mat file, 1x11788 images
save('../mat/image.mat', 'image');
% save attribute data to mat file
save('../mat/attr.mat', 'attr');

%% adding birds' articles
for id = 1:200,
    classes(id).class_id = id;
    cur_class = class(str2num(char(image(:,1))) == id,:);
    classes(id).name = char(class(id,2));
    classes(id).images = [];
    name = strsplit(lower(char(class(id,2))),'.');
    file = char(name(1,2));
    path = strcat('../../Processing/WikiBirds/',file,'/context.txt');
    classes(id).text = fileread(path);
end

%save('classes_pre.mat', 'classes');

for id = 1:size(image,1),
    cur = attr(attr(:,1) == id,:);
    images(id).image_id = id
    images(id).attribute_id = cur(:,2);
    images(id).is_present = cur(:,3);
    images(id).certainty_id = cur(:,4);
    images(id).time = cur(:,5);
    cur_image = image(str2num(char(image(:,1))) == id,:);
    images(id).image_name = char(cur_image(1,2));
    images(id).is_training_image = str2num(char(cur_image(1,4)));
    classes(str2num(char(cur_image(1,3)))).images = [classes(str2num(char(cur_image(1,3)))).images;images(id)];
end
% save data of 200 kinds of birds, include image, text, attributes...
save('../mat/classes.mat', 'classes');


%% reading attribute id and content

attributes_path = '../../CUB_200_2011/attributes.txt';
fid = fopen(attributes_path);
tmp = textscan(fid,'%s','Delimiter','\n');
tmp = tmp{:};
attr_type = regexp(tmp, ' ', 'split');
attr_type = vertcat(attr_type{:});
save('../mat/attr_type.mat', 'attr_type');
fclose(fid);