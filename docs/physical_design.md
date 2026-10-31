# Physical design methodology and macro integration

## Design setup

- Tool flow: OpenROAD Flow Scripts (ORFS), using Nangate45.
- Config: [`config.mk`](../physical_design/designs/nangate45/mnist_npu/config.mk).
- Timing constraints: [`constraint.sdc`](../physical_design/designs/nangate45/mnist_npu/constraint.sdc).
- Hard macro: 7 × `fakeram45_512x64`; ORFS reads macro LEF and Liberty files from the installed platform.
- Nominal setup: **5.0 ns clock**, 0.2 ns setup and 0.1 ns hold clock uncertainty, 1.0 ns max external input/output delay, explicit output capacitive load.
- Configured floorplan: utilization target 60%, core aspect ratio 1.2, core margin 10 µm. These are inputs, not necessarily the post-route measured utilization.
- Current config sets `LEC_CHECK = 0` and `CAP_MARGIN = 25`.

The repository includes many historical named experiments. Existing `results/` and `logs/` are retained; their presence does not establish a portable or independently reproduced flow.

## Stage sequence and checkpoints

| Stage | Design question | What to inspect |
| --- | --- | --- |
| Synthesis | Were arithmetic logic/memory macros mapped correctly? | `synth_stat.txt`, netlist, mapped SRAM count |
| Floorplan | Are seven hard macros legal and sensibly located? | Core bounds, macro orientations, halos/channels, placement log |
| PDN / tapcell | Are power shapes connected and rows properly cut? | `check_power_grid`, tapcell/power straps and obstruction views |
| Placement | Are utilization, wirelength and macro proximity reasonable? | Placement, congestion, resizing and cap/transition violations |
| CTS | Is the clock tree implementable? | Clock buffer count, clock skew, setup/hold paths |
| Routing | Are all nets routed and router violations resolved? | GRT congestion, DRT iteration report, antenna checks |
| Timing / extraction | Does the final routed design meet 5 ns? | Extracted parasitics, setup/hold WNS/TNS, cap and slew |
| Signoff | Does it meet independent physical and logical checks? | Standalone signoff DRC, LVS, LEC — **still to document** |

## Manual SRAM placement

[`macro.tcl`](../physical_design/designs/nangate45/mnist_npu/macro.tcl) places:

- Left column: 3 SRAMs, orientation **MY**.
- Right column: 4 SRAMs, orientation **R0**.
- Left/right outer core margin: 30 µm.
- Top/bottom margin: 20 µm.
- Center channel determined by available core width.

The committed [`final_5ns` macro-placement log](../physical_design/logs/nangate45/mnist_npu/final_5ns/2_2_floorplan_macro.log) shows seven macros placed and then recognized as fixed. This is evidence of placement; it does not alone prove that the channel is optimal.

## Power network

The [`final_5ns` PDN stage log](../physical_design/logs/nangate45/mnist_npu/final_5ns/2_4_floorplan_pdn.log) shows PDN insertion for all seven macros (it also emits an unused grid warning). A separate [`check_pdn.log`](../physical_design/check_pdn.log) reports connected VDD/VSS shapes, **but the accompanying script points to the `5ns_cap_margin25` experiment**, not an independently rechecked `final_5ns` snapshot. Keep this provenance distinction.

## Recorded routing check

The final_5ns [detailed-route log](../physical_design/logs/nangate45/mnist_npu/final_5ns/5_2_route.log) shows the routed iteration's violation count reaching **0** and subsequent antenna check net/pin violations **0**.

**Do not label this as signoff DRC clean.** Re-running standalone DRC on exported GDS and the correct rule deck is a separate verification step. Similarly, `finish__flow__errors__count = 0` means flow errors were not logged; it is not an LVS/DRC certification.

## Physical data retained

The existing final_5ns experiment includes ODB/DEF/GDS/netlist/SPEF artifacts and stage-specific reports. Large generated files have been kept unchanged by this documentation update. For long-term maintainability, later separate version-controlled scripts and selected evidence from regenerable binary artifacts, with care not to lose the experimental baselines.
