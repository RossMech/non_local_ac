#!/bin/bash

mpirun -n 16 ../../non_local_ac-opt -i ./FeCu_single_precipitate_size_dependence_6nm.i
mpirun -n 16 ../../non_local_ac-opt -i ./FeCu_single_precipitate_size_dependence_8nm.i
mpirun -n 16 ../../non_local_ac-opt -i ./FeCu_single_precipitate_size_dependence_10nm.i
mpirun -n 16 ../../non_local_ac-opt -i ./FeCu_single_precipitate_size_dependence_13nm.i
mpirun -n 16 ../../non_local_ac-opt -i ./FeCu_single_precipitate_size_dependence_17nm.i
mpirun -n 16 ../../non_local_ac-opt -i ./FeCu_single_precipitate_size_dependence_23nm.i
mpirun -n 16 ../../non_local_ac-opt -i ./FeCu_single_precipitate_size_dependence_29nm.i
mpirun -n 16 ../../non_local_ac-opt -i ./FeCu_single_precipitate_size_dependence_38nm.i
mpirun -n 16 ../../non_local_ac-opt -i ./FeCu_single_precipitate_size_dependence_50nm.i
