function [ neg_ene ] = negEnergy( cid, feature, t_params, f_params )
%NEGENERGY compute the value of the negative energy of the true label
%sequence after conditioning on the corresponding observed image sequence
    neg_ene = 0;
    for i=1:size(cid,2)-1,
        neg_ene = neg_ene + t_params(cid(i),cid(i+1));
    end
    potential = nodePotential( f_params, feature );
    for i=1:size(cid,2),
        neg_ene = neg_ene + potential(cid(i),i);
    end
end

