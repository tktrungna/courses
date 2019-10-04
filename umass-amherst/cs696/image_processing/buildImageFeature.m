
%attributes_path = '../../CUB_200_2011/CUB_200_2011/attributes/image_attribute_labels.txt.new';
clear; close all;
load('../text_mat/attr.mat');



num_img = size(attr,1)/312;
img_attr = zeros(312,num_img);
for i=1:num_img
    cur_atr = zeros(312,1);% attributes of current image
    sub_attr = attr((i-1)*312+1:i*312,:);
    ind = find(sub_attr(:,3) == 1 & sub_attr(:,4) == 4);
    cur_atr(ind) = 1;
    img_attr(:,i) = cur_atr;
end

%load('../text_mat/attr_group.mat');

load('../text_mat/attr_type.mat')
%load('../text_mat/attribute.mat')
attribute = img_attr';
keys = {''};
values = {''};
keyValues = {''};
keyMap = containers.Map(keys, [0]);
valueMap = containers.Map(values, [0]);
keyValuesMap = containers.Map(keyValues, [0]);
id_k = 0;
id_v = 0;
id_kv = 0;
keyMap_cell = {};
valueMap_cell = {};
keyValuesMap_cell = {};
for i=1:size(attr_type)
    att_str = attr_type(i,2); % get text description of attribute
    str = regexp(att_str, '::', 'split'); 
    str = vertcat(str{:}); % get key (has_bill_shape) and value (curved)
    if isKey(keyMap,char(str(1))) == 0,
        id_k = id_k + 1;
        keyMap(char(str(1))) = id_k;
        keyMap_cell{id_k} = char(str(1));
    end
    if isKey(valueMap,char(str(2))) == 0,
        id_v = id_v + 1;
        valueMap(char(str(2))) = id_v;
        valueMap_cell{id_v} = char(str(2));
    end
    if isKey(keyValuesMap,char(att_str)) == 0,
        id_kv = id_kv + 1;
        keyValuesMap(char(att_str)) = id_kv;
        keyValuesMap_cell{id_kv} = char(att_str);
    end
end

featureMap = zeros(size(keyMap,1),size(valueMap,1),num_img);
for i=1:num_img
    for j=1:size(attribute,2),
        if attribute(i,j) == 1
            attribute(i,j);
            att = attr_type(j,2);
            str = regexp(att, '::', 'split');
            str = vertcat(str{:});
            keyMap(char(str(1)));
            valueMap(char(str(2)));
            featureMap(keyMap(char(str(1))),valueMap(char(str(2))),i) = 1;
        end
    end
end

multiFeatureMap = zeros(size(keyMap_cell,2),num_img);
for i=1:num_img%col
    for j=1:size(keyMap_cell,2)%row
        a = find(featureMap(j,:,i) == 1);
        if size(a) > 0
        	val = a(1,1);
        else
            val = 0;
        end
        multiFeatureMap(j,i) = val;
    end
end
attr_group.multiFeatureMap = multiFeatureMap;
attr_group.featureMap = featureMap;
attr_group.keyMap_cell = keyMap_cell;
attr_group.valueMap_cell = valueMap_cell;
attr_group.keyValuesMap_cell = keyValuesMap_cell;
save('../text_mat/attr_group.mat','attr_group');
%save('multiFeatureMap.mat','multiFeatureMap');