`ifndef __MP_CACHE_ENV_SVH__
`define __MP_CACHE_ENV_SVH__

class mp_cache_env extends uvm_env;
    `uvm_component_utils(mp_cache_env)

    // Components
    mp_cache_agent agent; // Cache agent (contains driver, monitor, and sequencer)
    // cache_reference_model ref_model; // Reference model
    // mp_cache_scoreboard scoreboard; // Scoreboard

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build phase: Create components
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create components
        agent = mp_cache_agent::type_id::create("agent", this);
        // ref_model = cache_reference_model::type_id::create("ref_model", this);
        // scoreboard = mp_cache_scoreboard::type_id::create("scoreboard", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // agent.mon.analysis_port.connect(ref_model.analysis_port);

        // Connect monitor's analysis port to the scoreboard
        // agent.monitor.analysis_port.connect(scoreboard.monitor_export);

        // Connect reference model's analysis port to the scoreboard
        // ref_model.analysis_export.connect(scoreboard.ref_model_export);

    endfunction
endclass : mp_cache_env

`endif // __MP_CACHE_ENV_SVH__