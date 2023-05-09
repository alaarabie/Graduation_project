`ifndef axi_interface_sv
`define axi_interface_sv


interface axi_interface #(parameter t_user_width = 16, parameter t_data_bit = 128)();
	
/////// inf signal

logic					    rst_n;
logic    					clk;

// tx
logic 					    t_ready;
logic   				  	t_valid;
logic [t_data_bit-1 : 0]    t_data;
logic [t_user_width-1 : 0]  t_user;

// rx 
logic   				  	rx_valid;
logic 					    rx_ready;
logic [t_data_bit-1 : 0]    rx_data;
logic [t_user_width-1 : 0]  rx_user;


endinterface : axi_interface

`endif
