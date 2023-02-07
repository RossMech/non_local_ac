import numpy as np
import random

# number of random elements
N = 5

# create array with angles between circles, degrees
theta_deg = np.array([30,38])

theta_rad = theta_deg * np.pi / 180

# array with distance coefficient between circles
r_coeff = np.array([0.25,0.5,1.0,2.0,4.0,8.0])

# array with possible radii of the precipitates, nm
R = np.array([6.0,8.0,10.0,13.0])

# pick randomly 5 elements of the size, distance and angle array in correspondence to the hypothesis
theta_random = np.zeros(N)
r_coeff_random = np.zeros(N)
R_random = np.zeros(N)

for i in range(N):
    theta_random[i] = random.choice(theta_rad)
    r_coeff_random[i] = random.choice(r_coeff)
    R_random[i] = random.choice(R)


# array with distance between circles
r_vect = np.multiply(R_random,r_coeff_random)

# start a cycle over the angles
for i in range(N):

    # directory, where the files with circle parameters should be written
    dir_write = './'

    # Calculate the coordinates of the first precipitate
    x_1 = (R_random[i] + r_vect[i]/2) * np.cos(theta_random[i])
    y_1 = (R_random[i] + r_vect[i]/2) * np.sin(theta_random[i])

    # Calculate the coordinates of the second precipitate
    x_2 = - x_1
    y_2 = - y_1

    # file name generation
    file_name = 'circles_case_'+str(i+1)+'.txt'

    # generate full name
    full_name = dir_write+file_name

    # open file to write
    file_var = open(full_name, 'w')

    # write a content in file
    file_var.write("x   y   z   r\n")
    file_var.write(str(x_1)+"   "+str(y_1)+"    " +"0.0"+"   "+str(float(R_random[i]))+"\n")
    file_var.write(str(x_2)+"   "+str(y_2)+"    "+"0.0"+"   "+str(float(R_random[i]))+"\n")

    # close file
    file_var.close()

# write txt file with all the randomly generated parameters
parameters_array = np.vstack((R_random,r_coeff_random,theta_random))
np.savetxt('parameters.txt',parameters_array)
