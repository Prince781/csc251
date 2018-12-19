

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
    output [31:0] RegValueA_OUT,
    output [31:0] RegValueB_OUT,
    output [31:0] RegValueC_OUT,

    );

	PhysRegFile  #(
	.NUM_PHYS_REGS(NUM_PHYS_REGS)
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
        .RegValueA_OUT(RegValueA_OUT),
        .RegValueB_OUT(RegValueB_OUT),
        .RegValueC_OUT(RegValueC_OUT)
    );
    
    /* Write Me */
    
endmodule
