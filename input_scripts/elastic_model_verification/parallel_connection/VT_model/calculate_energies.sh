#!/bin/bash

# heterogenity parameter 1
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_1/heterogenity_1_diffusive_width_0025.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_1/heterogenity_1_diffusive_width_005.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_1/heterogenity_1_diffusive_width_01.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_1/heterogenity_1_diffusive_width_02.i

# heterogenity parameter 10
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_10/heterogenity_10_diffusive_width_0025.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_10/heterogenity_10_diffusive_width_005.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_10/heterogenity_10_diffusive_width_01.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_10/heterogenity_10_diffusive_width_02.i
# heterogenity parameter 1
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_100/heterogenity_100_diffusive_width_0025.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_100/heterogenity_100_diffusive_width_005.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_100/heterogenity_100_diffusive_width_01.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_100/heterogenity_100_diffusive_width_02.i
# heterogenity parameter 1
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_1000/heterogenity_1000_diffusive_width_0025.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_1000/heterogenity_1000_diffusive_width_005.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_1000/heterogenity_1000_diffusive_width_01.i
mpirun -n 8 ../../../../non_local_ac-opt -i ./heterogenity_parameter_1000/heterogenity_1000_diffusive_width_02.i
