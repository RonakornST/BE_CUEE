from math import sin,e
from random import randint,random
x = float(0)
y = float(0)
x1 = float(0)
y1 = float(0)
x2 = float(0)
y2 = float(0)
x2 = float(0)
y2 = float(0)

x2plus = float(0)
x2minus = float(0)
y2plus = float(0)
y2minus = float(0)
z2plus = -(x2plus*x2plus*sin(x2plus**2)) + 5*sin(3*x2plus)-(y2plus-1)**2
z2minus = -(x2minus*x2minus*sin(x2minus**2)) + 5*sin(3*x2minus)-(y2minus-1)**2

z1 = -(x1*x1*sin(x1**2)) + 5*sin(3*x1)-(y1-1)**2
z2 = -(x2*x2*sin(x2**2)) + 5*sin(3*x2)-(y2-1)**2
d = z2-z1

z2plus = float(0)
z2minus = float(0)

for i in range(10000):
    x2,y2 = x1 + randint(-9999,9999)/10000,y1 + randint(-9999,9999)/10000
    if -10<x2<10 and -10<y2<10: 
        print(x2,y2)
        if z2 - z1 <0:
            if random < 10*e**(-d/i):
                x1,y1 = x2,y2
                print('this is it')
            else:
                break


print(z1,x1,y1)