function [ output_args ] = evaluation( predict_label, true_label, num)
%EVALUATION Summary of this function goes here
%   Detailed explanation goes here

% true attribute of testing set
%num = 2;
comp = abs(predict_label - true_label);
acc = 1-sum(comp)/size(comp,1);

pred = sum(predict_label');
true = sum(true_label');
comp_sum = sum(comp');

% plot bar graph for true label and predicted label
figure('Units','characters','Position',[30 30 120 35]);
[ax,b,p1] = plotyy(1:40*num,pred,1:40*num,true,'bar','plot');
hold on
%[ax,b,p2] = plotyy(1:40,pred,1:40,comp_sum,'bar','plot');
xlabel('training sample')
set(p1,'marker','o','color','red')
ylabel(ax(1),'predicted attributes') % left y-axis
ylabel(ax(2),'true attributes') % right y-axis
set(ax(1),'YLim',[1 312])
set(ax(1),'YTick',[1:30:312])
set(ax(2),'YLim',[1 312])
set(ax(2),'YTick',[1:30:312])
tmp = 40*num + 1;
set(ax(1),'xlim',[0 tmp]);
set(ax(2),'xlim',[0 tmp]);
legend('number of predicted 1s','number of true 1s','Location','northwest')

% accuracy rate
acc = 1-sum(comp)/size(comp,1);
mean(acc)

end

