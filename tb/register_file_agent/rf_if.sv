interface rf_if  (
                  input clk, 
                  input res_n
                  );

logic  [3:0]    rf_address;         //output
logic  [63:0]   rf_write_data;      //output
logic  [63:0]   rf_read_data;       //input
logic           rf_access_complete; //input
logic           rf_invalid_address; //input
logic           rf_read_enable;     //output
logic           rf_write_enable;    //output

endinterface : rf_if