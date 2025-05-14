module cache_dut_tb;
    //---------------------------------------------------------------------------------
    // Time unit setup.
    //---------------------------------------------------------------------------------
    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps = 5;

    //---------------------------------------------------------------------------------
    // Waveform generation.
    //---------------------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end

    //---------------------------------------------------------------------------------
    // TODO: Declare cache port signals:
    //---------------------------------------------------------------------------------

        logic   [31:0]  ufp_addr;
        logic   [3: 0]  ufp_rmask;
        logic   [3: 0]  ufp_wmask;
        logic   [31:0]  ufp_rdata;
        logic   [31:0]  ufp_wdata;
        logic           ufp_resp;
    //---------------------------------------------------------------------------------
    // TODO: Generate a clock:
    //---------------------------------------------------------------------------------
    
    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    //---------------------------------------------------------------------------------
    // TODO: Write a task to generate reset:
    //---------------------------------------------------------------------------------

    bit rst;
    task do_rst();

        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;

    endtask

    //---------------------------------------------------------------------------------
    // TODO: Instantiate the DUT and physical memory:
    //---------------------------------------------------------------------------------
    mem_itf mem_itf_s(.*);
    simple_memory #(.MEMFILE("/home/arshah6/Documents/ece411/mp_cache/sim/sim/memory.lst"))(
        .itf(mem_itf_s));

    cache cache_inst(
        .clk(clk), 
        .rst(rst), 
        .ufp_addr(ufp_addr), 
        .ufp_rmask(ufp_rmask), 
        .ufp_wmask(ufp_wmask), 
        .ufp_rdata(ufp_rdata), 
        .ufp_wdata(ufp_wdata), 
        .ufp_resp(ufp_resp), 
        
        .dfp_addr(mem_itf_s.addr), 
        .dfp_read(mem_itf_s.read), 
        .dfp_write(mem_itf_s.write), 
        .dfp_rdata(mem_itf_s.rdata), 
        .dfp_wdata(mem_itf_s.wdata), 
        .dfp_resp(mem_itf_s.resp)
    );

    //---------------------------------------------------------------------------------
    // TODO: Write tasks to test various functionalities:
    //---------------------------------------------------------------------------------

    task do_read(logic [32:0] addr, logic [3:0] r_mask);

        ufp_addr = addr;
        ufp_rmask = r_mask;
        ufp_wmask = 4'b0;
        ufp_wdata = 32'b0;
        @(posedge clk iff ufp_resp);

    endtask

    task do_write(logic [32:0] addr, logic [3:0] w_mask, logic [31:0] w_data);

        ufp_addr  = addr;
        ufp_rmask = 4'b0000;
        ufp_wmask = w_mask;
        ufp_wdata = w_data;
        @(posedge clk iff ufp_resp);

    endtask

    //---------------------------------------------------------------------------------
    // TODO: Main initial block that calls your tasks, then calls $finish
    //---------------------------------------------------------------------------------

    initial begin

        mem_itf_s.resp = 1'b0;
        do_rst();
        @(posedge clk iff rst == 1'b0);

        // Call Tasks


        $finish;

    end

endmodule : cache_dut_tb