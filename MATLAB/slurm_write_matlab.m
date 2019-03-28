function slurm_write_matlab( numJobs, jobDir, scriptFileName )
%slurm_write_bash Writes bash script to initiate batch job

scriptText = [...
'#!/bin/bash\n',...
'#SBATCH --time 24:00:00\n',...
'#SBATCH --mem-per-cpu=8000\n',...
'#SBATCH -p mpi\n',...
'#SBATCH -c 36\n',...
'#SBATCH --error=slurm_error.err\n',...
'#SBATCH --mail-type=END\n',...
'#SBATCH --mail-user=dbanco02@tufts.edu\n',...
'\n',...
'module load matlab\n',...
'matlab -nodisplay -nodesktop -nosplash -r',...
' "addpath(''../CHESS-Research/MATLAB'');',...
'parallel_reg_wass_FISTA_script; exit"\n',...
];

fileID = fopen(fullfile(jobDir,scriptFileName),'w');
fprintf(fileID,scriptText,numJobs);
fclose(fileID);

end
