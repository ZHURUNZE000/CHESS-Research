function runCoupledFISTA( P, Pc )
%runCoupledFISTA 

P.params.wLam = Pc.wLam;
P.params.gamma = Pc.gamma;
P.params.maxIterReg = Pc.maxIterReg;
dataset = Pc.dataset;
lambda_values = Pc.lambda_values;
num_outer_iters = Pc.num_outer_iters;
init_dir = Pc.init_dir;
output_dirA = Pc.output_dirA;
output_dirB = Pc.output_dirB;
baseFileName = Pc.baseFileName;
num_ims = Pc.num_ims;
prefix = Pc.prefix;

% Construct dictionary
switch P.basis
    case 'norm2'
        A0ft_stack = unshifted_basis_matrix_ft_stack_norm2(P);
end

Threshold = 32;
D = constructDistanceMatrix(P,Threshold);

if Pc.preInitialized
   start_ind = Pc.preInitialized;
else
    start_ind = 1;
end
    
    
for jjj = start_ind:num_outer_iters
    % setup io directories
    if jjj == 1
        input_dir = init_dir;
        output_dir = init_dir;
    elseif jjj == 2
        input_dir = init_dir;
        output_dir = output_dirA;
    elseif mod(jjj,2)
        input_dir = output_dirA;
        output_dir = output_dirB;
    else
        input_dir = output_dirB;
        output_dir = output_dirA;
    end
    % extract vdfs if beyond first pass
    if jjj > 1
        vdf_array = cell(num_ims,1);
        for ii = 1:num_ims
            f_data = load(fullfile(input_dir,sprintf(baseFileName,1,ii)));
            vdf_array{ii} = squeeze(sum(sum(f_data.x_hat,1),2))/sum(f_data.x_hat(:));
        end
        new_vdf_array = cell(num_ims,1);
    end
    vdfs = {};
    % iterate over each image
    parfor image_num = 1:num_ims
        im_data = load(fullfile(dataset,[prefix,'_',num2str(image_num),'.mat']));
        %% Zero pad image
        b = zeroPad(im_data.polar_image,P.params.zeroPad);
        % Scale image by 2-norm
        b = b/norm(b(:));
        
        P_local = P;
        P_local.set = 1;
        % Use selected lambda
        P_local.params.lambda = lambda_values(image_num);
 
        x_init = zeros(size(A0ft_stack));
        for i = 1:P.num_var_t
            for j = 1:P.num_var_r
                x_init(:,:,i,j) = b/(P.num_var_t*P.num_var_r);
            end
        end
        
        if jjj == 1
            % Initialization 
            switch Pc.initialization
                case 'causal'
                    if image_num == 1
                        [x_hat,err,obj,~,~,~] = FISTA_Circulant_Poisson(A0ft_stack,b,x_init,P_local.params);
                    else
                        [x_hat, err, ~, ~,  obj, ~] = space_wasserstein_FISTA_Circulant_Poisson(A0ft_stack,b,vdfs,D,x_init,P_local.params);
                    end
                case 'simultaneous'
                    [x_hat,err,obj,~,~,~] = FISTA_Circulant_Poisson(A0ft_stack,b,x_init,P_local.params);
            end
            new_vdf = squeeze(sum(sum(x_hat,1),2))/sum(x_hat(:));
            vdfs = {new_vdf};
            
        else
            % Consecutive iterations use t-1,t+1
            if image_num == 1
                vdfs = vdf_array(2);
            elseif image_num == num_ims
                vdfs = vdf_array(num_ims-1);
            else
                vdfs = {vdf_array{image_num-1},vdf_array{image_num+1}};
            end
            [x_hat, err, ~, ~,  obj, ~] = space_wasserstein_FISTA_Circulant_Poisson(A0ft_stack,b,vdfs,D,x_init,P_local.params);
            
            new_vdf_array{image_num} = squeeze(sum(x_hat,1))/sum(x_hat(:));
        end
        
        % Output data
        save_output(output_dir,baseFileName,x_hat,err,im_data.polar_image,P_local,Pc,image_num);
        save_obj(output_dir,jjj,image_num,obj);
    end
    if jjj > 1
        vdf_array = new_vdf_array;
    end
end

end

function save_output(output_dir,baseFileName,x_hat,err,polar_image,P,Pc,image_num)
    save(fullfile(output_dir,sprintf(baseFileName,P.set,image_num)),'x_hat','err','polar_image','P','Pc');
end
function save_obj(output_dir,pass,image_num,obj)
    save(fullfile(output_dir,sprintf('objective_%i_%i.mat',pass,image_num)),'obj');
end
