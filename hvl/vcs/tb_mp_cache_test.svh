`ifndef __MP_CACHE_BASE_TEST_SVH__
`define __MP_CACHE_BASE_TEST_SVH__

class mp_cache_base_test extends uvm_test;
    `uvm_component_utils(mp_cache_base_test)

    mp_cache_env env;
    mp_cache_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = mp_cache_config::type_id::create("cfg");
        // cfg.num_transactions = 0;
        // cfg.hit_rate = 0; 

        env = mp_cache_env::type_id::create("env", this);
        uvm_config_db#(mp_cache_config)::set(this, "*", "cfg", cfg);

    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        // `uvm_info(get_type_name(), "base waiting for rst", UVM_LOW)
        wait (env.agent.drv.vif.monitor_cb.rst === 1'b0);
        // `uvm_info(get_type_name(), "base saw rst low", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass : mp_cache_base_test

`endif

`ifndef __MP_CACHE_CONTINUOUS_READ_TEST_SVH__
`define __MP_CACHE_CONTINUOUS_READ_TEST_SVH__

class mp_cache_continuous_read_test extends mp_cache_base_test;
    `uvm_component_utils(mp_cache_continuous_read_test)

    // var: test seq
    mp_cache_gen_seq seq;

    // func: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // build_phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg.num_transactions = 1000;
        cfg.hit_rate = 100;
        cfg.read_only = 1;
    endfunction : build_phase

    // func: run_phase
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        seq = mp_cache_gen_seq::type_id::create("mp_cache_gen_seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask : run_phase

endclass : mp_cache_continuous_read_test

`endif // __MP_CACHE_CONTINUOUS_READ_TEST_SVH__

`ifndef __MP_CACHE_CONTINUOUS_WRITE_TEST_SVH__
`define __MP_CACHE_CONTINUOUS_WRITE_TEST_SVH__

class mp_cache_continuous_write_test extends mp_cache_base_test;
    `uvm_component_utils(mp_cache_continuous_write_test)

    // var: test seq
    mp_cache_gen_seq seq;

    // func: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // build_phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg.num_transactions = 1000;
        cfg.hit_rate = 80;
        cfg.write_only = 1;
    endfunction : build_phase

    // func: run_phase
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        seq = mp_cache_gen_seq::type_id::create("mp_cache_gen_seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask : run_phase

endclass : mp_cache_continuous_write_test

`endif // __MP_CACHE_CONTINUOUS_WRITE_TEST_SVH__

`ifndef __MP_CACHE_MIX_TRANS_TEST_SVH__
`define __MP_CACHE_MIX_TRANS_TEST_SVH__

class mp_cache_mix_trans_test extends mp_cache_base_test;
    `uvm_component_utils(mp_cache_mix_trans_test)

    // var: test seq
    mp_cache_gen_seq seq;

    // func: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // build_phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg.num_transactions = 1000;
        cfg.hit_rate = 80;
    endfunction : build_phase

    // func: run_phase
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        seq = mp_cache_gen_seq::type_id::create("mp_cache_gen_seq");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask : run_phase

endclass : mp_cache_mix_trans_test

`endif // __MP_CACHE_MIX_TRANS_TEST_SVH__

`ifndef __MP_CACHE_SINGLE_READ_TEST_SVH__
`define __MP_CACHE_SINGLE_READ_TEST_SVH__

class mp_cache_single_read_test extends mp_cache_base_test;
    `uvm_component_utils(mp_cache_single_read_test)

    // test seq
    mp_cache_single_read_sequence seq;

    // func: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // func: build_phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg.num_transactions = 2;
        cfg.read_only = 1;

         // Print configuration settings
        `uvm_info("AGENT", $sformatf("Configuration: num_transactions=%0d, hit_rate=%0d, read_only=%0b, write_only=%0b", 
                  cfg.num_transactions, cfg.hit_rate, cfg.read_only, cfg.write_only), UVM_LOW)
    endfunction : build_phase

    // func: run_phase
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        // `uvm_info(get_type_name(), "super done", UVM_LOW)
        phase.raise_objection(this);
        // `uvm_info(get_type_name(), "obj raised, seq creating", UVM_LOW)
        seq = mp_cache_single_read_sequence::type_id::create("mp_cache_single_read_sequence");
        if (seq == null) begin
            `uvm_fatal("TEST", "Sequence creation failed!")
        end
        `uvm_info(get_type_name(), "single read seq starting", UVM_LOW)
        seq.start(env.agent.sqr);
        `uvm_info(get_type_name(), "single read seq finished", UVM_LOW)

        phase.drop_objection(this);
    endtask : run_phase

endclass : mp_cache_single_read_test

`endif //__MP_CACHE_SINGLE_READ_TEST_SVH__

`ifndef __MP_CACHE_SINGLE_WRITE_TEST_SVH__
`define __MP_CACHE_SINGLE_WRITE_TEST_SVH__

class mp_cache_single_write_test extends mp_cache_base_test;
    `uvm_component_utils(mp_cache_single_write_test)

    // test seq
    mp_cache_single_write_sequence seq;

    // func: new
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // func: build_phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    // func: run_phase
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        seq = mp_cache_single_write_sequence::type_id::create("mp_cache_single_write_sequence");
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
    endtask : run_phase

endclass : mp_cache_single_write_test

`endif //__MP_CACHE_SINGLE_WRITE_TEST_SVH__

