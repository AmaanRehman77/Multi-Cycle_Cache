module top_tb_uvm;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import tb_mp_cache_pkg::*;

    // Waveform generation.
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end

    bit clk;
    initial clk = 1'b1;
    always #1ns clk = ~clk;

    // UVM driven itf
    mp_cache_if itf(.*);

    // DUT
    cache dut (
        .clk        (clk),
        .rst        (itf.rst),
        .ufp_addr   (itf.ufp_addr),
        .ufp_rmask  (itf.ufp_rmask),
        .ufp_wmask  (itf.ufp_wmask),
        .ufp_rdata  (itf.ufp_rdata),
        .ufp_wdata  (itf.ufp_wdata),
        .ufp_resp   (itf.ufp_resp),
        .dfp_addr   (itf.dfp_addr),
        .dfp_read   (itf.dfp_read),
        .dfp_write  (itf.dfp_write),
        .dfp_rdata  (itf.dfp_rdata),
        .dfp_wdata  (itf.dfp_wdata),
        .dfp_resp   (itf.dfp_resp)
    );

    initial begin
        uvm_config_db#(virtual mp_cache_if)::set(uvm_root::get(), "*", "vif", itf);
        
        run_test();
    end

endmodule : top_tb_uvm