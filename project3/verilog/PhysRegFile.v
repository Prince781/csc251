
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
    input [2:0] Read_IN,        // what registers are we reading

    input [`LOG_PHYS - 1 : 0] BusyReg_IN,
    input SetBusy_IN,

    input [`LOG_PHYS - 1 : 0] FreeReg_IN,
    input SetFree_IN,

    output [31:0] RegValueA_OUT,
    output [31:0] RegValueB_OUT,
    output [31:0] RegValueC_OUT,

    output reg [NUM_PHYS_REGS-1:0] Busy_list_OUT,

    output reg [3*`LOG_PHYS - 1 : 0] Free_regs_OUT,
    output reg [2:0] Free_regs_sel_OUT
);
	 
	reg [31:0] PReg [NUM_PHYS_REGS-1:0] /*verilator public*/;
    reg [31:0] RefCounts [NUM_PHYS_REGS-1:0];
    wire [`LOG_PHYS:0] temp;

    assign RegValueA_OUT = PReg[RegAddrA_IN];
    assign RegValueB_OUT = PReg[RegAddrB_IN];
    assign RegValueC_OUT = PReg[RegAddrC_IN];
    always @(negedge CLK or negedge RESET) begin
	    if (!RESET) begin
            temp = 0;
            while (temp < NUM_PHYS_REGS) begin
                PReg[temp[`LOG_PHYS-1:0]] = 0;
                temp = temp + 1;
            end
        end
        if (Write_IN) begin
            PReg[RegWrite_IN] <= DataWrite_IN;
            $display("PhysRegFile: PReg[%d] <= %x (%d)", RegWrite_IN, DataWrite_IN, DataWrite_IN);
        end
        if (SetBusy_IN) begin
            Busy_list_OUT[BusyReg_IN] <= 1;
            $display("PhysRegFile: PReg[%d] set to busy", BusyReg_IN);
        end
        if (SetFree_IN) begin
            Busy_list_OUT[FreeReg_IN] <= 0;
            $display("PhysRegFile: PReg[%d] set to free", FreeReg_IN);
        end
        if (Read_IN != 0) begin
            if (Read_IN & 3'b001) begin
                RefCounts[RegAddrA_IN] <= RefCounts[RegAddrA_IN] + 1;
            end
            if (Read_IN & 3'b010) begin
                RefCounts[RegAddrB_IN] <= RefCounts[RegAddrB_IN] + 1;
            end
            if (Read_IN & 3'b100) begin
                RefCounts[RegAddrB_IN] <= RefCounts[RegAddrB_IN] + 1;
            end
        end
    end

    /* Write Me */
    
endmodule
