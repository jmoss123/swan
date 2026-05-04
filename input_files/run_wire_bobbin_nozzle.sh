#!/bin/bash
#SBATCH --job-name=wire_bobbin_nozzle
#SBATCH --output=%x_%j.out        
#SBATCH --error=%x_%j.err         
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32       
#SBATCH --mem=16G                  
#SBATCH --time=12:00:00            
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=jpamoss1@sheffield.ac.uk

# Module environment
module purge
module restore moose

# Conda Environment 
source ~/.bashrc
conda activate moose

# Move to the directory containing the input file
cd /users/mea21jpm/projects/swan/input_files

# Logging
echo "Job started: $(date)"
echo "Running on node: $(hostname)"
echo "MPI ranks: $SLURM_NTASKS"

# Run
mpirun -n $SLURM_NTASKS /users/mea21jpm/projects/swan/swan-opt -i wire_bobbin_nozzle_combined.i -w --n-threads=1

echo "Job finished: $(date)"
