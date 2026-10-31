# Reproducibility and experiment protocol

## Scope of this documentation update

Existing RTL, historical ORFS logs/results and GDS files are **intentionally preserved**. This update adds navigation, evidence extraction and a checklist. It does **not** rerun synthesis/simulation, regenerate weights, sign off GDS, or establish formal equivalence.

## Source tree

- Source RTL: `rtl/*.sv`, top `npu_top`.
- Testbench: `tb/tb_npu_mnist_extended.sv`.
- ORFS config: `physical_design/designs/nangate45/mnist_npu/config.mk`.
- SDC and placement config: alongside `config.mk`.
- Historical run output: `physical_design/logs/nangate45/mnist_npu/<run>/` and corresponding `reports/`/`results/` folders.
- Example report JSON: `physical_design/logs/nangate45/mnist_npu/final_5ns/6_report.json`.

## Local audit commands (no EDA installation needed)

```bash
git clone https://github.com/Won95/MNIST-NPU.git
cd MNIST-NPU

# Summarize recorded post-route JSON reports.
python3 scripts/compare_ppa.py
python3 scripts/compare_ppa.py --all --format json

# List missing simulation vectors.
python3 scripts/check_inputs.py --data-dir data --samples 100
```

The missing-input checker returns a nonzero status until all required inputs exist. It is a data audit, not a failed RTL test.

## Clean simulation prerequisites

The testbench reads `weights.hex`, `labels.hex`, and per-sample `image_N.hex` / `fc1_expected_N.hex` / `fc2_expected_N.hex` from the **simulator working directory**. The original Python model/export procedure and a complete set of those files are not currently versioned here.

After generating or restoring the authoritative inputs, a local Icarus Verilog test could be *attempted* using:

```bash
# Example only; compile/runtime compatibility has not been revalidated here.
iverilog -g2012 -s tb_npu_mnist_extended -o sim_npu_test rtl/*.sv tb/tb_npu_mnist_extended.sv
vvp ./sim_npu_test +N=100
```

Run from a directory containing all expected vector filenames (or arrange the paths consistently). Do **not** count the presence of committed `sim_npu` as proof that a clean build is reproducible.

## Clean physical-design prerequisites

1. Install/build a documented OpenROAD Flow Scripts (ORFS) revision and its Nangate45 platform.
2. Confirm the local platform contains `fakeram45_512x64.lef` and `fakeram45_512x64.lib` plus their correct supporting GDS/views.
3. Verify absolute-path assumptions in `config.mk` (including `MACRO_PLACEMENT_TCL` and `IO_CONSTRAINTS` currently referencing `$HOME/MNIST-NPU`).
4. Check that tool, platform and synthesis RTL matches the intended experiment.
5. From the ORFS `flow/` directory, use its supported make targets with the absolute path to `config.mk`. Check local ORFS make target names/version before assuming they match historical runs.
6. Record all log/tool versions, final JSON, post-route timing, power analysis assumptions and exported GDS.
7. Perform independent signoff checks as a separate step.

## Experiment manifest template

For every new run, keep a manifest near its reports:

```yaml
name: exp_name
status: unverified
git_commit: <exact source commit>
rtl_sha256: <hash of source set>
orfs_commit: <exact ORFS revision>
openroad_version: <exact version>
platform: nangate45
macro_lef_sha256: <hash>
macro_lib_sha256: <hash>
sdc_sha256: <hash>
config_sha256: <hash>
extra_tcl_sha256: <hash>
clock_ns: 5.0
simulation_vector_set: <source and checksum>
lec_status: not_run
signoff_drc_status: not_run
```

`<...>` fields are placeholders for future experiments; they are deliberately **not** fabricated for past runs.

## Next work items

- [ ] Recover or regenerate deterministic weight/image/golden vector export sources.
- [ ] Reproduce the 100-case comparison, then complete the 1,000-case run.
- [ ] Verify boundary conditions, signed arithmetic, restart/reset and inference latency.
- [ ] Establish explicit RTL provenance for `final_5ns` and `exp_arith_tree_ks`.
- [ ] Run consistent side-by-side optimization experiments.
- [ ] Verify all timing constraints and unclocked/unconstrained paths.
- [ ] Complete independent DRC/LVS and suitable LEC before using “signoff clean.”
- [ ] Separate regenerable multi-megabyte binary results from the small reproducible sources in a later controlled repository cleanup.
