# PoroMechanicsFullSatMaterial

!syntax description /Kernels/PoroMechanicsFullSatMaterial

## Description

This is a mechanics only version of [PorousFlow1PhaseFullySaturated](PorousFlow1PhaseFullySaturated.md) that is meant for enriched Galerkin kernels and does not use the [PorousFlowDictator](PorousFlowDictator.md).

## Example Input Syntax

!listing test/tests/enrichedGalerkin/EG_Mandel.i block=Materials

!syntax parameters /Kernels/PoroMechanicsFullSatMaterial

!syntax inputs /Kernels/PoroMechanicsFullSatMaterial

!syntax children /Kernels/PoroMechanicsFullSatMaterial
