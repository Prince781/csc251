`include "config.v"
module RENAME
(
    input CLK,
    input RESET,

    input [31:0] Instr1_IN,
    input [31:0] Instr1_addr,

    input [31:0] Alt_PC,
    input Request_Alt_PC,

    // stuff from Decode stage
    input [31:0] OperandA1_IN,
    input [31:0] OperandB1_IN,
    input [4:0] ReadRegisterA1_IN,
    input [4:0] ReadRegisterB1_IN,
    input [4:0] WriteRegister1_IN,
    input [31:0] MemWriteData1_IN,
    input [5:0] ALU_Control1_IN,
    input RegWrite_IN,              // if 1, instr belongs in issue queue
    input MemRead_IN,               // if 1, instr belongs in load queue
    input MemWrite_IN,              // if 1, instr belongs in store queue

    // stuff from free list, ROB, and queues
    input [11:0] Free_phys_regs,    // 3x4-bit physical registers (some or all may be empty)
    input [1:0] Free_reg_avail,     // number of free registers available (0 to 3)
    input ROB_full,
    input Issue_queue_full,
    input Load_queue_full,
    input Store_queue_full,

    // TODO: figure out proper sizes for all outputs
    output Issue_queue_entry,
    output Load_queue_entry,
    output Store_queue_entry,

    output [ROB_ENTRY_BITS-1:0] ROB_entry
);


always @(posedge CLK or negedge RESET) begin
end

endmodule
