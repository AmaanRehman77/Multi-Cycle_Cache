`ifndef __MP_CACHE_SEQUENCER_SVH__
`define __MP_CACHE_SEQUENCER_SVH__

class mp_cache_sequencer extends uvm_sequencer #(mp_cache_transaction);
    `uvm_component_utils(mp_cache_sequencer)

    mp_cache_config cfg;

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_db#(mp_cache_config)::get(this, "", "cfg", cfg);
    endfunction : build_phase

endclass : mp_cache_sequencer

`endif // __MP_CACHE_SEQUENCER_SVH__