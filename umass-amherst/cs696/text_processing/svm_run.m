% Training SVM classifiers and testing accuracy
load('../mat/crossvalid.mat')
accuracy = [];
for j=1:5,
    predict = [];
    for i=1:size(FEAT.TRAIN{j},2),
        group = FEAT.TRAIN{j}(:,i);
        if sum(group==1)==0,
            label = zeros(40,1);
            predict = [predict,label];
            continue;
        end
        if sum(group==0)==0,
            label = ones(40,1);
            predict = [predict,label];
            continue;
        end
        svmStruct = svmtrain(DATA.TRAIN{j},group);
        label = svmclassify(svmStruct,DATA.TEST{j});
        predict = [predict,label];
    end
    comp = abs(predict - FEAT.TEST{j});
    acc = 1-sum(comp)/size(comp,1);
    accuracy = [accuracy;acc];
end
%%
mean_acc = mean(accuracy);
hist(mean_acc)
mean(mean_acc)
%%
attr = load('attr_type.mat');
attr = attr.attr_type;
attr = [attr,num2cell(mean_acc')];
