#!/usr/bin/env python3
# * This file is part of the MOOSE framework
# * https://www.mooseframework.org
# *
# * All rights reserved, see COPYRIGHT for full restrictions
# * https://github.com/idaholab/moose/blob/master/COPYRIGHT
# *
# * Licensed under LGPL 2.1, please see LICENSE for details
# * https://www.gnu.org/licenses/lgpl-2.1.html
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math

from mpmath import *

# -------------------------------------------------------------------------------
# analytic solution Gringarten 1975
# For Rob
# 10 fractures
# 4 flow rates - 500, 1000, 1500, 200 gallons/min
# IMPORTANT - 1/2 spacing between fractures Gringarten 1975 eqn A19
frac_spacing = [2.5e2, 5e2, 7.5e2, 10e2, 15e2, 20e2, 1000e2]  # in cm
fracNum = 10  # number of fractures
gallonsPerMinute = 500  # gallons/minute

fracwidth = 50e2  # cm = 50m radius in y-direction
fracheight = 100e2  # cm = 100m frac height
z = fracheight  # distance between wells

# Material properties
Trock = 220  # C
Tinj = 65  # C

cpwater = 1  # 1.0 cal/(g*C)
rhowater = 1  # 1.0 g/(cm^3)

cprock = 0.19  # cal/(g*C) = 790 J/(kg*C)
rhorock = 2.75  # g/(cm^3) = 2750 kg/(m^3)
krock = 7.409e-3  # cal/(cm*s*K) = 3.1 Watts/(m*K)

# volumetric flow rate per fracture per unit thickness in y
volFlowRate = gallonsPerMinute * 63.09  # cm^3/s
Q = volFlowRate / fracwidth / fracNum

# Time
start = 3600
stop = 946080000
num_points = 50
timevector = np.logspace(np.log2(start), np.log2(stop), num=num_points, base=2)

# Solution to eqn A19 -- finite space between fractures set by frac_spacing
mp.dps = 9  # precision of inverse laplace transform
zd = z / fracheight
Twd_tilde = lambda s: 1 / s * exp(-zd * sqrt(s) * tanh(top / bottom * sqrt(s)))
# ------- Run for a range of seperations
# eqn A19 simplified inverse laplace transform
fig2, ax2 = plt.subplots()
# nondimensionalized Time eqn A9
# -- similar to eqn 10 except there is a 4 in the denominator
td = (
    (rhowater * cpwater) ** 2
    / (4 * krock * rhorock * cprock)
    * (Q / fracheight) ** 2
    * timevector
)

for j in range(len(frac_spacing)):
    top = rhowater * cpwater * Q * frac_spacing[j]
    bottom = 2 * krock * fracheight
    xed = rhowater * cpwater / krock * (Q / z) * frac_spacing[j]
    Twd = []
    Twater_finite = []
    for i in range(len(td)):
        temp = invertlaplace(Twd_tilde, td[i], method="talbot")
        Twd.append(temp)
        Twater_finite.append(Trock - temp * (Trock - Tinj))

    ax2.plot(
        timevector / (3600 * 24 * 365),
        Twater_finite,
        linestyle="-",
        fillstyle="none",
        label="{:.0f}m".format(2 * frac_spacing[j] / 100),
    )

ax2.set_ylim([50, 220])
ax2.set_xlim([0, 1])
ax2.set_ylabel("T (C)")
ax2.set_xlabel("Time (year)")
ax2.grid()
ax2.legend(title="Fracture Spacing", fontsize="small")
ax2.set_title(
    "Production Temperature \n Q={:.0f} gallons/minute".format(gallonsPerMinute)
    + "\n T_injection={:.0f} C;".format(Tinj)
    + " T_rock={:.0f} C".format(Trock),
    fontsize="medium",
)
filename = "flowrate_{:.0f}_1yr.pdf".format(gallonsPerMinute)
plt.savefig(filename)
plt.show()
