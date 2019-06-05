% Data directory
datadir = fullfile('/cluster','home','dbanco02');

% Ring dataset
dataset = fullfile(datadir,'simulated_data_small');
prefix = 'polar_image';


% Output directories
dirA = fullfile('/cluster','shared','dbanco02','wass_parallel_a');
dirB = fullfile('/cluster','shared','dbanco02','wass_parallel_b');
mkdir(dirA)
mkdir(dirB)

% Functions
funcName1 = 'wrap_FISTA_Circulant';
funcName2 = 'wrap_wass_reg_FISTA_Circulant';
jobDir1 = fullfile(datadir,['job_wass_parallel_init']);
jobDir2 = fullfile(datadir,['job_wass_parallel_ab']);
jobDir3 = fullfile(datadir,['job_wass_parallel_ba']);
mkdir(jobDir1)
mkdir(jobDir2)
mkdir(jobDir3)

%% Universal Parameters
% Ring sampling parameters
load(fullfile(dataset,ringName,[prefix,'_1.mat']));
P.num_theta= size(polar_image,2);
P.num_rad = size(polar_image,1);
P.dtheta = 1;
P.drad = 1;
P.sampleDims = [20,1];

% Basis function variance parameters
P.basis = 'norm2';
P.num_var_t = 15;
P.num_var_r = 10;
P.var_theta = linspace(P.dtheta/2,30,P.num_var_t).^2;
P.var_rad   = linspace(P.drad/2,  5,P.num_var_r).^2;

% Zero padding and mask\
zPad = [0,0];
zMask = [];


%% fista params
params.stoppingCriterion = 1;
params.tolerance = 1e-10;
params.L = 1000;
params.t_k = 1;
params.lambda = 0.0359;
params.wLam = 25;
params.gamma = 0.01;
params.beta = 1.2;
params.maxIter = 200;
params.maxIterReg = 5;
params.isNonnegative = 1;
params.zeroPad = zPad;
params.zeroMask = zMask;
params.noBacktrack = 0;
params.plotProgress = 0;
P.params = params;

%% Initialization parameters
P1 = P;
P1.params.tolerance = 1e-8;

%% Regularization parameters
P2 = P;

%% Parameters to vary
img_nums = 1:20;

imageDir = fullfile(dataset,ringName,prefix);
% Initialization jobs
k = 1;
for img = img_nums
    P1.img = img;
    P1.set = ring_num;
    varin = {imageDir,P1,dirA};
    funcName = funcName1;
    save(fullfile(jobDir1,['varin_',num2str(k),'.mat']),'varin','funcName')
    k = k + 1;
end

% Regularization jobs for dirA->dirB
k = 1;
for img = img_nums
    P2.img = img;
    P2.set = ring_num;
    varin = {dirA,P2,dirB};
    funcName = funcName2;
    save(fullfile(jobDir2,['varin_',num2str(k),'.mat']),'varin','funcName')
    k = k + 1;
end

% Regularization jobs for dirB->dirA
k = 1;
for img = img_nums
    P2.img = img;
    P2.set = ring_num;
    varin = {dirB,P2,dirA};
    funcName = funcName2;
    save(fullfile(jobDir3,['varin_',num2str(k),'.mat']),'varin','funcName')
    k = k + 1;
end

% Init script
slurm_write_matlab(numel(img_nums),jobDir1,'parallel_reg_wass_FISTA','batch_script.sh')

