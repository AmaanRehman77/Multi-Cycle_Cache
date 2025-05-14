`ifndef __MP_CACHE_PARAMS_SVH__
`define __MP_CACHE_PARAMS_SVH__

    // Cache parameters
    parameter int NUM_WAYS  = 4;          
    parameter int NUM_SETS  = 16;         
    parameter int LINE_SIZE = 256;      
    parameter int TAG_WIDTH = 23;        
    parameter int SET_WIDTH = 4;  

    // INTERFACE PARAMETER
    typedef enum {READ, WRITE} trans_type_t;


`endif // __MP_CACHE_PARAMS_SVH__