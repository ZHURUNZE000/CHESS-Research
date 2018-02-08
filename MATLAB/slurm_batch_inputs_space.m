% Data directory
datadir = fullfile('/cluster','home','dbanco02');

% Ring dataset
dataset = fullfile(datadir,'al7075_311_polar');

% Output directory
outputdir = fullfile('/cluster','shared','dbanco02','al7075_311_polar_fit_spatial_1');
mkdir(outputdir)

% Function
funcName = 'init_FISTA_Circulant';

jobDir = fullfile(datadir,'job_al7075_311_spatial');
mkdir(jobDir)

%% Fixed Parameters
% Ring sampling parameters
P.ring_width = 20;
P.num_theta= 2048;
P.num_rad = 2*P.ring_width+1;
P.dtheta = 2*pi/P.num_theta;
P.drad = 1;
P.sampleDims = [41,5];

% Basis function variance parameters
P.num_var_t = 15;
P.num_var_r = 10;
P.var_theta = linspace(P.dtheta,pi/64,P.num_var_t).^2;
P.var_rad   = linspace(P.drad,  2,    P.num_var_r).^2;

% basis weighting
P.weight = 1;
P.betap = P.dtheta*P.drad;
P.alphap = 10;

% fista params
params.stoppingCriterion = 2;
params.tolerance = 1e-6;
params.L = 1e1;
params.lambda = 50;
params.beta = 1.2;
params.maxIter = 20;
params.gamma = 0.5;
params.maxCycles = 10;
params.isNonnegative = 1;
P.params = params;

%% Parameters to vary
k = 0;

for img = 0:204 
    for load_step = 0 
        P.img = img;
        P.load_step = load_step;

        varin = {dataset,P,outputdir};
        save(fullfile(jobDir,['varin_',num2str(k),'.mat']),'varin','funcName')
        k = k + 1;
    end
end

% Init script
slurm_write_bash(k-1,jobDir,'init_batch_script.sh','0-204')
% Odd script
slurm_write_bash(k-1,jobDir,'odd_batch_script.sh','0-204:2')
% Even script
slurm_write_bash(k-1,jobDir,'even_batch_script.sh','1-203:2')
