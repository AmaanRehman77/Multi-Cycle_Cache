`ifndef __MP_CACHE_CFG_SVH__
`define __MP_CACHE_CFG_SVH__

class mp_cache_config extends uvm_object;
    `uvm_object_utils(mp_cache_config)
    
    // Configuration parameters
    int num_transactions;  
    int hit_rate;          
    bit read_only;         
    bit write_only;        

    // UVM automation macros
    // `uvm_object_utils_begin(mp_cache_config)
    //     `uvm_field_int(num_transactions, UVM_ALL_ON)
    //     `uvm_field_int(hit_rate,         UVM_ALL_ON)
    //     `uvm_field_int(read_only,        UVM_ALL_ON)
    //     `uvm_field_int(write_only,       UVM_ALL_ON)
    // `uvm_object_utils_end

    // Constructor
    function new(string name = "mp_cache_config");
        super.new(name);
    endfunction

endclass : mp_cache_config

`endif // __MP_CACHE_CFG_SVH__