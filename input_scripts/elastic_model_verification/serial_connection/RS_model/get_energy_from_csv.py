# python function to get value of elastic energy from csv file for morphology calculations

import pandas

def get_energy_from_csv(file_name):

    # read data from csv file
    current_database = pandas.read_csv(file_name)

    # get a last timestep data, which should be at equilibrium
    current_database = current_database.tail(1)

    # get a field from database, which corresponds to an equilibrium value
    current_database = current_database['total_f']
    current_database = current_database.to_numpy()
    current_database = float(current_database)
    return current_database
