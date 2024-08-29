#!/bin/bash
#SBATCH --job-name=pick_test
#SBATCH --time=2:00:00
#SBATCH --mem=700GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --open-mode=truncate
#SBATCH -o './logs/%x.out'
#SBATCH -e './logs/%x.err'
#SBATCH --mail-type=begin        # send email when job begins
#SBATCH --mail-type=end          # send email when job ends
#SBATCH --mail-user=cc27@princeton.edu
 
if [[ "$HOSTNAME" == *"tiger"* ]]
then
    echo "It's tiger"
    module load anaconda
    conda activate 247-main
elif [[ "$HOSTNAME" == *"della"* ]]
then
    echo "It's della-gpu"
    module purge
    module load anaconda3/2021.11
    conda activate 247-main
else
    module purge
    module load anacondapy
    source activate srm
fi

echo 'Requester:' $USER 'Node:' $HOSTNAME
echo "$@"
echo 'Start time:' `date`
start=$(date +%s)

make create-pickle
#if [[ -v SLURM_ARRAY_TASK_ID ]]
#then
#    python "$@" --conversation-id $SLURM_ARRAY_TASK_ID
#else
#    python "$@"
#fi

end=$(date +%s)
echo 'End time:' `date`
echo "Elapsed Time: $(($end-$start)) seconds"
