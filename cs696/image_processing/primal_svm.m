function [sol,b,obj] = primal_svm(X,Y,lambda)
% [SOL, B] = PRIMAL_SVM(LINEAR,Y,LAMBDA,OPT)
% Solves the SVM optimization problem in the primal (with quatratic
%   penalization of the training errors).  
%
% If LINEAR is 1, a global variable X containing the training inputs
%   should be defined. X is an n x d matrix (n = number of points).
% If LINEAR is 0, a global variable K (the n x n kernel matrix) should be defined.  
% Y is the target vector (+1 or -1, length n). 
% LAMBDA is the regularization parameter ( = 1/C)
%
% IF LINEAR is 0, SOL is the expansion of the solution (vector beta of length n).
% IF LINEAR is 1, SOL is the hyperplane w (vector of length d).
% B is the bias
% The outputs on the training points are either K*SOL+B or X*SOL+B
% OBJ is the objective function value
% 
% OPT is a structure containing the options (in brackets default values):
%   cg: Do not use Newton, but nonlinear conjugate gradients [0]
%   lin_cg: Compute the Newton step with linear CG 
%           [0 unless solving sparse linear SVM]
%   iter_max_Newton: Maximum number of Newton steps [20]
%   prec: Stopping criterion
%   cg_prec and cg_it: stopping criteria for the linear CG.
 
% Copyright Olivier Chapelle, olivier.chapelle@tuebingen.mpg.de
% Last modified 25/08/2006  


% Call the right function depending on problem type and CG / Newton 
% Also check that X / K exists and that the dimension of Y is correct


[sol,obj] = primal_svm_linear_cg(X, Y,lambda);

% The last component of the solution is the bias b.
b = sol(end);
sol = sol(1:end-1);
fprintf('\n');
  
  

function  [w, obj] = primal_svm_linear_cg(X, Y,lambda)
% -----------------------------------------------------
% Train a linear SVM using nonlinear conjugate gradient 
% -----------------------------------------------------
[n,d] = size(X);

w = zeros(d+1,1); % The last component of w is b.
iter = 0;
out = ones(n,1); % Vector containing 1-Y.*(X*w)
go = [X'*Y; sum(Y)];  % -gradient at w=0 

s = go; % The first search direction is given by the gradient
while 1
    iter = iter + 1;
    if iter > 20 * min(n,d)
      warning(sprintf(['Maximum number of CG iterations reached. ' ...
                       'Try larger lambda']));
      break;
    end;

    % Do an exact line search
    [t,out] = line_search_linear(X, w,s,out,Y,lambda);
    w = w + t*s;

    % Compute the new gradient
    [obj, gn] = obj_fun_linear(X, w,Y,lambda,out); gn=-gn;
    
    % Stop when the relative decrease in the objective function is small 
    if t*s'*go < 1e-4*obj, break; end;

    % Flecher-Reeves update. Change 0 in 1 for Polack-Ribiere
    be = (gn'*gn - 0*gn'*go) / (go'*go);
    s = be*s+gn;
    go = gn;
end

  
  
function [obj, grad, sv] = obj_fun_linear(X,w,Y,lambda,out)
% Compute the objective function, its gradient and the set of support vectors
% Out is supposed to contain 1-Y.*(X*w)
out = max(0,out);
w0 = w; w0(end) = 0;  % Do not penalize b
obj = sum(out.^2)/2 + lambda*w0'*w0/2; % L2 penalization of the errors
grad = lambda*w0 - [((out.*Y)'*X)'; sum(out.*Y)]; % Gradient
sv = find(out>0);  
    
function [t,out] = line_search_linear(X,w,d,out,Y,lambda) 
% From the current solution w, do a line search in the direction d by
% 1D Newton minimization
t = 0;
% Precompute some dots products
Xd = X*d(1:end-1)+d(end);
wd = lambda * w(1:end-1)'*d(1:end-1);
dd = lambda * d(1:end-1)'*d(1:end-1);
while 1
    out2 = out - t*(Y.*Xd); % The new outputs after a step of length t
    sv = find(out2>0);
    g = wd + t*dd - (out2(sv).*Y(sv))'*Xd(sv); % The gradient (along the line)
    h = dd + Xd(sv)'*Xd(sv); % The second derivative (along the line)
    t = t - g/h; % Take the 1D Newton step. Note that if d was an exact Newton
                 % direction, t is 1 after the first iteration.
    if g^2/h < 1e-10, break; end;
    %    fprintf('%f %f\n',t,g^2/h)
end;
out = out2;
  

