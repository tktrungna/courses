% Initiate data
close all; clear
conf.calDir = 'data/caltech-101' ;
conf.dataDir = 'data/' ;
conf.autoDownloadData = true ;
conf.numTrain = 15 ;
conf.numTest = 15 ;
conf.numClasses = 102 ;
conf.numWords = 600 ;
conf.numSpatialX = [2 4] ;
conf.numSpatialY = [2 4] ;
conf.quantizer = 'kdtree' ;
conf.svm.C = 10 ;

%conf.svm.solver = 'sdca' ;
conf.svm.solver = 'sgd' ;
%conf.svm.solver = 'liblinear' ;

conf.svm.biasMultiplier = 1 ;
conf.phowOpts = {'Step', 3} ;
conf.clobber = false ;
conf.tinyProblem = true ;
conf.prefix = 'baseline' ;
conf.randSeed = 1 ;

if conf.tinyProblem
  conf.prefix = 'tiny' ;
  conf.numClasses = 5 ;
  conf.numSpatialX = 2 ;
  conf.numSpatialY = 2 ;
  conf.numWords = 300 ;
  conf.phowOpts = {'Verbose', 2, 'Sizes', 7, 'Step', 5} ;
end

conf.vocabPath = fullfile(conf.dataDir, [conf.prefix '-vocab.mat']) ;
conf.histPath = fullfile(conf.dataDir, [conf.prefix '-hists.mat']) ;
conf.modelPath = fullfile(conf.dataDir, [conf.prefix '-model.mat']) ;
conf.resultPath = fullfile(conf.dataDir, [conf.prefix '-result']) ;

randn('state',conf.randSeed) ;
rand('state',conf.randSeed) ;
vl_twister('state',conf.randSeed) ;

%run('~/CODE/MATLAB/AdditionalPackages/vlfeat-0.9.20/toolbox/vl_setup')

% preprocessing data // load imdb ...
[imdb, param] = preData();

% construct histogram feature vector for testing image
load('../text_mat/attr_group.mat');

%image_id = randperm(size(attr_group.multiFeatureMap,2));
%image_id = image_id(:,1:2000);
%save('image_id.mat','image_id');
load('image_id.mat');
%bow_vectors = constructFeatures( imdb, param);
bow_vectors = constructFeatures2( imdb, param, image_id);
%psix = vl_homkermap(vectors, 1, 'kchi2', 'gamma', .5) ;

%%
% TRAIN AND TEST
labels = attr_group.multiFeatureMap;
%bow_vectors = bow_vectors';
train_id = image_id(:,401:end);
test_id = image_id(:,1:400);

bow_vectors_train = bow_vectors(:,401:end);
bow_vectors_test = bow_vectors(:,1:400);

label_train = labels(:,train_id);
label_test = labels(:,test_id);

predict = [];

lambda = 1; % Regularization parameter
maxIter = 100000; % Maximum number of iterations

w = [] ;
num_of_attribute = size(label_test,1);
predict = zeros(num_of_attribute,size(test_id,2));
for i = 1:num_of_attribute;
    tic
    w = [];
    b = [];
    uni_labels = unique(label_train(i,:));
    bincounts = [];ind = [];
    [bincounts(1,:),ind] = histc(label_train(i,:),uni_labels);
    for ci = 1:size(uni_labels,2)
        y = 2 * (label_train(i,:) == uni_labels(1,ci)) - 1 ;
        [w(:,ci) b(ci) info] = vl_svmtrain(bow_vectors_train, y, lambda, ...
          'MaxNumIterations', maxIter);%, ...
          %'Solver', conf.svm.solver, ...
          %'BiasMultiplier', conf.svm.biasMultiplier, ...
          %'Epsilon', 1e-3);
    end
    scores = w' * bow_vectors_test + b' * ones(1,size(bow_vectors_test,2)) ;
    [drop, imageEstClass] = max(scores, [], 1) ;
    for j=1:size(imageEstClass,2)
        predict_label(1,j) = uni_labels(1,imageEstClass(1,j));
    end
    toc
    [bincounts(2,:),ind] = histc(predict_label,uni_labels);
    [bincounts(3,:),ind] = histc(label_test(i,:),uni_labels);
    [i sum(predict_label==label_test(i,:))/400]
    scores1 = w' * bow_vectors_train + b' * ones(1,size(bow_vectors_train,2)) ;
    [drop, imageEstClass1] = max(scores1, [], 1) ;
    for j=1:size(imageEstClass1,2)
        predict_label1(1,j) = uni_labels(1,imageEstClass1(1,j));
    end
    toc
    [bincounts(2,:),ind] = histc(predict_label1,uni_labels);
    [bincounts(3,:),ind] = histc(label_test(i,:),uni_labels);
    [i sum(predict_label1==label_train(i,:))/1600]
    predict(i,:) = predict_label;
end
%%
comp = predict==label_test;
save('comp.mat','comp');
mean(sum(comp,1)/num_of_attribute)

corr = sum(predict==label_test & predict ~= 0);
pred = sum(predict ~= 0);
gold = sum(label_test ~= 0);