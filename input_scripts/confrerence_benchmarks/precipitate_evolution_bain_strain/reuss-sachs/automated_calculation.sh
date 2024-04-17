#!/bin/bash

mpirun -n 16 ../../../../non_local_ac-opt -i heterogenity_1_diffusive_width_0025.i
mpirun -n 16 ../../../../non_local_ac-opt -i heterogenity_1_diffusive_width_005.i
mpirun -n 16 ../../../../non_local_ac-opt -i heterogenity_1_diffusive_width_01.i
mpirun -n 16 ../../../../non_local_ac-opt -i heterogenity_1_diffusive_width_02.i