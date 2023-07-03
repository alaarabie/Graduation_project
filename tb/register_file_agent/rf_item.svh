class rf_item extends  uvm_sequence_item;

`uvm_object_utils(rf_item)

  rand logic  [3:0]   addr;
  rand logic  [63:0]  data;
  rand logic          write_flag;

  // Constraints
  constraint addr_limit_c {
    addr inside { [4'h0 : 4'hC] };
  }

  constraint write_flag_c {
    write_flag inside {1'b0, 1'b1};
  }

extern function new(string name = "");
extern function void do_copy(uvm_object rhs);
extern function bit do_compare(uvm_object rhs, uvm_comparer comparer);
extern function string convert2string();
extern function void do_print(uvm_printer printer);

endclass : rf_item


function rf_item::new(string name = "");
  super.new(name);
endfunction : new

function void rf_item::do_copy(uvm_object rhs);
  rf_item rhs_;

  if(!$cast(rhs_, rhs)) begin
    `uvm_fatal("do_copy", "cast of rhs object failed")
  end
  super.do_copy(rhs);
  // Copy over data members:
  addr = rhs_.addr;
  data = rhs_.data;
  write_flag = rhs_.write_flag;

endfunction:do_copy

function bit rf_item::do_compare(uvm_object rhs, uvm_comparer comparer);
  rf_item rhs_;

  if(!$cast(rhs_, rhs)) begin
    `uvm_error("do_copy", "cast of rhs object failed")
    return 0;
  end
  return super.do_compare(rhs, comparer) &&
         addr == rhs_.addr &&
         data == rhs_.data &&
         write_flag   == rhs_.data;
endfunction:do_compare

function string rf_item::convert2string();
  string s;

  $sformat(s, "%s\n", super.convert2string());
  // Convert to string function reusing s:
  $sformat(s, "%saddr\t%0h\n data\t%0h\n write_flag\t%0b\n", s, addr, data, write_flag);
  return s;

endfunction:convert2string

function void rf_item::do_print(uvm_printer printer);
  printer.m_string = convert2string();
endfunction:do_print