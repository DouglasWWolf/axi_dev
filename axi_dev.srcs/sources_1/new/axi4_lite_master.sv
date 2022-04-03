`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2022 09:14:58 PM
// Design Name: 
// Module Name: axi4_lite_master
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi4_lite_master#
(
    parameter integer C_AXI_DATA_WIDTH	= 32,
	parameter integer C_AXI_ADDR_WIDTH	= 32
)
(
    
    //====================== The user interface for writing ====================
    input  wire [C_AXI_ADDR_WIDTH-1:0] I_WADDR,
    input  wire [C_AXI_DATA_WIDTH-1:0] I_WDATA,
    input  wire                        I_WRITE,
    output wire                        O_WIDLE,
    //==========================================================================
    
    //====================== The user interface for reading ====================
    input  wire [C_AXI_ADDR_WIDTH-1:0] I_RADDR,
    output wire [C_AXI_DATA_WIDTH-1:0] O_RDATA,
    input  wire                        I_READ,
    output wire                        O_RIDLE,
    //==========================================================================

    //================ From here down is the AXI4-Lite interface ===============
    input wire  M_AXI_ACLK,
    input wire  M_AXI_ARESETN,
        
    // "Specify write address"              -- Master --    -- Slave --
    output wire [C_AXI_ADDR_WIDTH-1 : 0]    M_AXI_AWADDR,   
    output wire                             M_AXI_AWVALID,  
    input  wire                                             M_AXI_AWREADY,
    output wire  [2 : 0]                    M_AXI_AWPROT,

    // "Write Data"                         -- Master --    -- Slave --
    output wire [C_AXI_DATA_WIDTH-1 : 0]    M_AXI_WDATA,      
    output wire                             M_AXI_WVALID,
	output wire [(C_AXI_DATA_WIDTH/8)-1 : 0]M_AXI_WSTRB,
    input  wire                                             M_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    input  wire [1 : 0]                                     M_AXI_BRESP,
    input  wire                                             M_AXI_BVALID,
    output wire                             M_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    output wire [C_AXI_ADDR_WIDTH-1 : 0]    M_AXI_ARADDR,     
    output wire                             M_AXI_ARVALID,
    output wire [2 : 0]                     M_AXI_ARPROT,     
    input  wire                                             M_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    input  wire [C_AXI_DATA_WIDTH-1 : 0]                    M_AXI_RDATA,
    input  wire                                             M_AXI_RVALID,
    input  wire [1 : 0]                                     M_AXI_RRESP,
	output wire                             M_AXI_RREADY
	//==========================================================================

);

    localparam C_AXI_DATA_BYTES = (C_AXI_DATA_WIDTH/8);

    // Registers used to drive output ports during a "Write to slave"
    logic                           m_axi_wvalid;
    logic                           m_axi_awvalid;
    logic [C_AXI_DATA_BYTES-1 : 0 ] m_axi_wstrb = (1 << C_AXI_DATA_BYTES) - 1; // Never changes
    logic                           m_axi_bready;
    logic [C_AXI_ADDR_WIDTH-1 : 0]  i_waddr;
    logic [C_AXI_DATA_WIDTH-1 : 0]  i_wdata;

    // Registers used to drive outpout ports during "Read from slave"
    logic                           m_axi_arvalid;
    logic                           m_axi_rready;
    logic [C_AXI_DATA_WIDTH-1 : 0]  m_axi_rdata;

    // This goes high when a write is complete
    (* mark_debug = "true" *) logic                           o_widle = 1; 

    
    // This goes high when a read is complete
    logic                           o_ridle = 1;   
 
    // Assignment of ports used for a "write" transaction
    assign M_AXI_AWADDR  = i_waddr;
    assign M_AXI_AWVALID = m_axi_awvalid;
    assign M_AXI_AWPROT  = 3'b000;
    assign M_AXI_WDATA   = i_wdata;
    assign M_AXI_WVALID  = m_axi_wvalid;
    assign M_AXI_WSTRB   = m_axi_wstrb;
    assign M_AXI_BREADY  = m_axi_bready;
    assign O_WIDLE       = o_widle;
    
    // Assignment of ports used for a "read" transaction
    
    assign O_RDATA       = m_axi_rdata;
    assign M_AXI_ARVALID = m_axi_arvalid;
    assign M_AXI_ARPROT  = 3'b001;
    assign M_AXI_ARADDR  = I_RADDR;
    assign M_AXI_RREADY  = m_axi_rready;
    assign O_RIDLE       = o_ridle;
    
   

    // A write-from-master-to-save transaction begins on an I_WRITE pulse when o_widle is high (i.e., we're idle)
    wire start_write_transaction = I_WRITE & o_widle;  
    
    // A "read-from-slave_to_master" transaction begins on an I_READ pulse when o_ridle is high 
    wire start_read_transaction = I_READ & o_ridle; 
  
    //=========================================================================================================
    // Logic used for writing to the slave device
    //=========================================================================================================

 	
    /*
        The "write to slave" engine goes active when I_WRITE is pulsed, and returns to idle when
        the slave device asserts AXI_BVALID
    */
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0)
            o_widle <= 1;
        else if (start_write_transaction)
            o_widle <= 0;
        else if (M_AXI_BVALID && M_AXI_BREADY)
            o_widle <= 1;
        else 
            o_widle <= o_widle;
    end

 
 
    /*
        We raise AXI_AWVALID to indicate that there is a valid write-address on the bus.  The AXI spec
        says that once we raise it, we must keep it raised until both the data and address are valid
        and the slave has acknowledged them
    */
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0)
            m_axi_awvalid <= 0;
        else if (start_write_transaction) begin
            i_waddr <= I_WADDR;
            m_axi_awvalid <= 1;
        end else if (m_axi_wvalid && M_AXI_WREADY  && m_axi_awvalid && M_AXI_AWREADY)
            m_axi_awvalid <= 0;            
    end


    /*
        We raise AXI_WVALID to indicate that there is valid write-data on the bus.  The AXI spec
        says that once we raise it, we must keep it raised until both the data and address are valid
        and the slave has acknowledged them
    */
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0) begin
            m_axi_wvalid <= 0;
        end else if (start_write_transaction) begin
            i_wdata <= I_WDATA;
            m_axi_wvalid <= 1;
        end else if (m_axi_wvalid && M_AXI_WREADY  && m_axi_awvalid && M_AXI_AWREADY)
            m_axi_wvalid <= 0;            
    end


    /*
        When the slave asserts AXI_BVALID in order to send us status information from the write, 
        we acknowledge it by raisiung AXI_BREADY for one cycle
    */
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0)
            m_axi_bready <= 0;
        else if (M_AXI_BVALID && ~m_axi_bready)
            m_axi_bready <= 1;
        else if (m_axi_bready) 
            m_axi_bready <= 0;
    end
    
  

    //=========================================================================================================
    // End of logic for writing to the slave device
    //=========================================================================================================



     
  
    //=========================================================================================================
    // Logic used for reading from the slave device
    //=========================================================================================================


    /*
        We raise AXI_ARVALID to indicate that there is valid read-address.  The AXI spec
        says that once we raise it, we must keep it raised until the slave asserts AXI_ARREADY
    */
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0) 
            m_axi_arvalid <= 0;
        else if (start_read_transaction)
            m_axi_arvalid <= 1;
        else if (M_AXI_ARREADY && m_axi_arvalid)
            m_axi_arvalid <= 0;
    end


    /*
        Once the slave raises AXI_RAVLID (to indicate that we now have valid data in AXI_RDATA),
        we acknowledge by raising AXI_RREADY for once clock cycle
    */
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0)
            m_axi_rready <= 0;
        else if (M_AXI_RVALID && ~m_axi_rready) begin 
            m_axi_rdata  <= M_AXI_RDATA;
            m_axi_rready <= 1;
        end else if (m_axi_rready)
            m_axi_rready <= 0;
    end
        
        
    /*
        The "read from slave" engine goes active when I_READ is pulsed, and returns to idle when
        the slave device asserts AXI_RVALID
    */
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0)
            o_ridle <= 1;
        else if (start_read_transaction)
            o_ridle <= 0; 
        else if (M_AXI_RVALID && ~m_axi_rready)
            o_ridle <= 1;
    end



    //=========================================================================================================
    // End of logic for reading from the slave device
    //=========================================================================================================




endmodule