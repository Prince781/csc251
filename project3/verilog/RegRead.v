`include "config.v"

`define LOG_PHYS    $clog2(NUM_PHYS_REGS)

module RegRead#(
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
    input [0:0] Write_IN, // 0 = don't write, 1 = write

    input [`LOG_PHYS - 1 : 0] BusyReg_IN,
    input SetBusy_IN,
    input BusyValue_IN,

    output [31:0] RegValueA_OUT,
    output [31:0] RegValueB_OUT,
    output [31:0] RegValueC_OUT,

    output reg [NUM_PHYS_REGS-1:0] Busy_list_OUT
);

	PhysRegFile  #(
	.NUM_PHYS_REGS(`PROJ_NUM_PHYS_REGS)
	)
	PhysRegFile(
        .CLK(CLK),
        .RESET(RESET),
        .RegAddrA_IN(RegAddrA_IN),
        .RegAddrB_IN(RegAddrB_IN),
        .RegAddrC_IN(RegAddrC_IN),
        .RegWrite_IN(RegWrite_IN),
        .DataWrite_IN(DataWrite_IN),
        .Write_IN(Write_IN),
        .BusyReg_IN(BusyReg_IN),
        .SetBusy_IN(SetBusy_IN),
        .BusyValue_IN(BusyValue_IN),
        .RegValueA_OUT(RegValueA_OUT),
        .RegValueB_OUT(RegValueB_OUT),
        .RegValueC_OUT(RegValueC_OUT),
        .Busy_list_OUT(Busy_list_OUT)
    );
    
    /* Write Me */
    
endmodule
