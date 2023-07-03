class axi_read_seq extends  axi_base_seq;

  `uvm_object_utils(axi_read_seq)


  constraint req_class_c {
    req_class inside {READ, MODE_READ};
  }

  function new(string name = "");
    super.new(name);
  endfunction : new


endclass : axi_read_seq