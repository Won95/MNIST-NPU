# Functional verification: evidence and remaining work

## Implemented checks

The checked-in [testbench](../tb/tb_npu_mnist_extended.sv) loads 64-bit weight words through the DUT SRAM write interface, loads 784 pixels per sample through the DUT image-input interface, then compares:

1. Selected SRAM-bank write addresses with expected words.
2. All 784 input-buffer pixels for every tested image.
3. All 32 FC1 outputs against Python-generated expectations.
4. All 10 FC2 scores against Python-generated expectations.
5. The predicted digit versus the golden score argmax; classification accuracy is separately compared with labels.

## Completed result — 100 samples

Source: [`simulation.log`](../simulation.log).

| Metric | Logged value |
| --- | --- |
| Loaded weight words | 3,200 |
| Representative SRAM write checks | PASS |
| Image checks | 100 / 100 images, 784 / 784 pixels each |
| RTL/golden mismatches | 0 |
| RTL classification accuracy | 98 / 100 (98.00%) |
| Python classification accuracy | 98 / 100 (98.00%) |
| Overall testbench result | PASS |

**Interpretation:** this proves agreement for the logged 100-sample run. It is **not** proof of full MNIST test-set accuracy, exhaustive state-space verification, gate-level equivalence, or that the current repository can reproduce the run without additional assets.

## The reproducibility gap

The testbench reads the following files from the simulator's **working directory**:

```text
weights.hex
labels.hex
image_0.hex ... image_(N-1).hex
fc1_expected_0.hex ... fc1_expected_(N-1).hex
fc2_expected_0.hex ... fc2_expected_(N-1).hex
```

It allows `+N=100` and `+N=1000`. At the time of this documentation, GitHub's `data/` directory has **1,000 `fc1_expected_*.hex` files**, but lacks the other required vector classes. Thus, a clean checkout is **not yet a self-contained inference test**. Do not fabricate weights or labels to make the test appear complete.

Check the missing assets locally with:

```bash
python3 scripts/check_inputs.py --data-dir data --samples 100
```

If the original training/preprocessing code and weights are available, add a deterministic export script together with a documented quantization scale, preprocessing convention, fixed model weights/checksum, dataset split, and expected predictions. The source of the weight file matters to the accuracy claim.

## Additional verification gates

- Re-run 100 and 1,000 cases from freshly generated and versioned input vectors.
- Add directed tests for signed INT8 extremes, saturation, ties in argmax, and reset/restart behavior.
- Verify weight SRAM at bank crossings and the last 64-bit word.
- Record compute-only latency, end-to-end inference latency, and throughput in cycles/sample under a documented definition.
- Confirm the same functional model for each purported RTL optimization candidate; the current synthesis config has `LEC_CHECK = 0`.
- If using formal tools, define precisely which equivalence is being checked (RTL vs RTL, RTL vs synthesized gates, or post-ECO).

**Status rule:** label verification claims as **logged**, **rerun and reproduced**, or **not yet checked**. Do not promote an unexecuted test to PASS.
