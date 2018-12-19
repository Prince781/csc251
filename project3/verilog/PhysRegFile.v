`include "config.v"
`define LOG_PHYS    $clog2(NUM_PHYS_REGS)

module PhysRegFile (
    input CLK,
    input RESET,
    input [`LOG_PHYS - 1 : 0] RegAddrA_IN,
    input [`LOG_PHYS - 1 : 0] RegAddrB_IN,
    input [`LOG_PHYS - 1 : 0] RegAddrC_IN,
    input [`LOG_PHYS - 1 : 0] RegWrite_IN,
    input [31:0] DataWrite_IN,
    input [0:0] Write_IN, // 0 = don't write, 1 = write
    output [31:0] RegValueA_OUT,
    output [31:0] RegValueB_OUT,
    output [31:0] RegValueC_OUT,
    );
	 
	reg [31:0] PReg [NUM_PHYS_REGS-1:0] /*verilator public*/;
    wire temp;

    assign RegValueA_OUT = PReg[RegAddrA_IN];
    assign RegValueB_OUT = PReg[RegAddrB_IN];
    assign RegValueC_OUT = PReg[RegAddrC_IN];
    always @(posedge CLK or negedge RESET) begin
	    if (!RESET) begin
            temp = 0;
            while (temp < NUM_PHYS_REGS) begin
                PReg[temp] = 0;
                temp = temp + 1;
            end
        end
        if (Write_IN) begin
            assign PReg[RegWrite_IN] = DataWrite_IN;
        end
    end

    /* Write Me */
    
endmodule
