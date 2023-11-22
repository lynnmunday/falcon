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
# analytic solution for single fracture Gringarten 1975 eqn A18
# from Beckers, Koenraad <Koenraad.Beckers@nrel.gov>

# terms for infinite and finite space fractures
Trock = 300  # C
Tinj = 65  # 65  # C

cpwater = 1  # 1.0 cal/(g*C)
rhowater = 1  # 1.0 g/(cm^3)

cprock = 0.25  # 0.25 cal/(g*C)
rhorock = 2.65  # 2.65 g/(cm^3)
krock = 6.2e-3  # 6.2e-3cal/(cm*s*K)

volFlowRate = 1.45e5  # 1.45e5cm^3/s

fracwidth = 1e5  # 1 km thickness in y-direction
fracheight = 1e5  # 1km frac height or distance between wells
# volumetric flow rate per fracture per unit thickness in y
# only a single fracture
Q = volFlowRate / fracwidth


# nonDimensionalized Time (t_D*) from equation A9 [NOT EQN 10]
timevector = np.linspace(1, 3153600000, 100)  # np.logspace(6, 10, 50, base=10)
td = (
    (rhowater * cpwater) ** 2
    / (4 * krock * rhorock * cprock)
    * (Q / fracheight) ** 2
    * timevector
)
# Solution to eqn A18 -- infinite space between fractures
Twater_inf = []
Twd_inf = []
for i in range(len(td)):
    # eqn A18 solving for nonDimensionalized temperature
    temp = 1 - math.erf(1 / 2 / math.sqrt(td[i]))
    Twd_inf.append(temp)
    # convert to Temperature
    Twater_inf.append(Trock - temp * (Trock - Tinj))

# Solution to eqn A19 -- finite space between fractures set above by xe
# simplified inverse laplace transform
mp.dps = 9  # precision of inverse laplace transform
z = fracheight
zd = z / fracheight

# ------- Run for a range of seperations
# eqn A19 simplified inverse laplace transform
fig2, ax2 = plt.subplots()
# 1/2 spacing between fractures Gringarten 1975 eqn A19
frac_spacing = [20e2, 40e2, 80e2, 10e2]  # in cm
fracNum = 10  # number of fractures
Q = Q / fracNum
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
    Twd_tilde = lambda s: 1 / s * exp(-zd * sqrt(s) * tanh(top / bottom * sqrt(s)))
    Twd = []
    Twater_finite = []
    for i in range(len(td)):
        temp = invertlaplace(Twd_tilde, td[i], method="talbot")
        Twd.append(temp)
        Twater_finite.append(Trock - temp * (Trock - Tinj))

    ax2.plot(
        timevector / 3600 / 24 / 365,
        Twater_finite,
        linestyle="-",
        fillstyle="none",
        label="xe={:.0f}m".format(frac_spacing[j] / 100),
    )

ax2.plot(
    timevector / 3600 / 24 / 365,
    Twater_inf,
    "k",
    linestyle="-",
    fillstyle="none",
    label="inf",
)

ax2.set_ylim([0, 310])
ax2.set_xlim([0, 100])
ax2.set_ylabel("T (degC)")
ax2.set_xlabel("Time (year)")
ax2.grid()
ax2.legend()
ax2.set_title("production temperature")

plt.show()
