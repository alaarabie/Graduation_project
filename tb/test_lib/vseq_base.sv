class vseq_base extends  uvm_sequence #(uvm_sequence_item);

  `uvm_object_utils(vseq_base)
  `uvm_declare_p_sequencer(vsequencer)

  rf_reg_block rf_rb;

  env_cfg m_cfg;

  // Virtual sequencer handles
  rf_sequencer m_rf_seqr;
  sequencer_hmc_agent m_seqr_hmc_agent ;


  function new(string name = "");
    super.new(name);
  endfunction : new


  virtual task body();
    if(m_cfg == null) begin
       `uvm_fatal(get_full_name(), "env_config is null")
    end
    rf_rb = m_cfg.rf_rb;
    // assign all sequencers to their handle in vsequencer
    m_rf_seqr = p_sequencer.m_rf_seqr;
    m_seqr_hmc_agent=p_sequencer.m_seqr_hmc_agent ;

  endtask : body

endclass : vseq_base