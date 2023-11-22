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
Trock = 363 - 273.15
Tinj = 303 - 273.15
rhowater = 1000
cpwater = 4150
fracnumb = 1
fracwidth = 100
fracsep = 1000
krock = 2.83
fracheight = 10
rhorock = 2875
cprock = 825
mtot = 25 / 25 / 10
Q = mtot / rhowater / fracnumb / fracwidth  # volumetric flow rate per fracture
# terms needed for finite spaced fractures.  Gringarten 1975 eqn A19
z = fracheight

# nonDimensionalized Time (t_D*) from equation A9 [NOT EQN 10]
timevector = np.logspace(6, 11, 50, base=10)
td = (
    (rhowater * cpwater)
    * (rhowater * cpwater)
    / (4 * krock * rhorock * cprock)
    * (Q / fracheight)
    * (Q / fracheight)
    * timevector
)
# Solution to eqn A18 -- infinite space between fractures
Twater_inf = []
Twd_inf = []
for i in range(len(td)):
    # eqn A18 solving for nonDimensionalized temperature
    temp = 1 - math.erf(1 / (2 * math.sqrt(td[i])))
    Twd_inf.append(temp)
    # convert to Temperature
    Twater_inf.append(Trock - temp * (Trock - Tinj))

# Solution to eqn A19 -- finite space between fractures set above by xe
# simplified inverse laplace transform
mp.dps = 15
z = fracheight
zd = z / fracheight
Twd_tilde = lambda s: 1 / s * exp(-zd * sqrt(s) * tanh(top / bottom * sqrt(s)))

# ------- Run for a range of seperations
# eqn A19 simplified inverse laplace transform
fig1, ax1 = plt.subplots()
fig2, ax2 = plt.subplots()
# 1/2 spacing between fractures Gringarten 1975 eqn A19
frac_spacing = np.linspace(2, 40, 10)
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

    ax1.semilogx(
        td,
        Twd,
        linestyle="-",
        marker="o",
        fillstyle="none",
        label="xe={:.2f}m".format(frac_spacing[j]),
    )
    ax2.plot(
        timevector / 3600 / 24 / 365,
        Twater_finite,
        linestyle="-",
        fillstyle="none",
        label="xe={:.2f}m".format(frac_spacing[j]),
    )

ax1.semilogx(td, Twd_inf, "k", linestyle="-", fillstyle="none", label="inf")
ax2.plot(
    timevector / 3600 / 24 / 365,
    Twater_inf,
    "k",
    linestyle="-",
    fillstyle="none",
    label="inf",
)

ax1.set_ylim([0, 1])
ax1.set_xlim([1e-1, 1e3])
ax1.set_ylabel("dimensionless Temperature")
ax1.set_xlabel("dimensionless Time")
ax1.grid()
ax1.legend()

ax2.set_ylim([30, 100])
ax2.set_xlim([0, 30])
ax2.set_ylabel("T (degC)")
ax2.set_xlabel("Time (year)")
ax2.grid()
ax2.legend()
ax2.set_title("production temperature")

plt.show()
