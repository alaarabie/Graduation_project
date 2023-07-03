class axi_write_seq extends  axi_base_seq;

  `uvm_object_utils(axi_write_seq)


  constraint req_class_c {
    req_class inside {WRITE, MISC};
  }

  function new(string name = "");
    super.new(name);
  endfunction : new


endclass : axi_write_seq