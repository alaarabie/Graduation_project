
class axi_seq extends base_seq;

localparam NUM_DATA_BYTES =64;
localparam DWIDTH =512; 

`uvm_object_utils(axi_seq)
`uvm_declare_p_sequencer(axi_sequencer)

int unsigned num_packets = 12;          
   
rand hmc_pkt_item_request hmc_items[]; 
hmc_pkt_item_request hmc_packets_ready[$];
valid_data #(.DWIDTH(DWIDTH),.NUM_DATA_BYTES(NUM_DATA_BYTES)) axi4_queue[$];  
//int working_pos = 0;
      
typedef bit [1+1+1+127:0] valid_tail_header_flit_t;
valid_tail_header_flit_t flit_queue[$];
int tag = 0;
   
constraint tag_value_c {
tag >= 0;
tag <  512;
}


function new(string name="axi_seq");
super.new(name);
endfunction : new


// cerate request in the queue hmc_items
function void starting ();
   hmc_items = new[num_packets];
   foreach (hmc_items[i]) begin
   hmc_items[i] = hmc_pkt_item_request::type_id::create($psprintf("hmc_item[%0d]", i));
   assert(hmc_items[i].randomize());
   //`uvm_info(get_type_name(),$psprintf("%0d HMC packets command", hmc_items[i].command), UVM_MEDIUM)  
   end   
endfunction : starting


// assign tag field to each request packet   
task aquire_tags();
   for (int i = 0; i < hmc_items.size(); i++) 
   begin
      // only register a tag if response required >> all but posted commands
      if    (hmc_items[i].get_command_type() == WRITE_TYPE ||
      hmc_items[i].get_command_type() == MISC_WRITE_TYPE ||
      hmc_items[i].get_command_type() == READ_TYPE       ||
      hmc_items[i].get_command_type() == MODE_READ_TYPE)
      begin
      //p_sequencer.handler.get_tag(tag);
      tag = tag+1;
      end else begin
      tag = 0;
      end
      hmc_items[i].tag = tag;    
      // move packet to ready queue if tag valid
      if (tag >= 0) begin
         `uvm_info(get_type_name(),$psprintf("HMC Packet #%0d command is: %0s tag is: %0d", i, hmc_items[i].command, hmc_items[i].tag), UVM_MEDIUM)
         hmc_packets_ready.push_back(hmc_items[i]);
         //working_pos = i+1;
      end else begin
      break;   //-- send all already processed AXI4 Cycles if tag_handler can not provide an additional tag
      end
   end
endtask : aquire_tags

   
// pack the request packet, and divide the packet to flits
function void pack_hmc_packet(hmc_pkt_item_request pkt);
   bit bitstream[];
   valid_tail_header_flit_t tmp_flit;
   int unsigned bitcount;
   int unsigned packet_count=1;
   bitcount = pkt.pack(bitstream);
   pkt_successfully_packed : assert (bitcount > 0);

   // divide the packet to flits and store them in flit_queue
   // f = flit number
   for (int f=0; f<bitcount/128; f++) begin
      for (int i=0; i< 128; i++)
      tmp_flit[i] = bitstream[f*128+i];
      // check if header
      tmp_flit[128] = (f==0);             
      // check if tail
      tmp_flit[129] = (f==bitcount/128-1);   
      // valid       
      tmp_flit[130] = 1'b1;                        
      flit_queue.push_back(tmp_flit);
   end
endfunction : pack_hmc_packet
   

// assign tuser: header, tail, valid flags, and put flits in axi queue
function void hmc_packet_2_axi_cycles();
   valid_data #(.DWIDTH(DWIDTH),.NUM_DATA_BYTES(NUM_DATA_BYTES)) axi4_item;
            
   int unsigned FPW     = DWIDTH/128; 
   int unsigned HEADERS = 1*FPW;
   int unsigned TAILS   = 2*FPW;
   int unsigned VALIDS  = 0;
         
   int unsigned pkts_in_cycle = 0;     //-- HMC tails in current cycle
   int unsigned header_in_cycle = 0;      //-- HMC headers in current cycle
   int unsigned valids_in_cycle = 0;
   hmc_pkt_item_request hmc_pkt;

   int flit_offset=0;      //-- flit offset: if First flit-> create new axi_item
   valid_tail_header_flit_t current_flit;
   valid_tail_header_flit_t next_flit;

   // create empty valid_data
   //`uvm_create_on(axi4_item, p_sequencer)
   axi4_item=valid_data #(.DWIDTH(DWIDTH),.NUM_DATA_BYTES(NUM_DATA_BYTES))::type_id::create("axi4_item");
   axi4_item.t_data = 0;
   axi4_item.t_user = 0;
   axi4_item.delay = 0;

      
   while (hmc_packets_ready.size() >0 )  
   begin 
      // if there are packets ready, divide them to flits       
      hmc_pkt = hmc_packets_ready.pop_front();  
      pack_hmc_packet(hmc_pkt);
               
      // write flits in flit_queue in axi4_queue
      while( flit_queue.size > 0 ) 
      begin  //-- flit queue contains flits      
         current_flit = flit_queue.pop_front();    
    
         if (current_flit[128])     //-- If current flit is header
         flit_offset += 0;

         // check if axi4_item is full >> push full axi item to axi4_queue
         if (flit_offset == 4)
         begin 
            `uvm_info(get_type_name(),$psprintf("axi4_item is full (offset = %0d), writing element %0d to queue ", flit_offset, axi4_queue.size()), UVM_MEDIUM)
            axi4_queue.push_back(axi4_item);
                           
            //-- create new AXI4 cycle
            //`uvm_create_on(axi4_item, p_sequencer)
            axi4_item=valid_data #(.DWIDTH(DWIDTH),.NUM_DATA_BYTES(NUM_DATA_BYTES))::type_id::create("axi4_item");
            axi4_item.t_data = 0;
            axi4_item.t_user = 0;
            axi4_item.delay = 0;
            /*                           
            //-- set AXI4 cycle delay
            axi4_item.delay = (flit_offset / FPW) -1; //-- flit offset contains also empty flits
            if (flit_offset % FPW >0)
            axi4_item.delay += 3;
             */              
            // reset counter and flit
            `uvm_info(get_type_name(),$psprintf("HMC Packets in last cycle: %0d, %0d", pkts_in_cycle, header_in_cycle), UVM_HIGH)
            pkts_in_cycle  = 0;  //-- reset HMC packet counter in AXI4 Cycle
            header_in_cycle = 0;
            valids_in_cycle = 0;
           // `uvm_info(get_type_name(),$psprintf("axi_delay is %0d", axi4_item.delay), UVM_MEDIUM)
            flit_offset = 0;
         end
     
         //-- write flit to axi4_item
         // t_data
         for (int i =0;i<128;i++) begin
         axi4_item.t_data[(flit_offset*128)+i] = current_flit[i];
         end
                     
         // t_user flags
         //-- write valid
         axi4_item.t_user[VALIDS +flit_offset] = current_flit[130];  //-- valid [fpw-1:0]
         //-- write header
         axi4_item.t_user[HEADERS   +flit_offset] = current_flit[128];  //-- only 1 if header
         //-- write tail
         axi4_item.t_user[TAILS  +flit_offset] = current_flit[129];  //-- only 1 if tail
         valids_in_cycle ++;
                     
                   
         if(current_flit[129])      //-- count tails in current cycle
         pkts_in_cycle ++;

         if(current_flit[128]) begin      //-- count headers in current cycle
         header_in_cycle ++;
         end
                   
         //-- debugging output
         if(current_flit[128]) 
         `uvm_info(get_type_name(),$psprintf("FLIT is header at pos %d", flit_offset), UVM_MEDIUM)
         
         if(current_flit[129]) 
         `uvm_info(get_type_name(),$psprintf("FLIT is tail at pos %d", flit_offset), UVM_MEDIUM)
            
         flit_offset++;
      end
   end
   //-- push last axi4_item to axi4_queue
   `uvm_info(get_type_name(),$psprintf("axi4_item is half-full (offset = %0d), writing element %0d to queue ", flit_offset, axi4_queue.size()), UVM_MEDIUM)
   axi4_queue.push_back(axi4_item);
endfunction : hmc_packet_2_axi_cycles
   

      
task send_axi4_cycles();
   valid_data #(.DWIDTH(DWIDTH),.NUM_DATA_BYTES(NUM_DATA_BYTES)) axi4_item;
   while( axi4_queue.size() > 0 ) begin
      
      `uvm_info(get_type_name(),$psprintf("axi4_queue contains %0d items", axi4_queue.size()), UVM_MEDIUM)
      axi4_item = axi4_queue.pop_front();

/*
      if ((axi4_item.t_user == {{(NUM_DATA_BYTES){1'b0}}})) begin
         axi4_item.print();
         `uvm_fatal("AXI4_Master_Driver", "sent an empty cycle")
      end
*/
      
     // `uvm_send(axi4_item);
     //`uvm_info(get_type_name(),"not me?", UVM_MEDIUM)
      start_item(axi4_item);
      //`uvm_info(get_type_name(),"started correct ?", UVM_MEDIUM)
      finish_item(axi4_item);
      //`uvm_info(get_type_name(),"finished correct ?", UVM_MEDIUM)
   end
endtask : send_axi4_cycles
   
task body();   
repeat (1) begin
   super.body();

   starting(); 
   `uvm_info(get_type_name(),$psprintf("HMC Packets to send: %0d", hmc_items.size()), UVM_MEDIUM)
   aquire_tags();
   // send all packets with tags
   hmc_packet_2_axi_cycles();
   // send axi4_queue
   send_axi4_cycles();
end
endtask : body

endclass : axi_seq


