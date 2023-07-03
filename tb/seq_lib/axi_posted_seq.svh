class axi_posted_seq extends  axi_base_seq;

  `uvm_object_utils(axi_posted_seq)


  constraint req_class_c {
    req_class inside {POSTED};
  }

  function new(string name = "");
    super.new(name);
  endfunction : new


endclass : axi_posted_seq