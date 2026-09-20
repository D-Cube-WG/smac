# SMAC: Scalable High-Throughput FPGA Architecture for Message Authentication Code

FPGA implementation of SMAC, a recently proposed stand-alone Message Authentication Code optimized for hardware acceleration on Xilinx Kintex UltraScale+.

## Paper

| | |
|---|---|
| **Title** | Scalable High-Throughput FPGA Architecture for SMAC Message Authentication Code |
| **Authors** | Ahmet Malal, Hakan Güler, Bahadır Aydoğan, Oğuz Yayla |
| **Conference** | SECRYPT 2026 (23rd Int'l Conf. on Security and Cryptography) |
| **Location** | Porto, Portugal |
| **DOI** | [10.5220/0015062600004103](https://www.scitepress.org/Link.aspx?doi=10.5220/0015062600004103) |

## Abstract

SMAC is a recently proposed stand-alone Message Authentication Code constructed from repeated applications of the AES round function with an aggregation mode (SMAC-1×n) for scalable parallel processing. This work presents the first systematic FPGA-oriented architecture of SMAC on a Xilinx Kintex UltraScale+ platform, achieving **731 Gbps peak throughput** for SMAC-1×16 with near-linear scalability up to eight lanes.

## Key Contributions

- **First FPGA study of SMAC** with systematic architecture evaluation
- **Single-cycle Π transformation** using fully combinational AES rounds
- **Scalable SMAC-1×n architecture** supporting all aggregation factors (1-16)
- **Balanced XOR tree** aggregation enabling logarithmic latency
- **Near-linear throughput scaling** up to 8 lanes with deterministic behavior

## Performance Summary

| Config | LUT | FF | Frequency | Throughput | TPS |
|--------|-----|-----|-----------|------------|-----|
| SMAC-1 | 3,476 | 3,450 | 526 MHz | 67 Gbps | 19.4 |
| SMAC-1×2 | 5,712 | 4,600 | 526 MHz | 135 Gbps | 23.6 |
| SMAC-1×4 | 9,933 | 6,915 | 476 MHz | 244 Gbps | **24.5** |
| SMAC-1×8 | 18,652 | 11,551 | 435 MHz | 445 Gbps | 23.9 |
| SMAC-1×16 | 54,611 | 21,507 | 357 MHz | **731 Gbps** | 13.4 |

*TPS = Throughput Per Slice (Mbps/Slice)*

## Quick Start

### Simulate
```bash
cd vunit
python3 run_smac.py          # Full testbench
python3 run_smac_n.py        # SMAC-N variant
python3 run_smac_1.py        # SMAC-1 variant
```

### Build
1. Open Xilinx Vivado
2. Add VHDL files from `hdl/`
3. Run synthesis → implementation → bitstream

## Directory Structure

| Dir | Contents |
|-----|----------|
| `hdl/` | VHDL modules (smac, aes, variants) |
| `tb/` | Testbenches and packages |
| `vunit/` | Test automation scripts |
| `tcl/` | Vivado TCL scripts |
| `doc/` | Waveforms and documentation |

## Citation

```bibtex
@conference{secrypt26,
  author={Ahmet Malal and Hakan Güler and Bahadır Aydoğan and Oğuz Yayla},
  title={Scalable High-Throughput FPGA Architecture for SMAC Message Authentication Code},
  booktitle={Proceedings of the 23rd International Conference on Security and Cryptography - Volume 1: SECRYPT},
  year={2026},
  pages={96-107},
  publisher={SciTePress},
  organization={INSTICC},
  doi={10.5220/0015062600004103},
  isbn={978-989-758-858-7},
  issn={2184-7711}
}
```
