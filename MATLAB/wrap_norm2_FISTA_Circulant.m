function wrap_norm2_FISTA_Circulant(datadir,P,outputdir)
%wrap_FISTA_Circulant 

%% load polar image
str1 = sprintf('%i',P.load_step);
str2 = sprintf('%i',P.img);
fileName = ['polar_image_',str1,'_',str2,'.mat'];
fileDir = fullfile(datadir,fileName);
load(fileDir)

%% Zero pad image
b = zeroPad(polar_iamge,P.params.zeroPad);

P.num_rad = size(b,1);
P.num_theta = size(b,2);

%% Generate unshifted basis function matrices
A0ft_stack = unshifted_basis_matrix_ft_stack_norm2(P);

% Initialize solution
x_init = rand(size(A0ft_stack));
x_init = x_init/norm(x_init(:));

% Scale image by 2-norm
b = b/norm(b(:));

%% call function
[x_hat, err, obj, l_0] = FISTA_Circulant(A0ft_stack,polar_image,x_init,P.params);


%% save output
save(fullfile(outputdir,sprintf('fista_fit_%i_%i.mat',P.load_step,P.img)),'x_hat','err','polar_image','P')

end

