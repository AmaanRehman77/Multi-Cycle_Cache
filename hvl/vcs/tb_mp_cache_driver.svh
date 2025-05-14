`ifndef __MP_CACHE_DRIVER_SVH__
`define __MP_CACHE_DRIVER_SVH__

class mp_cache_driver extends uvm_driver#(mp_cache_transaction);
    `uvm_component_utils(mp_cache_driver)

    // Virtual interface
    virtual mp_cache_if vif;

    // Configuration object
    mp_cache_config cfg;

    // Random variables for delay and dfp_rdata
    rand int dfp_delay;             // Delay between request and response
    rand bit [255:0] dfp_rdata = 1; // Randomized DFP read data

    // Constraints for randomization
    constraint dfp_delay_c {
        dfp_delay inside {[1:10]}; // Delay between 1 and 10 cycles
    }

    constraint dfp_rdata_c {
        dfp_rdata != '0;
    }

    mp_cache_transaction req;

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build phase: Retrieve virtual interface and configuration
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Retrieve virtual interface
        if (!uvm_config_db#(virtual mp_cache_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("VIF", "Virtual interface not found!")
        end

        // Retrieve configuration object
        if (!uvm_config_db#(mp_cache_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("CFG", "Configuration object not found!")
        end
    endfunction

    // Reset phase
    virtual task reset_phase(uvm_phase phase);
        super.reset_phase(phase);

        phase.raise_objection(this);
        vif.driver_cb.rst <= 1'b1;
        vif.driver_cb.ufp_rmask <= '0;
        vif.driver_cb.ufp_wmask <= '0;
        vif.driver_cb.dfp_resp <= '0;
        repeat(2) @(vif.driver_cb);
        vif.driver_cb.rst <= 1'b0;
        repeat(10) @(vif.driver_cb);
        phase.drop_objection(this);
        `uvm_info(get_type_name(), "rst done", UVM_LOW)

    endtask

    // Run phase: Drive transactions
    virtual task run_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "inside run phase", UVM_LOW)
        super.run_phase(phase);
        // wait (vif.monitor_cb.rst === 1'b0);
        // repeat(10) @(vif.driver_cb);
        forever begin
            // Get a transaction from the sequencer
            `uvm_info(get_type_name(), "waiting to get req", UVM_LOW)
            seq_item_port.get(req); 
            `uvm_info(get_type_name(), "got req", UVM_LOW)

            // Drive the transaction onto the interface
            drive_transaction(req);
            // Indicate that the transaction is complete
            // seq_item_port.item_done();
        end
    endtask
    
    // Task: Drive a single transaction
    virtual task drive_transaction(mp_cache_transaction trans);
        // Wait for the next clock cycle
        @(vif.driver_cb);

        `uvm_info(get_type_name(), "Driving Transaction", UVM_LOW)


        // Drive UFP signals through the clocking block
        vif.driver_cb.ufp_addr  <= trans.rand_ufp_addr;
        vif.driver_cb.ufp_rmask <= trans.rand_ufp_rmask;
        vif.driver_cb.ufp_wmask <= trans.rand_ufp_wmask;
        vif.driver_cb.ufp_wdata <= trans.rand_ufp_wdata;

        // Wait for the cache response
        `uvm_info(get_type_name(), "Waiting for ufp_resp...", UVM_LOW)
        @(vif.driver_cb iff (vif.driver_cb.ufp_resp !== 1'bx));
        `uvm_info(get_type_name(), "ufp_resp received!", UVM_LOW)

        // Handle cache misses
        if (vif.driver_cb.ufp_resp === 1'b0) begin
            handle_cache_miss(trans);
        end

        // Debug message
        `uvm_info("DRIVER", $sformatf("Driven %s transaction: addr=0x%0h, wdata=0x%0h, rdata=0x%0h, resp=%0d",
                  (trans.trans_type == READ) ? "READ" : "WRITE",
                  trans.rand_ufp_addr, trans.rand_ufp_wdata, vif.driver_cb.ufp_rdata, vif.driver_cb.ufp_resp), UVM_HIGH)
    endtask

    // Task: Handle cache misses
    virtual task handle_cache_miss(mp_cache_transaction trans);
        // Wait for DFP read or write
        if (vif.driver_cb.dfp_read) begin
            drive_dfp_read(trans);
        end else if (vif.driver_cb.dfp_write) begin
            drive_dfp_write(trans);
        end else begin
            `uvm_error("DRIVER", "DFP read/write not driven on cache miss!")
        end
    endtask

    // Task: Drive DFP read
virtual task drive_dfp_read(mp_cache_transaction trans);
        // Randomize the delay and dfp_rdata
        if (!this.randomize()) begin
            `uvm_fatal("RAND", "Failed to randomize DFP delay or rdata!")
        end

        // Wait for the randomized delay
        repeat (dfp_delay) @(vif.driver_cb);

        // Drive DFP response and read data
        vif.driver_cb.dfp_rdata <= dfp_rdata;
        vif.driver_cb.dfp_resp  <= 1'b1;

        @(vif.driver_cb);
        vif.driver_cb.dfp_resp <= 1'b0;

        // Debug message
        `uvm_info("DRIVER", $sformatf("DFP read completed: addr=0x%0h, rdata=0x%0h, delay=%0d",
                  vif.driver_cb.dfp_addr, dfp_rdata, dfp_delay), UVM_HIGH)
    endtask

    // Task: Drive DFP write
    virtual task drive_dfp_write(mp_cache_transaction trans);
        // Randomize the delay
        if (!this.randomize(dfp_delay)) begin
            `uvm_fatal("RAND", "Failed to randomize DFP delay!")
        end

        repeat (dfp_delay) @(vif.driver_cb);

        vif.driver_cb.dfp_resp <= 1'b1;

        @(vif.driver_cb);

        vif.driver_cb.dfp_resp <= 1'b0;

        `uvm_info("DRIVER", $sformatf("DFP write completed: addr=0x%0h, wdata=0x%0h, delay=%0d",
                  vif.driver_cb.dfp_addr, vif.driver_cb.dfp_wdata, dfp_delay), UVM_HIGH)
    endtask


endclass : mp_cache_driver

`endif // __MP_CACHE_DRIVER_SVH__