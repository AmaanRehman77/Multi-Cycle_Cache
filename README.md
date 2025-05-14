# Multicycle Cache with UVM Testbench

This repository contains the RTL and UVM-based verification environment for a parameterizable Multicycle Cache. The design supports a pipelined CPU interface and simulates realistic memory access latencies, while the UVM testbench provides a reusable, coverage-driven environment for functional verification.

## 🔧 Multicycle Cache (RTL)

### Features
- **Configurable Parameters**:
  - Cache size - (Made using OpenRam SRAMs)
  - Line/block size
    
- **Read/Write support** with hit/miss detection
- **Write-back + Write-allocate** policy
- **Multicycle miss penalty** modeled using FSM
- **Memory-mapped interface** with CPU and main memory
