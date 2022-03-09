`ifndef PULPINO_SPI_MASTER_SUBSYSTEM_ENV_INCLUDED_
`define PULPINO_SPI_MASTER_SUBSYSTEM_ENV_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: pulpino_spi_master_subsystem_env
// Creates master agent and slave agent and scoreboard
//--------------------------------------------------------------------------------------------
class pulpino_spi_master_subsystem_env extends uvm_env;
  `uvm_component_utils(pulpino_spi_master_subsystem_env)

  //Variable : axi4_master_agent_h
  //Declaring axi4 master agent handle
  axi4_master_agent axi4_master_agent_h;

  //Variable : spi_slave_agent_h
  //Declaring spi slave agent handle
  spi_slave_agent spi_slave_agent_h[];

  //Variable : axi4__scoreboard_h
  //Declaring pulpino_spi_master_subsystem scoreboard handle
  pulpino_spi_master_subsystem_scoreboard pulpino_spi_master_subsystem_scoreboard_h;

  //Variable : pulpino_spi_master_subsystem_virtual_seqr_h
  //Declaring axi4 virtual seqr handle
  pulpino_spi_master_subsystem_virtual_sequencer pulpino_spi_master_subsystem_virtual_seqr_h;
  
  //Variable : pulpino_spi_master_subsystem_env_config_h
  //Declaring handle for pulpino_spi_master_subsystem_env_config_object
  pulpino_spi_master_subsystem_env_config pulpino_spi_master_subsystem_env_config_h;  
  
  // Variable: axi4_master_coll_h;
  // Handle for axi4 master collector
  axi4_master_collector axi4_master_coll_h;

  // Variable: spi_slave_coll_h;
  // Handle for spi slave collector
  spi_slave_collector spi_slave_coll_h;

  // Variable: axi4_reg_predictor_h
  // Handle for axi4_reg_predictor#(axi4_master_tx)
  typedef axi4_reg_predictor#(axi4_master_tx) axi4_reg_predictor_t;
  axi4_reg_predictor_t axi4_reg_predictor_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "pulpino_spi_master_subsystem_env", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : pulpino_spi_master_subsystem_env

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - pulpino_spi_master_subsystem_env
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function pulpino_spi_master_subsystem_env::new(string name = "pulpino_spi_master_subsystem_env",uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Builds the master and slave agents and scoreboard
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void pulpino_spi_master_subsystem_env::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(!uvm_config_db #(pulpino_spi_master_subsystem_env_config)::get(this,"","pulpino_spi_master_subsystem_env_config",
                                                                    pulpino_spi_master_subsystem_env_config_h)) begin
   `uvm_fatal("FATAL_ENV_CONFIG", $sformatf("Couldn't get the env_config from config_db"))
  end
  
  axi4_master_agent_h = axi4_master_agent::type_id::create("axi4_master_agent",this);
  
  spi_slave_agent_h = new[pulpino_spi_master_subsystem_env_config_h.no_of_spi_slaves];
  foreach(spi_slave_agent_h[i]) begin
    spi_slave_agent_h[i] = spi_slave_agent::type_id::create($sformatf("spi_slave_agent_h[%0d]",i),this);
  end

  if(pulpino_spi_master_subsystem_env_config_h.has_virtual_seqr) begin
    pulpino_spi_master_subsystem_virtual_seqr_h = pulpino_spi_master_subsystem_virtual_sequencer::type_id::
                                                  create("pulpino_spi_master_subsystem_virtual_seqr_h",this);
  end

  if(pulpino_spi_master_subsystem_env_config_h.has_scoreboard) begin
    pulpino_spi_master_subsystem_scoreboard_h = pulpino_spi_master_subsystem_scoreboard::type_id::
                                                create("pulpino_spi_master_subsystem_scoreboard_h",this);
  end

  axi4_master_coll_h = axi4_master_collector::type_id::create("axi4_master_coll_h",this);
  spi_slave_coll_h   = spi_slave_collector::type_id::create("spi_slave_coll_h",this);
  axi4_reg_predictor_h = axi4_reg_predictor_t::type_id::create("axi4_reg_predictor_h", this);

endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
// Connects the master agent monitor's analysis_port with scoreboard's analysis_fifo 
// Connects the slave agent monitor's analysis_port with scoreboard's analysis_fifo 
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void pulpino_spi_master_subsystem_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  if(pulpino_spi_master_subsystem_env_config_h.has_virtual_seqr) begin
    pulpino_spi_master_subsystem_virtual_seqr_h.axi4_master_write_seqr_h = axi4_master_agent_h.axi4_master_write_seqr_h;
    pulpino_spi_master_subsystem_virtual_seqr_h.axi4_master_read_seqr_h = axi4_master_agent_h.axi4_master_read_seqr_h;
    foreach(spi_slave_agent_h[i]) begin
      pulpino_spi_master_subsystem_virtual_seqr_h.spi_slave_seqr_h = spi_slave_agent_h[i].spi_slave_seqr_h;
    end
    pulpino_spi_master_subsystem_virtual_seqr_h.env_config_h = pulpino_spi_master_subsystem_env_config_h; 
  end
  
  axi4_master_agent_h.axi4_master_mon_proxy_h.axi4_master_read_address_analysis_port.connect
                                              (axi4_master_coll_h.axi4_master_coll_imp_port);
  //axi4_master_agent_h.axi4_master_mon_proxy_h.axi4_master_read_data_analysis_port.connect
  //                                            (axi4_master_coll_h.axi4_master_coll_imp_port);
  axi4_master_agent_h.axi4_master_mon_proxy_h.axi4_master_write_address_analysis_port.connect
                                              (axi4_master_coll_h.axi4_master_coll_imp_port);
  //axi4_master_agent_h.axi4_master_mon_proxy_h.axi4_master_write_data_analysis_port.connect
  //                                            (axi4_master_coll_h.axi4_master_coll_imp_port);
  //axi4_master_agent_h.axi4_master_mon_proxy_h.axi4_master_write_response_analysis_port.connect
  //                                            (axi4_master_coll_h.axi4_master_coll_imp_port);
  foreach(spi_slave_agent_h[i]) begin
    spi_slave_agent_h[i].spi_slave_mon_proxy_h.spi_slave_analysis_port.connect(spi_slave_coll_h.spi_slave_coll_imp_port);
  end

  axi4_master_coll_h.axi4_master_write_address_coll_analysis_port.connect(pulpino_spi_master_subsystem_scoreboard_h
                                                                 .axi4_master_write_address_analysis_fifo.analysis_export);
  //axi4_master_coll_h.axi4_master_write_data_coll_analysis_port.connect(pulpino_spi_master_subsystem_scoreboard_h
  //                                                            .axi4_master_write_data_analysis_fifo.analysis_export);
  //axi4_master_coll_h.axi4_master_write_response_coll_analysis_port.connect(pulpino_spi_master_subsystem_scoreboard_h
  //                                                                .axi4_master_write_response_analysis_fifo.analysis_export);
  axi4_master_coll_h.axi4_master_read_address_coll_analysis_port.connect(pulpino_spi_master_subsystem_scoreboard_h
                                                                .axi4_master_read_address_analysis_fifo.analysis_export);
  //axi4_master_coll_h.axi4_master_read_data_coll_analysis_port.connect(pulpino_spi_master_subsystem_scoreboard_h
  //                                                           .axi4_master_read_data_analysis_fifo.analysis_export);
  spi_slave_coll_h.spi_slave_coll_analysis_port.connect(pulpino_spi_master_subsystem_scoreboard_h
                                               .spi_slave_analysis_fifo.analysis_export);

  // RAL connections
  if ( pulpino_spi_master_subsystem_env_config_h.spi_master_reg_block.get_parent() == null ) begin // if the top-level env
     pulpino_spi_master_subsystem_env_config_h.spi_master_reg_block.default_map.set_sequencer( 
                                                  .sequencer( axi4_master_agent_h.axi4_master_write_seqr_h ),
                                                  .adapter( axi4_master_agent_h.axi4_reg_adapter_h ) );
  end
  
  pulpino_spi_master_subsystem_env_config_h.spi_master_reg_block.default_map.set_auto_predict( .on( 0 ) );

  axi4_master_coll_h.map       = pulpino_spi_master_subsystem_env_config_h.spi_master_reg_block.default_map;
  axi4_reg_predictor_h.map     = pulpino_spi_master_subsystem_env_config_h.spi_master_reg_block.default_map;
  axi4_reg_predictor_h.adapter = axi4_master_agent_h.axi4_reg_adapter_h;
  
  axi4_master_agent_h.axi4_master_mon_proxy_h.axi4_master_read_address_analysis_port.connect( axi4_reg_predictor_h.bus_in);
  //axi4_master_agent_h.axi4_master_mon_proxy_h.axi4_master_read_data_analysis_port.connect( axi4_reg_predictor_h.bus_in);
  axi4_master_agent_h.axi4_master_mon_proxy_h.axi4_master_write_address_analysis_port.connect( axi4_reg_predictor_h.bus_in);
  //axi4_master_agent_h.axi4_master_mon_proxy_h.axi4_master_write_data_analysis_port.connect( axi4_reg_predictor_h.bus_in);
  //axi4_master_agent_h.axi4_master_mon_proxy_h.axi4_master_write_response_analysis_port.connect( axi4_reg_predictor_h.bus_in);
  
  endfunction : connect_phase

`endif

