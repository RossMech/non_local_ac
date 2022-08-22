#!/bin/bash

# heterogenity parameter 1
../../../../non_local_ac-opt -i ./heterogenity_parameter_1/heterogenity_1_diffusive_width_0025.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_1/heterogenity_1_diffusive_width_005.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_1/heterogenity_1_diffusive_width_01.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_1/heterogenity_1_diffusive_width_02.i

# heterogenity parameter 2
../../../../non_local_ac-opt -i ./heterogenity_parameter_2/heterogenity_2_diffusive_width_0025.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_2/heterogenity_2_diffusive_width_005.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_2/heterogenity_2_diffusive_width_01.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_2/heterogenity_2_diffusive_width_02.i

# heterogenity parameter 5
../../../../non_local_ac-opt -i ./heterogenity_parameter_5/heterogenity_5_diffusive_width_0025.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_5/heterogenity_5_diffusive_width_005.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_5/heterogenity_5_diffusive_width_01.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_5/heterogenity_5_diffusive_width_02.i

# heterogenity parameter 10
../../../../non_local_ac-opt -i ./heterogenity_parameter_10/heterogenity_10_diffusive_width_0025.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_10/heterogenity_10_diffusive_width_005.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_10/heterogenity_10_diffusive_width_01.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_10/heterogenity_10_diffusive_width_02.i

# heterogenity parameter 20
../../../../non_local_ac-opt -i ./heterogenity_parameter_20/heterogenity_20_diffusive_width_0025.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_20/heterogenity_20_diffusive_width_005.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_20/heterogenity_20_diffusive_width_01.i
../../../../non_local_ac-opt -i ./heterogenity_parameter_20/heterogenity_20_diffusive_width_02.i

# get csv file with energies
python get_energy_and_parameters.py
