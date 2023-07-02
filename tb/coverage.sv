class coverage extends uvm_component;
 `uvm_component_utils(coverage)

  // Variables
  bit   [3:0]      length;
  cmd_encoding_e   command;

  `uvm_analysis_imp_decl(_hmc_req)
  uvm_analysis_imp_hmc_req #(hmc_pkt_item, coverage) hmc_req_import;
    
  `uvm_analysis_imp_decl(_hmc_rsp)
  uvm_analysis_imp_hmc_rsp #(hmc_pkt_item, coverage) hmc_rsp_import;
  
  `uvm_analysis_imp_decl(_axi4_req)
  uvm_analysis_imp_axi4_req #(hmc_pkt_item, coverage) axi4_req_import; 
    
  `uvm_analysis_imp_decl(_axi4_rsp)
  uvm_analysis_imp_axi4_rsp #(hmc_pkt_item, coverage) axi4_rsp_import;

  //***********************************************************//
  //*********************** COVERGROUPS ***********************//
  //***********************************************************//
   covergroup command_cg;

    Flow : coverpoint command {
                                  bins flow[]={ NULL,
                                                PRET,
                                                TRET,
                                                IRTRY};}

    Write_Requests : coverpoint command { bins Write_Requests[]={ WR16,
                                                                  WR32,
                                                                  WR48,
                                                                  WR64,
                                                                  WR80,
                                                                  WR96,
                                                                  WR112,
                                                                  WR128};}

    Misc_Write_Requests : coverpoint command { bins Misc_Write_Requests[]={ MD_WR,
                                                                             BWR,
                                                                             DUAL_2ADD8 ,
                                                                             SINGLE_ADD16};}

    Posted_Write_Requests : coverpoint command { bins  Posted_Write_Requests[]={ P_WR16,
                                                                              P_WR32,
                                                                              P_WR48,
                                                                              P_WR64,
                                                                              P_WR80,
                                                                              P_WR96,
                                                                              P_WR112,
                                                                              P_WR128};}

    Posted_Misc_Write_Requests : coverpoint command { bins Posted_Misc_Write_Requests[]={ P_BWR,
                                                                                    P_DUAL_2ADD8,
                                                                                    P_SINGLE_ADD16};}

    Mode_Read_Request : coverpoint command { bins  Mode_Read_Request[]={MD_RD};}

    Read_Requests : coverpoint command { bins  Read_Requests[]={ RD16,
                                                                    RD32,
                                                                    RD48,
                                                                    RD64,
                                                                    RD80,
                                                                    RD96,
                                                                    RD112,
                                                                    RD128};}

    Response_Commands : coverpoint command { bins Response_Commands[]={RD_RS,
                                                                    WR_RS,
                                                                    MD_RD_RS,
                                                                    MD_WR_RS,
                                                                    ERROR_RS };}
  endgroup
    
  covergroup length_cg;
   
   Packet_Length: coverpoint length{
   bins length[]={[1:9] };}
   
 endgroup
   
  //***********************************************************//
  //********************** FUNCTIONS **************************//
  //***********************************************************//
  function new (string name, uvm_component parent);
    super.new(name, parent);
    command_cg = new();
    length_cg = new();

    hmc_req_import = new("hmc_req_import",this);
    hmc_rsp_import = new("hmc_rsp_import",this);
    axi4_req_import = new("axi4_req_import",this);
    axi4_rsp_import = new("axi4_rsp_import",this);
    
  endfunction : new

  function void write_hmc_req(hmc_pkt_item t);
    command=t.command;
    length=t.length;
    
    command_cg.sample();
    length_cg.sample();
    
  endfunction : write_hmc_req

  function void write_hmc_rsp(hmc_pkt_item t);
    command=t.command;
    length=t.length;
    
    command_cg.sample();
    length_cg.sample();
    
  endfunction : write_hmc_rsp

  function void write_axi4_req(hmc_pkt_item t);
    command=t.command;
    length=t.length;
    
    command_cg.sample();
    length_cg.sample();
    
  endfunction : write_axi4_req

  function void write_axi4_rsp(hmc_pkt_item t);
    command=t.command;
    length=t.length;
    
    command_cg.sample();
    length_cg.sample();
    
  endfunction : write_axi4_rsp
  
endclass : coverage