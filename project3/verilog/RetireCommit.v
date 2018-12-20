/**************************************
* Module: RetireCommit
* Date:2013-12-10  
* Author: isaac     
*
* Description: Handles commits to the ROB, and retires instructions from the ROB.
*
* This is the last stop of this train. All passengers must exit.
***************************************/
`define LOG_PHYS    $clog2(NUM_PHYS_REGS)
`define LOG_ARCH    $clog2(NUM_ARCH_REGS)
module  RetireCommit #(
    parameter NUM_PHYS_REGS = 64,
    parameter NUM_ARCH_REGS = 35
)
(
    input CLK,
    input RESET,

    input [`LOG_ARCH-1:0] Arch_reg_IN,
    input [`LOG_PHYS-1:0] Phys_reg_IN,

    input Update_IN,                        // whether to actually perform the update

    output Flush_OUT,
    output reg [`LOG_PHYS-1:0] RegPtrs_OUT [NUM_ARCH_REGS-1:0]
);/*verilator public_module*/

assign Flush_OUT = 1'b0;    // TODO

RAT #(
    .NUM_ARCH_REGS(35),
    .NUM_PHYS_REGS(NUM_PHYS_REGS)
    /* Maybe Others? */
)RRAT(
    .RESET(RESET),
    .Register_update_src(Arch_reg_IN),
    .Register_update_dst(Phys_reg_IN),
    .Write(Update_IN),
    .RegPtrs(RegPtrs_OUT)
);

endmodule

