#!/bin/bash

mpirun -n 16 /home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt -i FeCu_precipitation_interaction_hetero_2_isotropic_non_equal_case_1.i
mpirun -n 16 /home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt -i FeCu_precipitation_interaction_hetero_2_isotropic_non_equal_case_2.i
mpirun -n 16 /home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt -i FeCu_precipitation_interaction_hetero_2_isotropic_non_equal_case_3.i
mpirun -n 16 /home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt -i FeCu_precipitation_interaction_hetero_2_isotropic_non_equal_case_4.i
mpirun -n 16 /home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt -i FeCu_precipitation_interaction_hetero_2_isotropic_non_equal_case_5.i