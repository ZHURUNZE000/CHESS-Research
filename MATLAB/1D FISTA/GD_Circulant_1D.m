function [x_hat, err, obj, l_0, t_k, L] = GD_Circulant_1D(A0ft_stack,b,x_init,params)
%FISTA_Circulant_1D Image regression by solving LASSO problem 
%                argmin_x 0.5*||Ax-b||^2 + lambda||x||_1
%
%   Implementation of Fast Iterative Shrinkage-Thresholding Algorithm using 
%   convolutional subroutines for circulant matrix computations as
%   described in:
%   A. Beck and M. Teboulle, “A Fast Iterative Shrinkage-Thresholding 
%       Algorithm for Linear Inverse Problems,�? SIAM Journal on Imaging 
%       Sciences, vol. 2, no. 1, pp. 183202, Jan. 2009.
%
% Inputs:
% b          - (n) polar ring image
% A0ft_stack - (n x t) fft of unshifted gaussian basis matrices
% params     - struct containing the following field
%   lambda - l1 penalty parameter > 0
%   L - initial Lipschitz constant > 0
%   beta - backtracking parameter > 1
%   stoppingCriterion - integer indicated stopping criterion (1,2,3)
%   tolerance - tolerance for stopping criterion
%   maxIter - maximum number of iterations
%   isNonnegative - flag to enforce nonnegative solution
%   x_init - initial guess of solution
%
% Outputs:
% x_hat - (n x t) solution 
% err - (nIters) relative error of solution at each iteration
% obj - (nIters) objective value of solution at each iteration
% l_0 - (nIters) sparsity of solution at each iteration


% Define stopping criterion
STOPPING_OBJECTIVE_VALUE = 1;
STOPPING_SUBGRADIENT = 2;
COEF_CHANGE = 3;

% Set default parameter values
% stoppingCriterion = STOPPING_OBJECTIVE_VALUE;
% maxIter = 200 ;
% isNonnegative = 1;
% tolerance = 1e-3;
% x_init = ones(m,n,t,r) ;

% Get parameters
stoppingCriterion = params.stoppingCriterion;
tolerance = params.tolerance;
L = params.L;
lambda = params.lambda;
beta = params.beta;
maxIter = params.maxIter;
isNonnegative = params.isNonnegative;

tvBeta = params.tvBeta;
numIms = params.numIms;
imageNum = params.imageNum;

zPad = params.zeroPad;
zMask = params.zeroMask;
[n,t] = size(A0ft_stack) ;

if ~all(size(x_init)==[n,t])
    error('The dimension of the initial x_init does not match.');
end

b = zeroPad(b,zPad);
bnorm = norm(b(:));

% Track error, objective, and sparsity
err = nan(1,maxIter);
obj = nan(1,maxIter);
l_0 = nan(1,maxIter);

% Initial sparsity and objective
f = 0.5/bnorm*norm(b-Ax_ft_1D(A0ft_stack,x_init))^2 +...
    lambda * sum(sqrt(x_init(:).^2 + tvBeta^2));

min_f = f;
old_count = 0;

% Used to compute gradient
c = AtR_ft_1D(A0ft_stack,b)/bnorm;

x_init = forceMaskToZeroArray(x_init,zMask);
xkm1 = x_init;
xk = x_init;
zk = xk;
t_k = 1;
t_kp1 = 1;
keep_going = 1;
nIter = 0;
while keep_going && (nIter < maxIter)
    nIter = nIter + 1 ;        
    
    % Compute gradient of f
    grad = AtR_ft_1D(A0ft_stack,forceMaskToZero(Ax_ft_1D(A0ft_stack,xk),zMask))/bnorm - c - lambda*xk./sqrt(xk.^2 + tvBeta^2);
    
    stop_backtrack = 0;
    while ~stop_backtrack 
        
        %l1/nonnegative-proximal
        zk = xk - (1/L)*grad ;
        if isNonnegative
            zk(zk<0) = 0;
        end
        
        % Compute objective at xk/zk
        f_xk = 0.5/bnorm*forceMaskToZero(Ax_ft_1D(A0ft_stack,xk),zMask) + lambda*sum(sqrt(xk(:).^2 + tvBeta^2));
        f = 0.5/bnorm*forceMaskToZero(Ax_ft_1D(A0ft_stack,zk),zMask) + lambda*sum(sqrt(zk(:).^2 + tvBeta^2));
        
        criterion = f_xk - (1/L)*sum(grad(:).^2);

        
        % Stop backtrack if objective <= quadratic approximation
        if params.noBacktrack
            stop_backtrack = 1 ;
        elseif f <= criterion
            stop_backtrack = 1;
            params.noBacktrack = 1;
        else
            L = L*beta ;
            if L > 1e50
                keep_going = 0;
                stop_backtrack = 1;
            end
        end
    end
   
    % Track and display error, objective, sparsity
    err(nIter) = norm(b(:)-fit(:))/norm(b(:));
    obj(nIter) = f;
    l_0(nIter) = sum(abs(zk(:))>eps*10);
    disp(['Iter ',     num2str(nIter),...
          ' Obj ',     num2str(obj(nIter)),...
          ' L ',       num2str(L),...
          ' ||x||_0 ', num2str(l_0(nIter)),...
          ' RelErr ',  num2str(err(nIter)) ]);
    
    if params.plotProgress
        lim1 = 0;
        lim2 = max(b(:));
        figure(1)
       
        subplot(2,3,1)
        imshow(b,'DisplayRange',[lim1 lim2],'Colormap',jet);
        title('img')
        
        subplot(2,3,2)
        imshow(Ax_ft_1D(A0ft_stack,zk),'DisplayRange',[lim1 lim2],'Colormap',jet);
        title('xk')
        
        pause(0.05)
    end
    
    % Check stopping criterion
    switch stoppingCriterion
        case STOPPING_OBJECTIVE_VALUE
            % compute the stopping criterion based on the relative
            % variation of the objective function.
            criterionObjective = abs(f-prev_f);
            keep_going =  (criterionObjective > tolerance);
        case COEF_CHANGE
            diff_x = sum(abs(zk(:)-xkm1(:)))/numel(zk);
            keep_going = (diff_x > tolerance);
        otherwise
            error('Undefined stopping criterion.');
    end
    if f < min_f
        min_x = zk;
        min_f = f;
        min_iter = nIter;
        old_count = 0;
    else
        old_count = old_count + 1;
        if old_count > 20
            x_hat = min_x;
            err = err(1:old_iter) ;
            obj = obj(1:old_iter) ;
            l_0 = l_0(1:old_iter) ;
            return
        end
    end
    
    % Update indices
    xk = zk;
end

x_hat = xk;
err = err(1:nIter) ;
obj = obj(1:nIter) ;
l_0 = l_0(1:nIter) ;

function y = soft(x,T)
if sum(abs(T(:)))==0
    y = x;
else
    y = max(abs(x) - T, 0);
    y = sign(x).*y;
end