interface mp_cache_if (input logic clk);

    logic rst;

    // CPU side signals (UFP - Upward Facing Port)
    logic [31:0]  ufp_addr;    
    logic [3:0]   ufp_rmask;   
    logic [3:0]   ufp_wmask;   
    logic [31:0]  ufp_rdata;   
    logic [31:0]  ufp_wdata;   
    logic         ufp_resp;    

    // Memory side signals (DFP - Downward Facing Port)
    logic [31:0]  dfp_addr;   
    logic         dfp_read;   
    logic         dfp_write;  
    logic [255:0] dfp_rdata;  
    logic [255:0] dfp_wdata;  
    logic         dfp_resp;   

    // Clocking block for driver (driving signals)
    clocking driver_cb @(posedge clk);
        default input #1step output #1step;
        output rst;
        output ufp_addr, ufp_rmask, ufp_wmask, ufp_wdata;
        input  ufp_rdata, ufp_resp;
        input  dfp_addr, dfp_read, dfp_write, dfp_wdata;
        output dfp_rdata, dfp_resp;
    endclocking

    // Clocking block for monitor (sampling signals)
    clocking monitor_cb @(posedge clk);
        default input #1step output #1step;
        input rst;
        input ufp_addr, ufp_rmask, ufp_wmask, ufp_wdata, ufp_rdata, ufp_resp;
        input dfp_addr, dfp_read, dfp_write, dfp_wdata, dfp_rdata, dfp_resp;
    endclocking

    // Modport for driver
    modport driver_mp (clocking driver_cb, input clk);

    // Modport for monitor
    modport monitor_mp (clocking monitor_cb, input clk);


endinterface