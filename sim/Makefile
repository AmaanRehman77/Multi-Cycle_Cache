SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

PKG_SRCS  := $(PWD)/../pkg/types.sv $(PWD)/../pkg/tb_mp_cache_pkg.sv
HDL_SRCS  := $(shell find $(PWD)/../hdl -name '*.sv')
COMM_HVL  := $(shell find $(PWD)/../hvl/common                -name '*.sv' -o -name '*.v' -o -name '*.o' -o -name '*.so')
VCS_HVL   := $(COMM_HVL) $(shell find $(PWD)/../hvl/vcs       -name '*.sv' -o -name '*.v' -o -name '*.o' -o -name '*.so')
VER_HVL   :=
SRAM_SRCS := $(shell find $(PWD)/../sram/output -name '*.v')
HDRS      := $(shell find $(PWD)/../hvl -name '*.svh')
DW_IP     :=
VCS_SRCS  := $(PKG_SRCS) $(HDL_SRCS) $(VCS_HVL) $(SRAM_SRCS) $(DW_IP)
VER_SRCS  := $(PKG_SRCS) $(HDL_SRCS) $(VER_HVL) $(SRAM_SRCS) $(DW_IP)

TIMEOUT   ?= 10000000

export VCS_ARCH_OVERRIDE=linux
COMMON_FLAGS = +incdir+$(PWD)/../hvl/common
VCS_FLAGS    = $(COMMON_FLAGS) +incdir+$(PWD)/../hvl/vcs -licqueue -full64 -lca -sverilog -timescale=1ps/1ps -debug_acc+all -kdb -suppress=LCA_FEATURES_ENABLED -msg_config=../vcs_warn.config -xprop=../xprop.config -xprop=flowctrl -assert svaext
VER_FLAGS    = $(COMMON_FLAGS) +incdir+$(PWD)/../hvl/verilator -Wall --timescale 1ps/1ps -Mdir build -O3 -CFLAGS "-Ofast -march=native" --x-assign fast --x-initial fast --noassert --cc --exe ../verilator_warn.vlt --trace-fst --trace-structs --trace-max-array 1048576 --trace-max-width 1048576 +define+ECE411_VERILATOR
UVM_FLAGS= +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv $(UVM_HOME)/src/dpi/uvm_dpi.cc -CFLAGS -DVCS

ECE411_CACHE_TEST ?= mp_cache_single_read_test

vcs/top_tb: $(VCS_SRCS) $(HDRS)
	mkdir -p vcs
	cd vcs && vcs $(UVM_FLAGS) $(VCS_SRCS) $(VCS_FLAGS) -l compile.log -top top_tb_uvm -o top_tb_uvm

.PHONY: run_vcs_top_tb
run_vcs_top_tb: vcs/top_tb
	rm -f vcs/dump.fsdb
	python3 $(PWD)/../bin/get_options.py clock
	cd vcs && ./top_tb_uvm -l simulation.log -exitstatus -suppress=ASLR_DETECTED_INFO \
		+UVM_TESTNAME=$(ECE411_CACHE_TEST) \
		+UVM_NO_RELNOTES

.PHONY: run_verilator_lint
run_verilator_lint: $(VER_SRCS) $(HDRS)
	mkdir -p verilator
	cd verilator ;\
	verilator --lint-only $(VER_FLAGS) $(VER_SRCS) --top-module cache |& tee compile.log

.PHONY: covrep
covrep: vcs/top_tb.vdb
	cd vcs && urg -dir top_tb.vdb

.PHONY: verdi
verdi:
	mkdir -p verdi
	cd verdi && timeout $(ECE411_GUI_TIMEOUT) $(VERDI_HOME)/bin/verdi -ssf $(PWD)/vcs/dump.fsdb

.PHONY: clean
clean:
	rm -rf bin vcs verdi verilator