module cache (
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,                   // ufp_addr[1:0] will always be '0, that is, all accesses to the cache on UFP are 32-bit aligned
    input   logic   [3:0]   ufp_rmask,                  // specifies which bytes of ufp_rdata the UFP will use. You may return any byte at a position whose corresponding bit in ufp_rmask is zero. A nonzero ufp_rmask indicates a read request
    input   logic   [3:0]   ufp_wmask,                  // tells the cache which bytes out of the 4 bytes in ufp_wdata are to be written. A nonzero ufp_wmask indicates a write request.
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,                   // dfp_addr[4:0] should always be '0, that is, all accesses to physical memory must be 256-bit aligned.
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp

);


    // Data Array Signals
    logic         d_write_en [4];
    logic [255:0] data_in    [4];
    logic [255:0] data_out   [4];
    logic [31: 0] cache_wmask;

    // Tag Array Signals
    logic         t_write_en [4];
    logic [23 :0] tag_in     [4];
    logic [23: 0] tag_out    [4];

    // Valid Array Signals
    logic         v_write_en [4];
    logic         valid_in   [4];
    logic         valid_out  [4];

    // LRU Signals
    logic         load_lru;
    logic [2:0]   lru_in, lru_out;
    logic [1:0]   PLRU_way;

    enum int unsigned {
	    idle,
	    compare,
	    write_back,
	    allocate,
        stall
    } state, next_state;

    always_ff @(posedge clk) begin: next_state_assignment
        state <= next_state;
    end

    logic cache_hit;
    logic [3:0] way_hit;

    always_comb begin : cache_hit_logic
        way_hit[0] = (tag_out[0][22:0] == ufp_addr[31:9]) && valid_out[0];
        way_hit[1] = (tag_out[1][22:0] == ufp_addr[31:9]) && valid_out[1];
        way_hit[2] = (tag_out[2][22:0] == ufp_addr[31:9]) && valid_out[2];
        way_hit[3] = (tag_out[3][22:0] == ufp_addr[31:9]) && valid_out[3];

        cache_hit = way_hit[0] | way_hit[1] | way_hit[2] | way_hit[3];
    end


    always_comb begin : next_state_logic

        if (rst) next_state = idle;

        else begin

            case (state)

                idle : begin                                           // Wait for valid read or write request from processor
                    if (ufp_rmask != 4'b0 || ufp_wmask != 4'b0) next_state = compare;
                    else next_state = idle;
                end

                compare : begin
                    if (cache_hit) next_state = idle;                 
                    else if (tag_out[PLRU_way][23]) next_state = write_back;
                    else next_state = allocate;
                end

                write_back : begin
                    if (dfp_resp) next_state = allocate;
                    else next_state = write_back;
                end

                allocate : begin
                    if (dfp_resp) next_state = stall;
                    else next_state = allocate;
                end

                stall : next_state = compare;

                default: next_state = idle;

            endcase

        end    
    end

    logic [31:9] tag;
    logic [8:5]  set_index;
    logic [4:0]  offset;

    logic [31:0] w_maskEXT, r_maskEXT;

    logic [1:0] way_index;

    always_comb begin : LRU_Set

        case (way_index)
            2'b00 : lru_in = {1'b1, 1'b1, lru_out[0]};      // A
            2'b01 : lru_in = {1'b1, 1'b0, lru_out[0]};      // B
            2'b10 : lru_in = {1'b0, lru_out[1], 1'b1};      // C
            2'b11 : lru_in = {1'b0, lru_out[1], 1'b0};      // D
        endcase
        
    end

    always_comb begin : LRU_Decode

        if (lru_out[2] == 1'b0) begin
            PLRU_way = lru_out[1] ? 2'b01 : 2'b00;
        end
        else begin
            PLRU_way = lru_out[0] ? 2'b11 : 2'b10;
        end

    end

    always_comb begin : state_signals

        // Set Defaults:
        t_write_en [0] = 1'b0; 
        tag_in     [0] = tag_out[0];    
        v_write_en [0] = 1'b0;

        t_write_en [1] = 1'b0;
        tag_in     [1] = tag_out[1];
        v_write_en [1] = 1'b0;

        t_write_en [2] = 1'b0; 
        tag_in     [2] = tag_out[2];
        v_write_en [2] = 1'b0;

        t_write_en [3] = 1'b0;
        tag_in     [3] = tag_out[3];
        v_write_en [3] = 1'b0;

        tag       = ufp_addr[31:9];
        set_index = ufp_addr[8:5];
        offset    = ufp_addr[4:0];

        dfp_read  = 1'b0;
        dfp_write = 1'b0;
        dfp_addr  = 'x;
        dfp_wdata = 'x;

        ufp_resp  = 1'b0;
        ufp_rdata = 'x;

        w_maskEXT = {{8{ufp_wmask[3]}}, {8{ufp_wmask[2]}}, {8{ufp_wmask[1]}}, {8{ufp_wmask[0]}}};
        r_maskEXT = {{8{ufp_rmask[3]}}, {8{ufp_rmask[2]}}, {8{ufp_rmask[1]}}, {8{ufp_rmask[0]}}};
        cache_wmask = 32'b0;

        load_lru = 1'b0;

        data_in[0] = 256'b0;
        data_in[1] = 256'b0;
        data_in[2] = 256'b0;
        data_in[3] = 256'b0;

        d_write_en[0] = 1'b0;
        d_write_en[1] = 1'b0;
        d_write_en[2] = 1'b0;
        d_write_en[3] = 1'b0;

        if (way_hit[0] == 1'b1)      way_index = 2'b00;
        else if (way_hit[1] == 1'b1) way_index = 2'b01;
        else if (way_hit[2] == 1'b1) way_index = 2'b10;
        else if (way_hit[3] == 1'b1) way_index = 2'b11;
        else way_index = 'x;

        case (state)

            idle: ; 

            compare : begin
                
                if (cache_hit) begin

                    if (ufp_rmask != 4'b0) begin

                        ufp_rdata = data_out[way_index][32*offset[4:2]+:32] & r_maskEXT;

                    end

                    else if (ufp_wmask != 4'b0) begin

                        data_in[way_index] = {8{ufp_wdata & w_maskEXT}} ;         
                        d_write_en[way_index] = 1'b1;
                        cache_wmask = {28'b0,ufp_wmask} << (4*offset[4:2]);
                        // cache_wmask[4*offset[4:2]+:4] = ufp_wmask;

                        tag_in[way_index] = {1'b1, tag};
                        t_write_en[way_index] = 1'b1;

                    end

                    ufp_resp = 1'b1;
                    load_lru = 1'b1;

                end
            end

            allocate : begin

                dfp_read = 1'b1;
                dfp_addr = {ufp_addr[31:5], 5'b0};

                if (dfp_resp) begin
                    
                    cache_wmask = '1;
                    data_in[PLRU_way] = dfp_rdata;
                    d_write_en[PLRU_way] = 1'b1;
                    tag_in[PLRU_way] = {1'b0, tag};
                    t_write_en[PLRU_way] = 1'b1;

                    v_write_en[PLRU_way] = 1'b1;

                end
            end

            stall : ;

            write_back : begin

                dfp_write = 1'b1;
                dfp_addr  = {tag_out[PLRU_way][22:0], set_index, 5'b0};
                dfp_wdata = data_out[PLRU_way];

            end
        endcase

        
    end

    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (!d_write_en[i]),
            .wmask0     (cache_wmask),
            .addr0      (set_index),
            .din0       (data_in[i]),
            .dout0      (data_out[i])
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (!t_write_en[i]),
            .addr0      (set_index),
            .din0       (tag_in[i]),
            .dout0      (tag_out[i])
        );
        sp_ff_array #(.WIDTH(1)) valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (!v_write_en[i]),
            .addr0      (set_index),
            .din0       (1'b1),
            .dout0      (valid_out[i])
        );
    end endgenerate

    sp_ff_array #(.WIDTH(3)) lru_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (!load_lru),
            .addr0      (set_index),
            .din0       (lru_in),
            .dout0      (lru_out)
        );


endmodule