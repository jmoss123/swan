#!/bin/bash
#SBATCH --job-name=wire_bobbin_nozzle
#SBATCH --output=%x_%j.out        
#SBATCH --error=%x_%j.err         
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16       
#SBATCH --mem=8G                  
#SBATCH --time=24:00:00            
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=jpamoss1@sheffield.ac.uk

# Module environment
module purge
module restore moose

# Conda Environment
source activate moose

# Move to the directory containing the input file
cd /users/mea21jpm/projects/swan

# Logging
echo "Job started: $(date)"
echo "Running on node: $(hostname)"
echo "MPI ranks: $SLURM_NTASKS"

export LD_LIBRARY_PATH=/users/mea21jpm/.conda/envs/moose/lib:$LD_LIBRARY_PATH

# Run
mpiexec -n 16 ./swan-opt -i input_files/wire_bobbin_nozzle_combined.i -w

echo "Job finished: $(date)"
