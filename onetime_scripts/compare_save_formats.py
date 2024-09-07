import csv
import numpy as np
import os

n = 1000000

# Save files
arr = np.random.rand(n)
np.save("numpy_arr", arr)
np.savez("numpy_arr_z", arr)

with open("csv_arr.csv", "w") as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerows([arr.tolist()])

# Print file sizes
for filename in ["numpy_arr_z.npz", "numpy_arr.npy", "csv_arr.csv"]:
    print(f"{filename} {os.stat(filename).st_size / (1024 * 1024)} MB")
    # 7.6MB, 7.6MB, 18.4MB