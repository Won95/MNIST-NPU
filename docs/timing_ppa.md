# Post-route timing and PPA comparison

## Source and conventions

These values are extracted from committed `physical_design/logs/nangate45/mnist_npu/<run>/6_report.json`. Positive setup/hold WNS means the reported worst slack meets its check. TNS = 0 is required for the corresponding timing check. Area comparison refers to **standard-cell area only**, excluding seven SRAM macros.

| Run | Setup WNS (ns) | Setup TNS (ns) | Hold WNS (ns) | Hold TNS (ns) | Std-cell area (µm²) | Cap violations |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `5ns` | −0.835428 | −3.313390 | −0.002624 | −0.002624 | 76,799.3 | 10 |
| `final_5ns` | +0.655638 | 0 | +0.001683 | 0 | 76,557.2 | 0 |
| `exp_arith_tree` | +0.779564 | 0 | +0.003880 | 0 | 72,458.4 | 0 |
| `exp_arith_tree_ks` | +0.801004 | 0 | +0.001724 | 0 | 72,005.1 | 0 |
| `exp_booth` | +0.536499 | 0 | −0.001168 | −0.001168 | 74,229.4 | 0 |

The run name is descriptive but **not sufficient evidence of the transformation actually applied**. Changes in netlist, RTL revision, synthesis passes, macro placement, SDC, and tool version must be tracked before any causal statement is made.

## Measured deltas (candidate vs timing-closed baseline)

Comparison: `exp_arith_tree_ks` minus `final_5ns`.

- Standard-cell area: `72,005.1 − 76,557.2 = −4,552.1 µm²`, a **5.95% reduction** relative to `final_5ns`.
- Setup WNS: `0.801004 − 0.655638 = +0.145366 ns`, a larger reported margin.
- Hold WNS: `0.001724 − 0.001683 ≈ +0.000040 ns`; both are positive, **but the hold margin is small**.
- Recorded estimated total power: `final_5ns = 0.0401427 W`; `exp_arith_tree_ks = 0.0401149 W`. Do not claim a meaningful power improvement without switching activity and power-model provenance.
- Die area also changes (`344,719 µm²` to `337,646 µm²`), so experiments must be assessed with proper control of placement settings; the lower std-cell area is not the full chip area.

## Critical path interpretation

The [`final_5ns/6_finish.rpt`](../physical_design/reports/nangate45/mnist_npu/final_5ns/6_finish.rpt) contains a reported worst-slack output path:

- **Startpoint:** `fc2_score[6][14]`, a clocked register.
- **Endpoint:** `digit[0]`, timed against the virtual output clock.
- **Arrival:** around 3.14 ns.
- **Required:** around 3.80 ns (5.0 ns clock, 0.2 ns uncertainty, 1.0 ns max output delay).
- **Slack:** about **+0.66 ns**.

The comparator/argmax output path should be investigated separately from register-to-register timing. The report also lists the internal `MAIN_CLOCK` minimum period near 2.31 ns and `fmax` near 432 MHz. **That value must not be presented as the complete 432 MHz external-interface operating capability**, because the constrained virtual-clock I/O path remains relevant.

## What is closed, and what is not

**Recorded for final_5ns:**
- 5 ns clock constraint with setup and hold TNS = 0.
- Setup and hold WNS > 0.
- Max capacitance and slew violations = 0 in the final metrics.
- Final detailed-router iteration violation count = 0.

**Not demonstrated by those reports:**
- Full multi-corner/multi-mode signoff.
- Independent GDS signoff DRC or LVS.
- RTL-to-gate formal equivalence (`LEC_CHECK = 0`).
- Correct signoff power with an actual workload SAIF/VCD.
- Apples-to-apples cause-and-effect analysis between experiments.

## Controlled follow-up experiment

1. Check out and record the exact RTL revision for each candidate.
2. Run common tests, include bank-boundary and arithmetic corner cases, and perform equivalence where available.
3. Keep clock, IO, macro Liberty/LEF, PDK, tool revision, floorplan constraints, and workload assumptions fixed.
4. Run each variant from synthesis through route and timing report.
5. Archive comparison metrics and critical path group(s), noting whether paths moved between endpoints.
6. Promote a candidate to the portfolio's reference implementation only if **functional correctness and physical constraints both hold**.

Generate a current report table without editing evidence:

```bash
python3 scripts/compare_ppa.py
python3 scripts/compare_ppa.py --all --format csv
```
