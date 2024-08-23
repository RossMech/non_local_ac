#!/bin/bash

find . -type f -name "*.i" | while read -r file; do
    mpirun -n 16 ~/projects/non_local_ac/non_local_ac-opt -i "$file"
done