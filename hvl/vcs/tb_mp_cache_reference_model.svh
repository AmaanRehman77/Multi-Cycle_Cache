`ifndef __MP_CACHE_REFERENCE_MODEL_SVH__
`define __MP_CACHE_REFERENCE_MODEL_SVH__

class cache_reference_model extends uvm_component;
    `uvm_component_utils(cache_reference_model)       

    // Cache entry structure
    typedef struct {
        bit [TAG_WIDTH-1:0] tag;          // Tag
        bit                 valid;        // Valid bit
        bit                 dirty;        // Dirty bit
        bit [LINE_SIZE-1:0] data;         // Data block
    } cache_entry_t;

    // Cache memory
    cache_entry_t cache_mem[NUM_SETS][NUM_WAYS];

    // PLRU state for each set
    bit [2:0] plru_state[NUM_SETS];        

    // State machine states
    typedef enum {IDLE, COMPARE, ALLOCATE, WRITEBACK} cache_state_t;
    cache_state_t current_state;

    // Interface to receive transactions
    uvm_analysis_imp#(mp_cache_transaction, cache_reference_model) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function void write(mp_cache_transaction trans);
        case (current_state)
            IDLE: begin
                if (trans.rand_ufp_rmask != 0 || trans.rand_ufp_wmask != 0) begin
                    current_state = COMPARE;
                end
            end

            COMPARE: begin
                // Check for cache hit
                bit hit = 0;
                int hit_way = -1;
                for (int way = 0; way < NUM_WAYS; way++) begin
                    if (cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][way].valid &&
                        cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][way].tag == trans.rand_ufp_addr[31:9]) begin
                        hit = 1;
                        hit_way = way;
                        break;
                    end
                end

                if (hit) begin
                    // Cache hit
                    if (trans.rand_ufp_rmask != 0) begin
                        // Read hit
                        trans.expected_ufp_rdata = cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][hit_way].data;
                        trans.expected_ufp_resp = 1;
                    end
                    else if (trans.rand_ufp_wmask != 0) begin
                        // Write hit
                        cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][hit_way].data = trans.rand_ufp_wdata;
                        cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][hit_way].dirty = 1;
                        trans.expected_ufp_resp = 1;
                    end
                    current_state = IDLE;
                end
                else begin
                    // Cache miss
                    if (cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][plru_state[trans.rand_ufp_addr[SET_WIDTH+1:2]]].dirty) begin
                        current_state = WRITEBACK;
                    end
                    else begin
                        current_state = ALLOCATE;
                    end
                end
            end

            ALLOCATE: begin
                // Allocate a new block
                int way_to_replace = plru_state[trans.rand_ufp_addr[SET_WIDTH+1:2]];
                cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][way_to_replace].tag = trans.rand_ufp_addr[31:9];
                cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][way_to_replace].valid = 1;
                cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][way_to_replace].dirty = 0;
                cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][way_to_replace].data = trans.rand_dfp_rdata;

                // Update PLRU state
                update_plru(trans.rand_ufp_addr[SET_WIDTH+1:2], way_to_replace);

                current_state = COMPARE;
            end

            WRITEBACK: begin
                // Write back dirty block
                int way_to_replace = plru_state[trans.rand_ufp_addr[SET_WIDTH+1:2]];
                // Simulate writing back to memory (not shown here)
                cache_mem[trans.rand_ufp_addr[SET_WIDTH+1:2]][way_to_replace].dirty = 0;

                current_state = ALLOCATE;
            end
        endcase
    endfunction

    // Function to update PLRU state
    function void update_plru(int set_index, int way);
        // Update PLRU state based on the accessed way
        case (way)
            0: plru_state[set_index] = {1'b1, 1'b1, plru_state[set_index][0]};
            1: plru_state[set_index] = {1'b1, 1'b0, plru_state[set_index][0]};
            2: plru_state[set_index] = {1'b0, plru_state[set_index][1], 1'b1};
            3: plru_state[set_index] = {1'b0, plru_state[set_index][1], 1'b0};
        endcase
    endfunction

endclass
`endif