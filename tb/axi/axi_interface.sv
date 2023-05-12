
interface axi_interface #(parameter T_USER_WIDTH = 16, parameter T_DATA_BIT = 128)();
	
/////// inf signal

logic					    rst_n;
logic    					clk;

// tx
logic 					    t_ready;
logic   				  	t_valid;
logic [T_DATA_BIT-1 : 0]    t_data;
logic [T_USER_WIDTH-1 : 0]  t_user;

// rx 
logic   				  	rx_valid;
logic 					    rx_ready;
logic [T_DATA_BIT-1 : 0]    rx_data;
logic [T_USER_WIDTH-1 : 0]  rx_user;


endinterface : axi_interface
