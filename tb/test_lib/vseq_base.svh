class vseq_base extends  uvm_sequence #(uvm_sequence_item);

  `uvm_object_utils(vseq_base)
  `uvm_declare_p_sequencer(vsequencer)

  rf_reg_block rf_rb;

  env_cfg m_cfg;

  // Virtual sequencer handles
  rf_sequencer m_rf_seqr;
  hmc_agent_sequencer m_hmc_sqr ;
  axi_sequencer_t m_axi_sqr;

  virtual system_if sys_if;

  function new(string name = "");
    super.new(name);
  endfunction : new


  virtual task body();
    m_cfg = p_sequencer.cfg ;
    if(m_cfg == null) begin
       `uvm_fatal(get_full_name(), "env_config is null")
    end
    rf_rb = m_cfg.rf_rb;
    // assign all sequencers to their handle in vsequencer
    m_rf_seqr = p_sequencer.m_rf_seqr;
    m_hmc_sqr=p_sequencer.m_hmc_sqr ;
    m_axi_sqr=p_sequencer.m_axi_sqr ;

  endtask : body

  function void seq_set_cfg(base_seq seq_);
    seq_.m_cfg = m_cfg;
    seq_.sys_if = sys_if;
  endfunction


endclass : vseq_base
