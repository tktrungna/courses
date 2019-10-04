function [ forward_messages, backward_messages ] = messages( clique_potentials )
%MESSAGES calculate forward and backward messages from clique potentials

num_char = size(clique_potentials,2);
num_cliques = size(clique_potentials,3);
num_messages = num_cliques - 1;

forward_messages = zeros(num_messages,num_char);
backward_messages = zeros(num_messages,num_char);

for i=1:num_messages,
    for j=1:num_char,
        if i == 1,
            forward_messages(i,j) = logSumExp(clique_potentials(:,j,i),1);
        else
            forward_messages(i,j) = logSumExp(clique_potentials(:,j,i) ...
                + forward_messages(i-1,:)',1);
        end
    end
end

for i=1:num_messages,
    for j=1:num_char,
        if i == 1
            backward_messages(i,j) = logSumExp(clique_potentials(j,:,num_messages+2-i),2);
        else                
            backward_messages(i,j) = logSumExp(clique_potentials(j,:,num_messages+2-i) + ...
                + backward_messages(i-1,:),2);
        end
    end
end
backward_messages = flipud(backward_messages);
end

