# PoroMechanicsFullSatTimeDerivative

!syntax description /Kernels/PoroMechanicsFullSatTimeDerivative

## Description

This is a mechanics only version of [PorousFlowFullySaturatedMassTimeDerivative](PorousFlowFullySaturatedMassTimeDerivative.md) that is meant for enriched Galerkin kernels and does not use the [PorousFlowDictator](PorousFlowDictator.md).

## Example Input Syntax

!listing test/tests/enrichedGalerkin/EG_Mandel.i block=Kernels

!syntax parameters /Kernels/PoroMechanicsFullSatTimeDerivative

!syntax inputs /Kernels/PoroMechanicsFullSatTimeDerivative

!syntax children /Kernels/PoroMechanicsFullSatTimeDerivative
