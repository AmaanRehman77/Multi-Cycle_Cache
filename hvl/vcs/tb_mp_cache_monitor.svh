`ifndef __MP_CACHE_MONITOR_SVH__
`define __MP_CACHE_MONITOR_SVH__

class mp_cache_monitor extends uvm_monitor;
    `uvm_component_utils(mp_cache_monitor)

    // Analysis port to send transactions to scoreboard or coverage collector
    uvm_analysis_port#(mp_cache_transaction) analysis_port;

    // Virtual interface
    virtual mp_cache_if vif;

    // Configuration object (optional, for future use)
    mp_cache_config cfg;

    mp_cache_transaction trans;

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction : new

    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Retrieve virtual interface
        if (!uvm_config_db#(virtual mp_cache_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("VIF", "Virtual interface not found!")
        end

        // Retrieve configuration object (if needed)
        if (!uvm_config_db#(mp_cache_config)::get(this, "", "cfg", cfg)) begin
            `uvm_warning("CFG", "Configuration object not found, using defaults.")
        end
    endfunction : build_phase

    // Run phase
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        // Wait for reset to deassert
        // `uvm_info(get_type_name(), "Mon waiting for rst", UVM_LOW)
        wait(vif.monitor_cb.rst === 1'b0);
        // `uvm_info(get_type_name(), "Mon saw rst low", UVM_LOW)

        // Main monitoring loop
        forever begin
            fork
                monitor_interface(); // Monitor the cache interface for errors
                monitor_transactions(); // Capture transactions
            join
        end
    endtask : run_phase

    // Task: Monitor the cache interface for errors
    task monitor_interface();
        forever begin
            @(vif.monitor_cb);

            // Simultaneous read and write masks
            if (|vif.monitor_cb.ufp_rmask && |vif.monitor_cb.ufp_wmask) begin
                `uvm_error("DRIVER", "Read and write masks are both active!")
            end

            // Invalid addresses
            if ((vif.monitor_cb.ufp_rmask || vif.monitor_cb.ufp_wmask) && $isunknown(vif.monitor_cb.ufp_addr)) begin
                `uvm_error("DRIVER", "UFP address is unknown when masks are set!")
            end

            // DFP alignment
            if ((vif.monitor_cb.dfp_read || vif.monitor_cb.dfp_write) && vif.monitor_cb.dfp_addr[4:0] !== 2'b00) begin
                `uvm_error("MONITOR", "DFP address is not 32-bit aligned!")
            end
        end
    endtask : monitor_interface

    // Capture transactions
    task monitor_transactions();
        forever begin
            // Wait for a valid transaction (UFP read or write)
            // @(posedge vif.monitor_cb.clk iff (|vif.monitor_cb.ufp_rmask || |vif.monitor_cb.ufp_wmask));
            if (vif.monitor_cb.ufp_rmask !== '0 || vif.monitor_cb.ufp_wmask !== '0) begin

                @(vif.monitor_cb);
                trans = mp_cache_transaction::type_id::create("trans");

                // UFP signals
                trans.rand_ufp_addr    = vif.monitor_cb.ufp_addr;
                trans.rand_ufp_rmask   = vif.monitor_cb.ufp_rmask;
                trans.rand_ufp_wmask   = vif.monitor_cb.ufp_wmask;
                trans.rand_ufp_wdata   = vif.monitor_cb.ufp_wdata;
                trans.actual_ufp_rdata = vif.monitor_cb.ufp_rdata;
                trans.actual_ufp_resp  = vif.monitor_cb.ufp_resp;

                // Determine transaction type
                if (|vif.monitor_cb.ufp_rmask) begin
                    trans.trans_type = READ;
                end else if (|vif.monitor_cb.ufp_wmask) begin
                    trans.trans_type = WRITE;
                end

                // Handle cache misses
                if (vif.monitor_cb.ufp_resp === 1'b0) begin
                    handle_cache_miss(trans);
                end

                // Send transaction to analysis port
                analysis_port.write(trans);

                // Debug message
                `uvm_info("MONITOR", $sformatf("Captured %s transaction: addr=0x%0h, wdata=0x%0h, rdata=0x%0h, resp=%0d",
                        (trans.trans_type == READ) ? "READ" : "WRITE",
                        trans.rand_ufp_addr, trans.rand_ufp_wdata, trans.actual_ufp_rdata, trans.actual_ufp_resp), UVM_HIGH)
            end
        end
    endtask : monitor_transactions

    // Handle cache misses
    task handle_cache_miss(mp_cache_transaction trans);
        // Wait for DFP read or write
        if (vif.monitor_cb.dfp_read) begin
            monitor_dfp_read(trans);
        end else if (vif.monitor_cb.dfp_write) begin
            monitor_dfp_write(trans);
        end else begin
            `uvm_error("MONITOR", "DFP read/write not driven on cache miss!")
        end
    endtask : handle_cache_miss

    // Task: Monitor DFP read
    task monitor_dfp_read(mp_cache_transaction trans);
        bit [31:0] expected_addr = {trans.rand_ufp_addr[31:5], 5'b0};

        while (!vif.monitor_cb.dfp_resp) begin
            if (vif.monitor_cb.dfp_addr !== expected_addr) begin
                `uvm_error("MONITOR", $sformatf("DFP address mismatch! Expected: 0x%0h, Actual: 0x%0h",
                          expected_addr, vif.monitor_cb.dfp_addr))
            end
            if (vif.monitor_cb.dfp_read === 1'b0) begin
                `uvm_error("MONITOR", $sformatf("DFP address is not stable during read request"))

            end
            @(vif.monitor_cb);
        end

        // Capture DFP read data
        trans.rand_dfp_rdata = vif.monitor_cb.dfp_rdata;
    endtask : monitor_dfp_read

    // Monitor DFP write
    task monitor_dfp_write(mp_cache_transaction trans);
        bit [31:0] captured_addr;

        while (!vif.monitor_cb.dfp_resp) begin
            if (captured_addr === 0) begin
                captured_addr = vif.monitor_cb.dfp_addr;
            end else if (vif.monitor_cb.dfp_addr !== captured_addr) begin
                `uvm_error("MONITOR", "DFP address changed during writeback!")
            end
            @(vif.monitor_cb);
        end

        // Capture DFP write data
        trans.actual_dfp_wdata = vif.monitor_cb.dfp_wdata;
        trans.actual_dfp_addr  = captured_addr;
    endtask : monitor_dfp_write

endclass : mp_cache_monitor

`endif // __CUSTOM_CACHE_MONITOR_SVH__