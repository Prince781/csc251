
`define LOG_PHYS $clog2(NUM_PHYS_REGS)

module PhysRegFile #(
    parameter NUM_PHYS_REGS = 64
)
(
    input CLK,
    input RESET,

    input [`LOG_PHYS - 1 : 0] RegAddrA_IN,
    input [`LOG_PHYS - 1 : 0] RegAddrB_IN,
    input [`LOG_PHYS - 1 : 0] RegAddrC_IN,
    input [`LOG_PHYS - 1 : 0] RegWrite_IN,
    input [31:0] DataWrite_IN,
    input Write_IN,                                     // 0 = don't write, 1 = write

    input [`LOG_PHYS - 1 : 0] BusyReg_IN,
    input SetBusy_IN,
    input BusyValue_IN,

    output [31:0] RegValueA_OUT,
    output [31:0] RegValueB_OUT,
    output [31:0] RegValueC_OUT,

    output reg [NUM_PHYS_REGS-1:0] Busy_list_OUT
);
	 
	reg [31:0] PReg [NUM_PHYS_REGS-1:0] /*verilator public*/;
    wire [`LOG_PHYS:0] temp;

    assign RegValueA_OUT = PReg[RegAddrA_IN];
    assign RegValueB_OUT = PReg[RegAddrB_IN];
    assign RegValueC_OUT = PReg[RegAddrC_IN];
    always @(posedge CLK or negedge RESET) begin
	    if (!RESET) begin
            temp = 0;
            while (temp < NUM_PHYS_REGS) begin
                PReg[temp[`LOG_PHYS-1:0]] = 0;
                temp = temp + 1;
            end
        end
        if (Write_IN) begin
            PReg[RegWrite_IN] <= DataWrite_IN;
        end
        if (SetBusy_IN) begin
            Busy_list_OUT[BusyReg_IN] <= BusyValue_IN;
        end
    end

    /* Write Me */
    
endmodule
