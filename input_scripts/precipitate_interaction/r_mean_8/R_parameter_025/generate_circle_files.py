import numpy as np

# create array with angles between circles, degrees
theta_deg = np.array([0,10,20,30,38,40,50,60,70,80,90])

theta_rad = theta_deg * np.pi / 180

# array with distance coefficient between circles
r_coeff = np.array([0.25,0.5,1.0,2.0,4.0,8.0,16.0])

# radius of the precipitates, nm
R = 8 # the radius at R parameter = 0
R1 = 9.70 # Radius of the first circle
R2 = 5.82 # Radius of the second circle

# array with distance between circles
r_vect = R * r_coeff

# start a cycle over the angles
j = 0 # iteratiion variable over angles
for theta in theta_deg:

    # directory, where the files with circle parameters should be written
    dir_write = './theta_'+str(theta)+'/'

    # start a cycle over the distances

    # cycle indicator
    k = 0
    for r in r_vect:

        # Calculate the coordinates of the first precipitate
        x_1 = (R + r/2) * np.cos(theta_rad[j])
        y_1 = (R + r/2) * np.sin(theta_rad[j])

        # Calculate the coordinates of the second precipitate
        x_2 = - x_1
        y_2 = - y_1

        # file name generation
        if r_coeff[k] < 1: # if r_coeff is smaller then 1, then in name should be deleted a point
            r_coeff_str = str(r_coeff[k])
            r_coeff_str = r_coeff_str[0] + r_coeff_str[2:]
            file_name = 'circles_theta_'+str(theta)+'_r_'+r_coeff_str+'.txt'
        else:
            file_name = 'circles_theta_'+str(theta)+'_r_'+str(int(r_coeff[k]))+'.txt'

        # generate full name
        full_name = dir_write+file_name

        # open file to write
        file_var = open(full_name, 'w')

        # write a content in file
        file_var.write("x   y   z   r\n")
        file_var.write(str(x_1)+"   "+str(y_1)+"    " +"0.0"+"   "+str(float(R1))+"\n")
        file_var.write(str(x_2)+"   "+str(y_2)+"    "+"0.0"+"   "+str(float(R2))+"\n")

        # close file
        file_var.close()

        # By end of cycle add 1 to k
        k += 1

    # By end of cycle add 1 to j
    j += 1
