class rf_item extends  uvm_sequence_item;


  rand logic  [3:0]   addr;
  rand logic  [63:0]  data;
  rand logic          write_flag;

  // add to factory and implement (print,compare,copy,...)
  `uvm_object_utils_begin(rf_item)
    `uvm_field_int ( addr,      UVM_DEFAULT)
    `uvm_field_int ( data,      UVM_DEFAULT)
    `uvm_field_int ( write_flag, UVM_DEFAULT)
  `uvm_object_utils_end

  // Constraints
  constraint addr_limit_c {
    addr inside { [4'h0 : 4'hC] };
  }

  constraint write_flag_c {
    write_flag inside {1'b0, 1'b1};
  }

  extern function new (string name = "");

endclass : rf_item


function rf_item::new(string name = "");
  super.new(name);
endfunction : new