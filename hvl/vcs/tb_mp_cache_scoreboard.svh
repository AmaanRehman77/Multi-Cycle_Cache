`ifndef __MP_CACHE_SCOREBOARD_SVH__
`define __MP_CACHE_SCOREBOARD_SVH__

class mp_cache_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(mp_cache_scoreboard)

    // Analysis ports to receive transactions from the monitor and reference model
    uvm_analysis_export#(mp_cache_transaction) monitor_export;
    uvm_analysis_export#(mp_cache_transaction) ref_model_export;

    // FIFOs to store transactions from the monitor and reference model
    uvm_tlm_analysis_fifo#(mp_cache_transaction) monitor_fifo;
    uvm_tlm_analysis_fifo#(mp_cache_transaction) ref_model_fifo;

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        monitor_export = new("monitor_export", this);
        ref_model_export = new("ref_model_export", this);
        monitor_fifo = new("monitor_fifo", this);
        ref_model_fifo = new("ref_model_fifo", this);
    endfunction

    // Connect phase: Connect analysis exports to FIFOs
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor_export.connect(monitor_fifo.analysis_export);
        ref_model_export.connect(ref_model_fifo.analysis_export);
    endfunction

    // Run phase: Compare transactions from the monitor and reference model
    virtual task run_phase(uvm_phase phase);
        forever begin
            mp_cache_transaction dut_trans, ref_trans;

            // Get transactions from the monitor and reference model
            monitor_fifo.get(dut_trans);
            ref_model_fifo.get(ref_trans);

            // Compare actual and expected outputs
            compare_transactions(dut_trans, ref_trans);
        end
    endtask

    // Task: Compare actual and expected transactions
    virtual task compare_transactions(mp_cache_transaction dut_trans, mp_cache_transaction ref_trans);
        // Compare response
        if (dut_trans.actual_ufp_resp !== ref_trans.expected_ufp_resp) begin
            `uvm_error("SCOREBOARD", $sformatf("Response mismatch! Expected: %0b, Actual: %0b",
                      ref_trans.expected_ufp_resp, dut_trans.actual_ufp_resp))
        end else begin
            `uvm_info("SCOREBOARD", "Response match", UVM_LOW)
        end

        // Compare read data (for read transactions)
        if (dut_trans.trans_type == READ && dut_trans.actual_ufp_rdata !== ref_trans.expected_ufp_rdata) begin
            `uvm_error("SCOREBOARD", $sformatf("Read data mismatch! Expected: 0x%0h, Actual: 0x%0h",
                      ref_trans.expected_ufp_rdata, dut_trans.actual_ufp_rdata))
        end else if (dut_trans.trans_type == READ) begin
            `uvm_info("SCOREBOARD", "Read data match", UVM_LOW)
        end
    endtask

endclass : mp_cache_scoreboard

`endif // __MP_CACHE_SCOREBOARD_SVH__