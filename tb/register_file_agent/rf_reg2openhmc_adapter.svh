class rf_reg2openhmc_adapter extends  uvm_reg_adapter;
  
  `uvm_object_utils(rf_reg2openhmc_adapter)

  function new(string name = "");
    super.new(name);
    // Does the protocol the Agent is modeling support byte enables?
    // 0 = NO
    // 1 = YES
    supports_byte_enable = 0;
    // Does the Agent's Driver provide separate response sequence items?
    // i.e. Does the driver call seq_item_port.put()
    // and do the sequences call get_response()?
    // 0 = NO
    // 1 = YES
    provides_responses = 0;
  endfunction : new

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);

    rf_item   trans_h = rf_item::type_id::create("trans_h");

    trans_h.write_flag = (rw.kind == UVM_READ) ? 1'b0 : 1'b1 ;
    trans_h.addr       = rw.addr;
    trans_h.data       = rw.data;
    `uvm_info("REG2HMC_ADAPTER", $psprintf("\n(reg2bus): %s to addr: %h with Payload: %h \n", rw.kind.name(), rw.addr, rw.data),UVM_HIGH);
    return trans_h;

  endfunction : reg2bus


  virtual function void bus2reg(uvm_sequence_item bus_item,
                                ref uvm_reg_bus_op rw);

    rf_item   trans_h;
    string    item_str;
    if(!$cast(trans_h, bus_item)) begin
      `uvm_fatal("NOT_BUS_TYPE","Provided bus_item is not of the correct type")
      return;
    end
    item_str = trans_h.convert2string();
    rw.kind   = (trans_h.write_flag == 1'b1) ? UVM_WRITE : UVM_READ;
    rw.addr   = trans_h.addr;
    rw.data   = trans_h.data;
    rw.status = UVM_IS_OK;
    `uvm_info("REG2HMC_ADAPTER", $psprintf("\n(bus2reg): %s to addr: %h with Payload: %h \n", rw.kind.name(), rw.addr, rw.data),UVM_HIGH);
  endfunction : bus2reg

endclass : rf_reg2openhmc_adapter