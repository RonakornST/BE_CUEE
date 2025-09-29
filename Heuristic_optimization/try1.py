import numpy as np
from random import random,randint
x = float(0)
y = float(0)
z = float(0)
list = []
# solve 3*x + 4*y + 7*z = 100
out = 3*x + 4*y + 7*z
#gen chromosome
for i in range (100):
    list.append([randint(-100,100),randint(-100,100),randint(-100,100)])

# select survival chromosome
rank = []
print(list)

for chromosome in list:
    dict = {}
    for list in range(len(chromosome)):
        

    for x,y,z in chromosome:
        out = 3*x + 4*y + 7*z
    dict.append({abs(out-100):chromosome})
        
sorted_dict = dict(sorted(dict.items()))

#for i in range(len(rank)):
    #lowest = rank[i][1]








chromosome = np.random()
print()