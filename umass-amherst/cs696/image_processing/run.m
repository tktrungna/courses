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

conf.svm.solver = 'sdca' ;
%conf.svm.solver = 'sgd' ;
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
predict = [];
% number of images of each category
num = 4;
true_label = zeros(40*num,size(imdb.attributes.TRAIN{1},2));
options.MaxIter = 10000000;

        train_vector = imdb.bow_vectors(160*num,:);
        test_vector = imdb.bow_vectors(40*num,:);
        for j=1:160
            train_vector(j*num-num+1:j*num,:) = imdb.bow_vectors(j*10-num+1:j*10,:);
        end
        for j=1:40
            test_vector(j*num-num+1:j*num,:) = imdb.bow_vectors(1600+j*10-num+1:1600+j*10,:);
            for k = 1:num
                true_label(j*num-num+k,:) = FEAT.TEST{1}(j,:);
            end
        end
        

lambda = 0.1 ; % Regularization parameter
maxIter = 1000 ; % Maximum number of iterations
switch param.svm
case 'vlfeat'
    a=1;
    %lambda = 1 / (conf.svm.C *  length(selTrain)) ;
    w = [] ;
    %train_vector = imdb.bow_vectors(160*num,:);
    %test_vector = imdb.bow_vectors(40*num,:);
    
    for i = 1:size(imdb.attributes.TRAIN{1},2)
        i
        group = imdb.attributes.TRAIN{1}(:,i);
        new_group = zeros(size(group,1)*num,1);
        for j=1:size(group,1)
            new_group(j*num-num+1:j*num,:) = group(j);
        end
        group = new_group;
%         if sum(group==1)==0,
%             label = zeros(40*num,1);
%             predict = [predict,label];
%             continue;
%         end
%         if sum(group==0)==0,
%             label = ones(40*num,1);
%             predict = [predict,label];
%             continue;
%         end
        w = [] ;
        [w(:,1) b(1) info] = vl_svmtrain(train_vector', 1-group', lambda, 'MaxNumIterations', maxIter);
        [w(:,2) b(2) info] = vl_svmtrain(train_vector', group', lambda, 'MaxNumIterations', maxIter);
        %[w(:,i) b(i) info] = vl_svmtrain(train_vector', group', lambda, 'MaxNumIterations', maxIter);
        scores = w' * test_vector' + b' * ones(1,size(test_vector',2)) ;
        [drop, imageEstClass] = max(scores, [], 1) ;
        label = imageEstClass-1;
        predict = [predict,label'];
    end
otherwise
    for i=1:size(imdb.attributes.TRAIN{1},2),
        i
        group = imdb.attributes.TRAIN{1}(:,i);
        new_group = zeros(size(group,1)*num,1);
        for j=1:size(group,1)
            new_group(j*num-num+1:j*num,:) = group(j);
        end
        group = new_group;
        if sum(group==1)==0,
            label = zeros(40*num,1);
            predict = [predict,label];
            continue;
        end
        if sum(group==0)==0,
            label = ones(40*num,1);
            predict = [predict,label];
            continue;
        end
%         vector = imdb.bow_vectors(160*num,:);
%         test_vector = imdb.bow_vectors(40*num,:);
%         for j=1:160
%             vector(j*num-num+1:j*num,:) = imdb.bow_vectors(j*10-num+1:j*10,:);
%         end
%         for j=1:40
%             test_vector(j*num-num+1:j*num,:) = imdb.bow_vectors(1600+j*10-num+1:1600+j*10,:);
%             for k = 1:num
%                 true_label(j*num-num+k,:) = FEAT.TEST{1}(j,:);
%             end
%         end
        svmStruct = svmtrain(train_vector,group,'Options', options);
        label = svmclassify(svmStruct,test_vector);
        predict = [predict,label];
    end
end


%%
%evaluation (predict, true_label, num);
 [ mean_precision, mean_recall ] = evaluation2 (predict, true_label);
