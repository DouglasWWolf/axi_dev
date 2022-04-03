`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2022 07:52:32 PM
// Design Name: 
// Module Name: main
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


module main
(
    input CLK100MHZ,
    input CPU_RESETN,
    input [7:0] SW,
    output [15:0] LED,
    output LED16_R, LED16_B,
    output LED17_R, LED17_G, LED17_B
);
    localparam C_AXI_DATA_WIDTH = 32;
    localparam C_AXI_ADDR_WIDTH = 32;
    
    // "Specify write address"          -- Master --    -- Slave --
    wire [C_AXI_ADDR_WIDTH-1 : 0]       AXI_AWADDR;   
    wire                                AXI_AWVALID;  
    wire                                                AXI_AWREADY;
    wire [2 : 0]                        AXI_AWPROT;

    // "Write Data"                     -- Master --    -- Slave --
    wire [C_AXI_DATA_WIDTH-1 : 0]       AXI_WDATA;      
    wire                                AXI_WVALID;
	wire [(C_AXI_DATA_WIDTH/8)-1 : 0]   AXI_WSTRB;
    wire                                                AXI_WREADY;

    // "Send Write Response"            -- Master --    -- Slave --
    wire [1 : 0]                                        AXI_BRESP;
    wire                                                AXI_BVALID;
    wire                                AXI_BREADY;

    // "Specify read address"           -- Master --    -- Slave --
    wire [C_AXI_ADDR_WIDTH-1 : 0]       AXI_ARADDR;     
    wire                                AXI_ARVALID;
    wire [2 : 0]                        AXI_ARPROT;     
    wire                                                AXI_ARREADY;

    // "Read data back to master"       -- Master --    -- Slave --
    wire [C_AXI_DATA_WIDTH-1 : 0]                       AXI_RDATA;
    wire                                                AXI_RVALID;
    wire [1 : 0]                                        AXI_RRESP;
	wire                                AXI_RREADY;


    slave slave1
    (
        .STATUS_LED(LED[7:0]),
        .SWITCH(SW[7:0]),

        .S_AXI_ACLK(CLK100MHZ),
		.S_AXI_ARESETN(CPU_RESETN),
		.S_AXI_AWADDR(AXI_AWADDR),
		.S_AXI_AWPROT(AXI_AWPROT),
		.S_AXI_AWVALID(AXI_AWVALID), 
		.S_AXI_AWREADY(AXI_AWREADY),
		.S_AXI_WDATA(AXI_WDATA),
        .S_AXI_WSTRB(AXI_WSTRB),
		.S_AXI_WVALID(AXI_WVALID),
		.S_AXI_WREADY(AXI_WREADY),
		.S_AXI_BRESP(AXI_BRESP),
		.S_AXI_BVALID(AXI_BVALID),
		.S_AXI_BREADY(AXI_BREADY),
		.S_AXI_ARADDR(AXI_ARADDR),
		.S_AXI_ARPROT(AXI_ARPROT),
		.S_AXI_ARVALID(AXI_ARVALID),
		.S_AXI_ARREADY(AXI_ARREADY),
		.S_AXI_RDATA(AXI_RDATA),
		.S_AXI_RRESP(AXI_RRESP),
		.S_AXI_RVALID(AXI_RVALID),
		.S_AXI_RREADY(AXI_RREADY)
    );


    // User interface for writing data to the bus
    logic [C_AXI_DATA_WIDTH-1 : 0] bus_wdata;
    logic [C_AXI_ADDR_WIDTH-1 : 0] bus_waddr;
    logic                          bus_write;
    wire                           bus_widle;

    // User interface for reading data from the bus
    wire  [C_AXI_DATA_WIDTH-1 : 0] bus_rdata;
    logic [C_AXI_ADDR_WIDTH-1 : 0] bus_raddr;
    logic                          bus_read;
    wire                           bus_ridle;

    axi4_lite_master master
    (
          //============== The user interface ===============
        .I_WADDR(bus_waddr),
        .I_WDATA(bus_wdata),
        .I_WRITE(bus_write),
        .O_WIDLE(bus_widle),
    
        .I_RADDR(bus_raddr),
        .O_RDATA(bus_rdata),
        .I_READ (bus_read ),
        .O_RIDLE(bus_ridle),
            
        //=== From here down is the AXI4-Lite interface ===
        .M_AXI_ACLK(CLK100MHZ),
		.M_AXI_ARESETN(CPU_RESETN),
		.M_AXI_AWADDR(AXI_AWADDR),
		.M_AXI_AWPROT(AXI_AWPROT),
		.M_AXI_AWVALID(AXI_AWVALID), 
		.M_AXI_AWREADY(AXI_AWREADY),
		.M_AXI_WDATA(AXI_WDATA),
        .M_AXI_WSTRB(AXI_WSTRB),
		.M_AXI_WVALID(AXI_WVALID),
		.M_AXI_WREADY(AXI_WREADY),
		.M_AXI_BRESP(AXI_BRESP),
		.M_AXI_BVALID(AXI_BVALID),
		.M_AXI_BREADY(AXI_BREADY),
		.M_AXI_ARADDR(AXI_ARADDR),
		.M_AXI_ARPROT(AXI_ARPROT),
		.M_AXI_ARVALID(AXI_ARVALID),
		.M_AXI_ARREADY(AXI_ARREADY),
		.M_AXI_RDATA(AXI_RDATA),
		.M_AXI_RRESP(AXI_RRESP),
		.M_AXI_RVALID(AXI_RVALID),
		.M_AXI_RREADY(AXI_RREADY)
    );


    reg led16_r = 0, led16_b = 0;
    reg led17_r=0, led17_g = 0, led17_b = 0;
    assign LED16_R = led16_r;
    assign LED16_B = led16_b;
    assign LED17_R = led17_r;
    assign LED17_B = led17_b;
    assign LED17_G = led17_g;

    localparam s_WAIT_FOR_MS    = 16;
    localparam s_WAIT_FOR_WRITE = 17;
    localparam s_WAIT_FOR_READ  = 18;
    localparam milliseconds = 100000;
    
    logic [4:0] state = 0, next_state;
    logic [31:0] delay;

    //----------------------------------------------------------------        
    // This macro delays a specified number of milliseconds and then
    // advances to the next state
    //----------------------------------------------------------------
    `define delay(ms)                        \
        begin                                \
            delay      <= ms * milliseconds; \
            next_state <= state + 1;         \
            state      <= s_WAIT_FOR_MS;     \
        end            
    //----------------------------------------------------------------

    //----------------------------------------------------------------        
    // This macro writes the specified value to the specified slave
    // address, waits for the write to be acknowledged by the slave,
    // then advances to the next state
    //----------------------------------------------------------------
    `define write(addr, value)                   \
            begin                                \
                bus_waddr  <= addr;              \
                bus_wdata  <= value;             \
                bus_write  <= 1;                 \
                next_state <= state + 1;         \
                state      <= s_WAIT_FOR_WRITE;  \
            end        
    //----------------------------------------------------------------


    //----------------------------------------------------------------        
    // This macro reads from the specified address of the specified 
    // slave, waits for the transaction to complete, then advances
    // to the next state
    //----------------------------------------------------------------
    `define read(addr)                           \
            begin                                \
                bus_raddr  <= addr;              \
                bus_read   <= 1;                 \
                next_state <= state + 1;         \
                state      <= s_WAIT_FOR_READ;   \
            end        
    //----------------------------------------------------------------


    reg [31:0] v0, v1, v2, v3;
        
    wire all_good = (v0 == 32'hF0000000 && v1 == 32'hF1000001 && v2 == 32'hF2000002 && v3 == 32'hF3000003);
    
    always @(posedge CLK100MHZ) begin
        if (CPU_RESETN == 0) begin
            state     <= 0;
            led16_r   <= 0;
            led16_b   <= 0;
            led17_b   <= 0; 
            led17_g   <= 0;
            led17_r   <= 0;
            bus_write <= 0;
            v0 <= 32'h00AAAAFE;
            v1 <= 32'h01AAAAFE;
            v2 <= 32'h02AAAAFE;
            v3 <= 32'h03AAAAFE;

        end else case (state)
            
            0: `delay(100)

            1:  begin
                    led16_b <= 1;
                    `write(0 * 4, 32'hF00000FF);
                end
            2:  `write(0 * 4, 32'hF0000000)  
            3:  `write(1 * 4, 32'hF1000001)
            4:  `write(2 * 4, 32'hF2000002)
            5:  `write(3 * 4, 32'hF3000003)
            6:  `read(0 * 4)
            
            7:  begin
                    v0 <= bus_rdata;
                    `read(1 * 4);
                end

            8:  begin
                    v1 <= bus_rdata;
                    `read(2 * 4);
                end

            9:  begin
                    v2 <= bus_rdata;
                    `read(3 * 4);
                end

           10:  begin
                    v3 <= bus_rdata;
                    state = state + 1;
                end
               
           11:  begin
                    led17_g <= all_good;
                    led17_r <= !all_good;
                end
            
            s_WAIT_FOR_MS:
                begin
                    if (delay == 0)
                        state <= next_state;
                    else
                        delay <= delay - 1;
                end
                
            s_WAIT_FOR_WRITE:
                begin
                    bus_write <= 0;
                    if (bus_write == 0 && bus_widle == 1) state <= next_state;
                end
 
            s_WAIT_FOR_READ:
                begin
                    bus_read <= 0;
                    if (bus_read == 0 && bus_ridle == 1) state <= next_state;
                end
            default:
                state <= state + 1;
        endcase
    
    end
    

    reg [7:0] status_led;
    assign LED[15:8] = status_led;
                
    always @(*) begin
        case (SW[3:0])
             0:  status_led = v0[31:24];
             1:  status_led = v0[23:16];
             2:  status_led = v0[15: 8];
             3:  status_led = v0[7 : 0];

             4:  status_led = v1[31:24];
             5:  status_led = v1[23:16];
             6:  status_led = v1[15: 8];
             7:  status_led = v1[7 : 0];

             8:  status_led = v2[31:24];
             9:  status_led = v2[23:16];
            10:  status_led = v2[15: 8];
            11:  status_led = v2[7 : 0];
            
            12:  status_led = v3[31:24];
            13:  status_led = v3[23:16];
            14:  status_led = v3[15: 8];
            15:  status_led = v3[7 : 0];
       endcase
    end
        
    

endmodule
