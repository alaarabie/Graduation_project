
interface axi_interface #(NUM_DATA_BYTES = 64, DWIDTH = 512)
					   (
	                    input clk, 
                  		input res_n);
	
/////// inf signal

// tx
logic 					      t_ready;
logic   				  	  t_valid;
logic [DWIDTH-1 : 0]          t_data;
logic [NUM_DATA_BYTES-1 : 0]  t_user;

// rx 
logic         				  rx_valid;
logic 					      rx_ready;
logic [DWIDTH-1 : 0]          rx_data;
logic [NUM_DATA_BYTES-1 : 0]  rx_user;


endinterface : axi_interface
