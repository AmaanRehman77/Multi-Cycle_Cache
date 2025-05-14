`ifndef __MP_CACHE_SEQ_SVH__
`define __MP_CACHE_SEQ_SVH__

// Base sequence: Populates the cache

////////////////////////////////////////////////////////////
////////////////SOMETHING HERE IS BROKEN////////////////////
////////////////////////////////////////////////////////////

class mp_cache_base_seq extends uvm_sequence #(mp_cache_transaction);
    `uvm_object_utils(mp_cache_base_seq)
    `uvm_declare_p_sequencer(mp_cache_sequencer)

    // Cache state tracking
    bit [31:0] cache_addr[NUM_SETS][NUM_WAYS];  // Track cache addresses

    // Constructor
    function new(string name = "mp_cache_base_seq");
        super.new(name);
    endfunction

    // Task to populate the cache
    virtual task populate_cache();
        `uvm_info("CACHE_POPULATE", "Populating cache...", UVM_LOW)

        for (int set_idx = 0; set_idx < NUM_SETS; set_idx++) begin
            for (int way_idx = 0; way_idx < NUM_WAYS; way_idx++) begin
                mp_cache_transaction trans;
                trans = mp_cache_transaction::type_id::create("trans");

                start_item(trans);
                if (!trans.randomize() with {
                    trans_type == READ;
                    rand_ufp_addr[8:5] == set_idx;  // Set index
                    !(rand_ufp_addr[31:9] inside {cache_addr[set_idx][$][31:9]});  // Unique tag
                }) begin
                    `uvm_fatal("RAND", "Randomization failed")
                end
                cache_addr[set_idx][way_idx] = trans.rand_ufp_addr;  // Update cache state
                finish_item(trans);
            end
        end

    endtask : populate_cache
endclass : mp_cache_base_seq

// Extended sequence: Single read -- tHIS CHANGES PLRU TWICE
class mp_cache_single_read_sequence extends mp_cache_base_seq;
    `uvm_object_utils(mp_cache_single_read_sequence)

    // Constructor
    function new(string name = "mp_cache_single_read_sequence");
        super.new(name);
        `uvm_info(get_type_name(), "Sequence Created (newed)", UVM_LOW)
    endfunction

    virtual task body();
        // Perform a single read operation

        bit [31:0] addr_to_reaccess;
        mp_cache_transaction trans_miss;
        mp_cache_transaction trans_hit;

        `uvm_info(get_type_name(), "Performing single read...", UVM_LOW)
        
        trans_miss = mp_cache_transaction::type_id::create("trans_miss");
        trans_hit = mp_cache_transaction::type_id::create("trans_hit");
        `uvm_info(get_type_name(), "starting first item", UVM_LOW)
        // First read (cache miss)
        start_item(trans_miss);
        if (!trans_miss.randomize() with {
            trans_type == READ;
        }) `uvm_fatal("RAND", "Randomization failed")
        addr_to_reaccess = trans_miss.rand_ufp_addr;  // Save address for re-access
        finish_item(trans_miss);
        `uvm_info(get_type_name(), "starting second item", UVM_LOW)
        // Second read (cache hit)
        start_item(trans_hit);
        if (!trans_hit.randomize() with {
            trans_type == READ;  // No write
            rand_ufp_addr == addr_to_reaccess;  // Re-access the same address
        }) `uvm_fatal("RAND", "Randomization failed")
        finish_item(trans_hit);

    endtask : body
endclass : mp_cache_single_read_sequence

// Extended sequence: Single write - THIS CHANGES PLRU TWICE
class mp_cache_single_write_sequence extends mp_cache_base_seq;

    `uvm_object_utils(mp_cache_single_write_sequence)

    // Constructor
    function new(string name = "mp_cache_single_write_sequence");
        super.new(name);
    endfunction

    virtual task body();

        // Perform a single write followed by a read
        // `uvm_info("SINGLE_WRITE", "Performing single write followed by read...", UVM_LOW)
        bit [31:0] addr_to_reaccess;

        mp_cache_transaction trans_write;
        mp_cache_transaction trans_read;

        trans_write = mp_cache_transaction::type_id::create("trans_write");
        trans_read = mp_cache_transaction::type_id::create("trans_read");

        // Cache Miss
        start_item(trans_write);
        if (!trans_write.randomize() with {
            trans_type == WRITE;  
        }) `uvm_fatal("RAND", "Randomization failed")
        addr_to_reaccess = trans_write.rand_ufp_addr;
        `uvm_info("SINGLE_WRITE", $sformatf("First write (miss): addr=0x%0h, data=0x%0h", 
                  trans_write.rand_ufp_addr, trans_write.rand_ufp_wdata), UVM_LOW)
        finish_item(trans_write);

        // Cache Hit
        start_item(trans_read);
        if (!trans_read.randomize() with {
            trans_type == READ;  
            rand_ufp_addr == addr_to_reaccess; 
        }) `uvm_fatal("RAND", "Randomization failed")
        `uvm_info("SINGLE_WRITE", $sformatf("Second read (hit): addr=0x%0h", addr_to_reaccess), UVM_LOW)
        finish_item(trans_read);

    endtask : body
endclass : mp_cache_single_write_sequence

class mp_cache_gen_seq extends mp_cache_base_seq;

    `uvm_object_utils(mp_cache_gen_seq)

    // Cache state tracking
    bit [31:0] cache_addr[NUM_SETS][NUM_WAYS];  // Track cache addresses

    // Constructor
    function new(string name = "mp_cache_gen_seq");
        super.new(name);
    endfunction

    virtual task populate_cache_addr();
        foreach (cache_addr[i, j]) begin
            cache_addr[i][j] = '0; 
        end
    endtask

    virtual task pre_body();
        populate_cache();
    endtask

    // Body task: Generate cache transactions
    virtual task body();
        `uvm_info("GEN_SEQ", "Generating cache transactions...", UVM_LOW)

        for (int i = 0; i < p_sequencer.cfg.num_transactions; i++) begin
            bit [31:0] addr;
            bit [1:0]  way;
            bit [3:0]  set;
            bit        hit;
            mp_cache_transaction trans;
            trans = mp_cache_transaction::type_id::create("trans");

            // Randomize hit/miss
            hit = ($urandom_range(0, 100) <= p_sequencer.cfg.hit_rate);

            // Randomize set and way
            set = $urandom_range(0, NUM_SETS - 1);
            way = $urandom_range(0, NUM_WAYS - 1);

            // Start transaction
            start_item(trans);

            // Randomize transaction type and address
            if (!trans.randomize() with {
                if (p_sequencer.cfg.read_only) {
                    trans_type == READ;  // Only generate read transactions
                } else if (p_sequencer.cfg.write_only) {
                    trans_type == WRITE; // Only generate write transactions
                } else {
                    trans_type dist {READ := 50, WRITE := 50};  // 50% read, 50% write
                }

                if (hit) {
                    rand_ufp_addr[8:5] == set;  // Use the same set for a hit
                    rand_ufp_addr[31:9] == cache_addr[set][way][31:9];  // Use the same tag for a hit
                } else {
                    !(rand_ufp_addr[31:9] inside {cache_addr[set][$][31:9]});  // Ensure a unique tag for a miss
                }
            }) begin
                `uvm_fatal("RAND", "Randomization failed")
            end

            // Update cache state
            addr = trans.rand_ufp_addr;
            cache_addr[set][way] = addr;

            // Finish transaction
            finish_item(trans);

            // Debug information
            `uvm_info("GEN_SEQ", $sformatf("Transaction %0d: %s to addr=0x%0h (hit=%0b)", 
                      i, (trans.trans_type == READ) ? "READ" : "WRITE", addr, hit), UVM_LOW)
        end
    endtask

endclass : mp_cache_gen_seq

`endif