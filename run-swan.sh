#!/bin/bash
#SBATCH --job-name=swan_bobbin
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=swan_bobbin-%j.out
#SBATCH --mail-user=mea21jpm@sheffield.ac.uk
#SBATCH --mail-type=ALL

module restore moose

source activate moose

cd /users/mea21jpm/projects/swan/input_files

mpirun -n $SLURM_NTASKS ../../swan-opt -i wire_bobbin_sim.i -w

