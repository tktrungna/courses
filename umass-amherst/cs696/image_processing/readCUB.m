function imdb = readCUB(dataDir, param)

imdb.imageDir = fullfile(dataDir, 'images');

classes_path = strcat(dataDir,'classes.txt');
fid = fopen(classes_path);
tmp = textscan(fid,'%s','Delimiter','\n'); tmp = tmp{:};
class = regexp(tmp, ' ', 'split'); class = vertcat(class{:});
fclose(fid);

imdb.images.className = class;

% reading images id and content
images_path = strcat(dataDir,'images.txt');
fid = fopen(images_path);
tmp = textscan(fid,'%s','Delimiter','\n'); tmp = tmp{:};
image = regexp(tmp, ' ', 'split'); image = vertcat(image{:});
fclose(fid);

imdb.images.name = image(:,2);

% reading images id and classes id information and combine to cells
images_class_path = strcat(dataDir,'image_class_labels.txt');
fid = fopen(images_class_path);
tmp = textscan(fid,'%s','Delimiter','\n');
tmp = tmp{:};
tmp = regexp(tmp, ' ', 'split');
tmp = vertcat(tmp{:});
fclose(fid);

imdb.images.classId = tmp(:,2);
%imdb.images.classId = cell2mat(str2num(imdb.images.classId));

% reading training/testing information and combine to cells
images_path = strcat(dataDir,'train_test_split.txt');
fid = fopen(images_path);
tmp = textscan(fid,'%s','Delimiter','\n');
tmp = tmp{:}; tmp = regexp(tmp, ' ', 'split'); tmp = vertcat(tmp{:});
fclose(fid);

imdb.images.type = tmp(:,2); %training/testing information


type = {};
classId = zeros(size(imdb.images.className,1)*param.numOfSample,1);
name = {};
ind = 0;
for i=1:size(imdb.images.className,1)
    row = find(strcmpi(imdb.images.classId,num2str(i)));
    if size(row,1) > param.numOfSample
        row = row(1:param.numOfSample,:);
    end
    for j=1:size(row,1),
        ind = ind+1;
        type{ind,1} = cell2mat(imdb.images.type(row(j,1)));
        classId(ind,1) = i;
        name{ind,1} = imdb.images.name(row(j,1));
    end
end
imdb.images.type = type;
imdb.images.classId = classId;
%bounding box
imdb.images.bounding = load(fullfile(dataDir, 'bounding_boxes.txt'));
imdb.images.all_imname = imdb.images.name;
imdb.images.name = name;

