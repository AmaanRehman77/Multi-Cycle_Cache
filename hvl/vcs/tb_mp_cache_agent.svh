`ifndef __MP_CACHE_AGENT_SVH__
`define __MP_CACHE_AGENT_SVH__

class mp_cache_agent extends uvm_agent;
    `uvm_component_utils(mp_cache_agent)
    
    // Components
    mp_cache_sequencer sqr;  
    mp_cache_driver    drv;  
    mp_cache_monitor   mon;  

    // Configuration object
    // mp_cache_config cfg;

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build phase: Create components and retrieve configuration
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // cfg = mp_cache_config::type_id::create("cfg");
        // uvm_config_db#(mp_cache_config)::set(this, "*", "cfg", cfg);

        // if (!uvm_config_db#(mp_cache_config)::get(this, "", "cfg", cfg)) begin
        //     `uvm_fatal("CFG", "Configuration object not found!")
        // end

        // Create components
        sqr = mp_cache_sequencer::type_id::create("sqr", this);
        drv = mp_cache_driver::type_id::create("drv", this);
        mon = mp_cache_monitor::type_id::create("mon", this);

        // Pass the configuration object to the sequencer, driver, and monitor
        // uvm_config_db#(mp_cache_config)::set(this, "sqr", "cfg", cfg);
        // uvm_config_db#(mp_cache_config)::set(this, "drv", "cfg", cfg);
        // uvm_config_db#(mp_cache_config)::set(this, "mon", "cfg", cfg);

    endfunction

    // Connect phase: Connect driver to sequencer
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        drv.seq_item_port.connect(sqr.seq_item_export);  // Connect driver to sequencer
        `uvm_info(get_type_name(), "Sequencer connected to driver ...", UVM_LOW)
    endfunction

endclass : mp_cache_agent

`endif