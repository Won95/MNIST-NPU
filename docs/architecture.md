# Architecture and dataflow

## Scope and RTL sources

This is a **two-layer MLP inference datapath**, not a general-purpose NPU instruction set or a complete SoC. The top-level interface exposes loading ports, `start`, `done` and a four-bit digit result. Source of truth: [`rtl/npu_top.sv`](../rtl/npu_top.sv), [`rtl/controller.sv`](../rtl/controller.sv), [`rtl/pe.sv`](../rtl/pe.sv), and [`rtl/weight_memory.sv`](../rtl/weight_memory.sv).

| Item | Implementation |
| --- | --- |
| Top | `npu_top` |
| Network | FC1: 784×32; FC2: 32×10 |
| Activation / weight | Signed 8-bit |
| PE accumulation | Signed 32-bit register |
| Parallelism | 8 output-neuron PEs |
| Dataflow | Output-stationary (accumulator remains in PE) |
| FC1 processing | Four 8-output groups |
| FC2 processing | Two 8-output groups, last group writes only 2 outputs |
| FC1 postprocessing | Bias input is wired to zero, ReLU, arithmetic right shift by 8, INT8 saturation to 127 |
| FC2 postprocessing | Raw 32-bit scores feed an argmax comparator tree |

The PE computes `acc <= acc + A_in * B_in` when `valid_in` is high and clears its accumulator when `clear` is asserted. The 8 PEs receive a shared activation and eight distinct weights from the 64-bit SRAM word.

## Memory organization

### Input buffer

`input_buffer.sv` declares a 784-entry signed-INT8 RTL array with synchronous read and write. **This is not one of the seven weight SRAM macros.** It may infer flip-flops and mux structures under the configured synthesis flow.

### Weight SRAM

`weight_memory.sv` instantiates **seven `fakeram45_512x64` banks**. The 12-bit word address selects bank via bits [11:9] and a local word via bits [8:0], with a registered bank select aligned to synchronous macro read.

| Layer / grouping | Word address range | Allocated 64-bit words |
| --- | --- | ---: |
| FC1 group 0 | 0–783 | 784 |
| FC1 group 1 | 784–1567 | 784 |
| FC1 group 2 | 1568–2351 | 784 |
| FC1 group 3 | 2352–3135 | 784 |
| FC2 group 0 | 3136–3167 | 32 |
| FC2 group 1 | 3168–3199 | 32 |

- **Total allocated:** 3,200 64-bit words = 25,600 INT8 weight slots.
- **Actual network weights:** 784×32 + 32×10 = **25,408 INT8 weights**.
- **FC2 final group padding:** 192 extra INT8 slots because the 8-lane word still supplies two valid outputs.
- **Physical bank capacity:** 7×512 = 3,584 words, of which 384 are unallocated by the current map.
- The file `rtl/fakeram45_512x64.sv` supplies a behavioral simulation model; the physical flow excludes it from synthesized RTL and instead supplies macro `.lef`/`.lib` files from the local Nangate45 platform.

Do not equate allocated memory words with the number of meaningful learned weights.

## Controller and latency

The controller cycles through `IDLE → CLEAR → READ → MAC → DRAIN → RESULT → NEXT_GROUP` (or `DONE`). The counter spans 784 MAC cycles for each FC1 group and 32 MAC cycles for each FC2 group:

```text
FC1 issue cycles: 4 × 784 = 3,136
FC2 issue cycles: 2 ×  32 =    64
Total MAC-issue cycles   = 3,200
```

These **3,200 cycles count MAC issue opportunities only**. They are *not* a measured end-to-end inference latency: controller overhead, input loading, weight loading, and other interface behavior must be accounted for separately. A benchmark should timestamp `start` and `done` in the testbench.

## Argmax combinational depth

`rtl/argmax.sv` uses a comparison tree with 10→5→3→2→1 reduction. The four comparison levels are **combinational logic**, not four additional clocked pipeline stages. This can improve output-path logic depth versus a linear nine-comparator chain, but any timing improvement must be demonstrated with a controlled baseline.

## Key interfaces and risks

- `input_load_*` and `weight_load_*` are exposed to the outside; the design assumes external sequencing and no conflicting compute/weight-load access.
- The code uses a single `clk`; reset assumptions and test coverage should be documented before claiming robust operation.
- FC1 bias is not supplied by an external learned-bias memory (it is tied to zero in `npu_top.sv`).
- SRAM read pipeline and bank-select alignment need directed verification at bank boundaries (especially 511/512 and 3071/3072) to complement the representative checks already committed.
