
load('classes.mat');

load('attr_type.mat');
load('all_doc.mat');
threshold = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9];
mean_acc = [];
mean_err = [];
mean_0slables = [];
for k=1:size(threshold,2),
    k
    feature=[];
    for i=1:200,
        cur = classes(i);
        att = [];
        for i=1:size(cur.images,1),
            att = [att,cur.images(i).is_present.*cur.images(i).certainty_id];
        end
        att = sum(att,2);
        att = att/max(att);
        att(att>=threshold(k))=1;
        att(att<threshold(k))=0;
        feature = [feature, att];
    end
    feature = feature';
    
    data1 = all_doc(1:40,:);
    data2 = all_doc(41:80,:);
    data3 = all_doc(81:120,:);
    data4 = all_doc(121:160,:);
    data5 = all_doc(161:200,:);

    feat1 = feature(1:40,:);
    feat2 = feature(41:80,:);
    feat3 = feature(81:120,:);
    feat4 = feature(121:160,:);
    feat5 = feature(161:200,:);

    DATA.TRAIN = {};
    DATA.TRAIN{1} = [data2;data3;data4;data5];
    DATA.TRAIN{2} = [data1;data3;data4;data5];
    DATA.TRAIN{3} = [data1;data2;data4;data5];
    DATA.TRAIN{4} = [data1;data2;data3;data5];
    DATA.TRAIN{5} = [data1;data2;data3;data4];
    DATA.TEST = {};
    DATA.TEST{1} = data1;
    DATA.TEST{2} = data2;
    DATA.TEST{3} = data3;
    DATA.TEST{4} = data4;
    DATA.TEST{5} = data5;

    FEAT.TRAIN = {};
    FEAT.TRAIN{1} = [feat2;feat3;feat4;feat5];
    FEAT.TRAIN{2} = [feat1;feat3;feat4;feat5];
    FEAT.TRAIN{3} = [feat1;feat2;feat4;feat5];
    FEAT.TRAIN{4} = [feat1;feat2;feat3;feat5];
    FEAT.TRAIN{5} = [feat1;feat2;feat3;feat4];
    FEAT.TEST = {};
    FEAT.TEST{1} = feat1;
    FEAT.TEST{2} = feat2;
    FEAT.TEST{3} = feat3;
    FEAT.TEST{4} = feat4;
    FEAT.TEST{5} = feat5;
    predict = [];
    for i=1:size(FEAT.TRAIN{1},2),
        group = FEAT.TRAIN{1}(:,i);
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
        svmStruct = svmtrain(DATA.TRAIN{1},group);
        label = svmclassify(svmStruct,DATA.TEST{1});
        predict = [predict,label];
    end
    comp = abs(predict - FEAT.TEST{1});
    acc = 1-sum(comp)/size(comp,1);
    mean_acc = [mean_acc,mean(acc)];
    err = sum(comp');
    true = sum(FEAT.TEST{1}');
    mean_err = [mean_err,mean(err)/312];
    mean_1slables = mean(true)/312;
    mean_0slables = [mean_0slables,1-mean(true)/312];
end
%% plot means

pred = sum(predict');
true = sum(FEAT.TEST{1}');
comp_sum = sum(comp');
figure('Units','characters','Position',[30 30 120 35]);
[ax,p1,p2] = plotyy(0.1:0.1:0.9,mean_acc,0.1:0.1:0.9,mean_0slables,'plot','plot');
xlabel('threshold values')
set(p1,'marker','o','color','red');
set(p2,'marker','x','color','green');
ylabel(ax(1),'predicted attributes','Color', 'k') % left y-axis
ylabel(ax(2),'true attributes','Color', 'k') % right y-axis
legend('predicted accuracy','baseline accuracy','Location','northwest')
set(ax(1),'YLim',[0.75 1])
set(ax(1),'YTick',[0.75:0.05:1])
set(ax(2),'YLim',[0.75 1])
set(ax(2),'YTick',[0.75:0.05:1])
set(ax(1),'xlim',[0 1]);
set(ax(2),'xlim',[0 1]);
