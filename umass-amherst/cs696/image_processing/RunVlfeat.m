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


% Initiate data
close all; clear
%run('~/CODE/MATLAB/AdditionalPackages/vlfeat-0.9.20/toolbox/vl_setup')

% preprocessing data // load imdb ...
[imdb, param] = preData();

% construct histogram feature vector for testing image
vectors = constructFeatures( imdb, param );
psix = vl_homkermap(vectors, 1, 'kchi2', 'gamma', .5) ;
%type = [ones(160,1);zeros(40,1)];
%imdb.type = type;
%% 
load('../text_mat/crossvalid.mat')
imdb.attributes = FEAT;
imdb.bow_vectors = vectors';
%clear vectors

%%
% TRAIN AND TEST

labels = [imdb.attributes.TRAIN{1}; imdb.attributes.TEST{1}]';
new_labels = [];
for i=1:200
    for j=1:10
        new_labels = [new_labels labels(:,i)];
    end
end

bow_vectors = imdb.bow_vectors';

%bow_vectors = vl_homkermap(bow_vectors, 1, 'kchi2', 'gamma', .5) ;

perm = randperm(size(bow_vectors,2));
train_id = perm(:,1:1600);
test_id = perm(:,1601:end);

bow_vectors_train = bow_vectors(:,train_id);
bow_vectors_test = bow_vectors(:,test_id);

label_train = new_labels(:,train_id);
label_test = new_labels(:,test_id);

predict = [];

lambda = 0.01 ; % Regularization parameter
maxIter = 100000 ; % Maximum number of iterations

w = [] ;
num_of_attribute = 50;
predict = zeros(size(test_id,2),num_of_attribute);
for i = 1:num_of_attribute;
    tic
    i
    w = [] ;
    
    y = 2 * label_train(i,:) - 1;
    y1 = 2 * label_test(i,:) - 1;
    [w(:,1) b(1) info] = vl_svmtrain(bow_vectors_train, y, lambda, 'MaxNumIterations', maxIter);
    %[w(:,2) b(2) info] = vl_svmtrain(bow_vectors_train, -y, lambda, 'MaxNumIterations', maxIter);
    scores = w' * bow_vectors_test + b' * ones(1,size(bow_vectors_test,2)) ;
    %[drop, imageEstClass] = max(scores, [], 1) ;
    %label = 2-imageEstClass;
    label = scores > 0;
    predict(:,i) = label';
    %predict = [predict,label'];
    toc
end

[ mean_precision, mean_recall ] = evaluation2 (predict, label_test');

% evaluation (1-predict, label_test', 10);
% %evaluation (predict, true_label, num);
