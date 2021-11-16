#!/bin/bash

mpirun -n 16 ../../../../non_local_ac-opt -i ./FeCu_single_precipitate_hydrostatic_pressure_50MPa.i --n-threads=2
mpirun -n 16 ../../../../non_local_ac-opt -i ./FeCu_single_precipitate_hydrostatic_pressure_100MPa.i --n-threads=2
mpirun -n 16 ../../../../non_local_ac-opt -i ./FeCu_single_precipitate_hydrostatic_pressure_200MPa.i --n-threads=2
mpirun -n 16 ../../../../non_local_ac-opt -i ./FeCu_single_precipitate_hydrostatic_pressure_400MPa.i --n-threads=2
