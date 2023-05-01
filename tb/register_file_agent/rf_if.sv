interface rf_if#(HMC_RF_WWIDTH = 64,
                  HMC_RF_RWIDTH = 64,
                  HMC_RF_AWIDTH = 4)
                 (
                  input clk, 
                  input res_n
                  );

logic  [HMC_RF_AWIDTH-1:0] rf_address;         //output
logic  [HMC_RF_WWIDTH-1:0] rf_write_data;      //output
logic  [HMC_RF_RWIDTH-1:0] rf_read_data;       //input
logic                      rf_access_complete; //input
logic                      rf_invalid_address; //input
logic                      rf_read_enable;     //output
logic                      rf_write_enable;    //output

endinterface : rf_if