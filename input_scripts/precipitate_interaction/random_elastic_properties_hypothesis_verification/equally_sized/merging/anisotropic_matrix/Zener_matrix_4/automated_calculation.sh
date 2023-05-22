#!/bin/bash

mpirun -n 16 /home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt -i ./FeCu_precipitation_interaction_homo_anisotropic_Z_4_merging_case_1.i
mpirun -n 16 /home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt -i ./FeCu_precipitation_interaction_homo_anisotropic_Z_4_merging_case_2.i
mpirun -n 16 /home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt -i ./FeCu_precipitation_interaction_homo_anisotropic_Z_4_merging_case_3.i
mpirun -n 16 /home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt -i ./FeCu_precipitation_interaction_homo_anisotropic_Z_4_merging_case_4.i
mpirun -n 16 /home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt -i ./FeCu_precipitation_interaction_homo_anisotropic_Z_4_merging_case_5.i