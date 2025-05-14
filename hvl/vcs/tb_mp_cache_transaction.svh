`ifndef __MP_CACHE_TRANSACTION_SVH__
`define __MP_CACHE_TRANSACTION_SVH__

class mp_cache_transaction extends uvm_sequence_item;
    // UVM MACROS
    `uvm_object_utils_begin(mp_cache_transaction)
        // `uvm_field_enum(trans_type_t, trans_type, UVM_ALL_ON)  
        `uvm_field_int(rand_ufp_addr,  UVM_ALL_ON)
        `uvm_field_int(rand_ufp_rmask, UVM_ALL_ON)
        `uvm_field_int(rand_ufp_wmask, UVM_ALL_ON)
        `uvm_field_int(rand_ufp_wdata, UVM_ALL_ON)
        `uvm_field_int(rand_dfp_rdata, UVM_ALL_ON)
        `uvm_field_int(expected_ufp_rdata, UVM_ALL_ON)
        `uvm_field_int(expected_ufp_resp,  UVM_ALL_ON)
        `uvm_field_int(actual_ufp_rdata,  UVM_ALL_ON)
        `uvm_field_int(actual_ufp_resp,   UVM_ALL_ON)
        `uvm_field_int(actual_dfp_addr,   UVM_ALL_ON)
        `uvm_field_int(actual_dfp_wdata,  UVM_ALL_ON)
    `uvm_object_utils_end


    // Transaction type: Read or Write
    rand trans_type_t trans_type;  

     // Randomized inputs to the cache
    rand bit [31:0]  rand_ufp_addr;   
    rand bit [3:0]   rand_ufp_rmask;  
    rand bit [3:0]   rand_ufp_wmask;  
    rand bit [31:0]  rand_ufp_wdata;  

    rand bit [255:0] rand_dfp_rdata;

    // Expected outputs from the reference model
    bit [31:0]  expected_ufp_rdata;   
    bit         expected_ufp_resp;    

    // Actual outputs from the cache (for comparison)
    bit [31:0]  actual_ufp_rdata;     
    bit         actual_ufp_resp;

    bit [31:0]  actual_dfp_addr;
    bit [31:0]  actual_dfp_wdata;      

    // Constraints for randomized mask values
    constraint mask_c {
        rand_ufp_wmask inside {4'b0001, 4'b0010, 4'b0100, 4'b1000, 4'b0011, 4'b1100, 4'b1111};
        rand_ufp_rmask inside {4'b0001, 4'b0010, 4'b0100, 4'b1000, 4'b0011, 4'b1100, 4'b1111};
    }

    constraint op_type {
        if (trans_type == READ)  rand_ufp_wmask == '0;
        if (trans_type == WRITE) rand_ufp_rmask == '0;
    }

    constraint ufp_addr_align {
        rand_ufp_addr[1:0] == 2'b00;
    }

    function new(string name="mp_cache_transaction");
        super.new(name);
    endfunction : new

endclass : mp_cache_transaction
`endif // __MP_CACHE_TRANSACTION_SVH__