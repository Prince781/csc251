/**************************************
* Module: RetireCommit
* Date:2013-12-10
* Author: isaac
*
* Description: Handles commits to the ROB, and retires instructions from the ROB.
*
* This is the last stop of this train. All passengers must exit.
***************************************/
`include "config.v"

`define LOG_PHYS    $clog2(NUM_PHYS_REGS)
`define LOG_ARCH    $clog2(NUM_ARCH_REGS)
module  RetireCommit #(
    parameter NUM_PHYS_REGS = 64,
    parameter NUM_ARCH_REGS = 35,
    parameter ROB_ENTRY_BITS = `ROB_ENTRY_BITS
)
(
    input CLK,
    input RESET,

    input [ROB_ENTRY_BITS-1:0] ROB_entry_IN,
    input ROB_entry_valid_IN,

    input Update_ROB_IN,
    input [5:0] Update_entry_IN,

    output [5:0] ROB_free_entry_OUT,
    output ROB_full_OUT,

    output Flush_OUT,
    output reg [`LOG_PHYS-1:0] RegPtrs_OUT [NUM_ARCH_REGS-1:0],

    output ROB_free_reg_OUT,
    output [`LOG_PHYS-1:0] ROB_phys_reg_OUT
);/*verilator public_module*/

wire update_ROB_RRAT;
wire ROB_full;

wire [`LOG_PHYS-1:0] Phys_reg;
wire [`LOG_ARCH-1:0] Arch_reg;

wire reg_update;
wire ready_commit;
wire [`LOG_PHYS-1:0] old_phys_register;

initial begin
    assign update_ROB_RRAT = 0;
    assign ROB_full = 0;
    assign reg_update = 0;
    assign ready_commit = 0;
end

assign Flush_OUT = 1'b0;    // TODO

ROB #(64, ROB_ENTRY_BITS, NUM_ARCH_REGS, NUM_PHYS_REGS) ROB(
    .CLK(CLK),
    .RESET(RESET),
    .Entry_valid_IN(ROB_entry_valid_IN),
    .Entry_IN(ROB_entry_IN),
    .Update_IN(Update_ROB_IN),
    .Update_entry_IN(Update_entry_IN),
    .Free_entry(ROB_free_entry_OUT),
    .Full(ROB_full),
    .Arch_reg(Arch_reg),
    .Phys_reg(Phys_reg),
    .RegUpdate(reg_update),
    .ReadyCommit(ready_commit)
);

assign ROB_full_OUT = ROB_full;

assign update_ROB_RRAT = !ROB_full && reg_update && ready_commit;

RAT #(
    .NUM_ARCH_REGS(35),
    .NUM_PHYS_REGS(NUM_PHYS_REGS),
    .NAME("R-RAT")
)RRAT(
    .CLK(CLK),
    .RESET(RESET),
    .Register_update_src(Arch_reg),
    .Register_update_dst(Phys_reg),
    .Write(update_ROB_RRAT),
    .Old_phys_register(old_phys_register),
    .regPtrs(RegPtrs_OUT)
);

assign ROB_free_reg_OUT = update_ROB_RRAT && old_phys_register != Phys_reg;
assign ROB_phys_reg_OUT = update_ROB_RRAT && old_phys_register != Phys_reg ? Phys_reg : 0;

endmodule
