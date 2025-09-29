import numpy as np
from random import random,randint
x = float(0)
y = float(0)
z = float(0)
chromosome = []
# solve 3*x + 4*y + 7*z = 100
out = 3*x + 4*y + 7*z
#gen chromosome
for i in range (100):
    chromosome.append([randint(-100,100),randint(-100,100),randint(-100,100)])

# select survival chromosome
rank = []

for i in range (1000):

    for gene in chromosome:
        dict = {}
        for x,y,z in gene:
            out = 3*x + 4*y + 7*z
        dict.append({abs(out-100):gene})
        
    sorted_dict = dict(sorted(dict.items()))
    for i in range(len(rank)):
        lowest = rank[i][1]








chromosome = np.random()
print()