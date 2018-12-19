`include "config.v"
module RENAME
(
    input CLK,
    input RESET,

    input Instr1_Valid_IN,                  // whether the queue we're popping from has an element

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
    input ALUSrc1,                          // whether instr has an immediate
    input [31:0] MemWriteData1_IN,
    input [5:0] ALU_Control1_IN,
    input RegWrite_IN,
    input MemRead_IN,                       // if 1, instr belongs in load/store queue
    input MemWrite_IN,                      // if 1, instr belongs in store/store queue
    input [4:0] ShiftAmount1_IN,

    // stuff from F-RAT, free list, ROB, and queues
    input [`LOG_PHYS-1:0] Map_arch_to_phys [`NUM_ARCH_REGS-1:0],
    input [`LOG_PHYS-1:0] Free_phys_reg;
    input Free_reg_avail;
    input ROB_full,
    input Issue_queue_full,
    input Load_store_queue_full,

    output [`ISSUE_QUEUE_ENTRY_BITS-1:0] Issue_queue_entry,
    output Issue_queue_entry_valid,
    output [`LOAD_STORE_QUEUE_ENTRY_BITS-1:0] Load_store_queue_entry,
    output Load_store_queue_entry_valid,

    output [`ROB_ENTRY_BITS-1:0] ROB_entry, // we don't need ROB_entry_valid because we rely on Blocked
    output Grabbed_regs,                    // number of registers we grabbed off the free list

    output Blocked                          // whether the Rename stage can proceed
);

wire num_needed_regs = !!WriteRegister1_IN;

always @(posedge CLK or negedge RESET) begin
    Blocked = 0;
    Grabbed_regs = 0;
    Issue_queue_entry_valid = 0;
    Load_store_queue_entry_valid = 0;
    $display("RENAME: instr@%x=%x: RegWrite? %b WriteReg = %d ReadReg1 = %d ReadReg2 = %d", 
        Instr1_addr, Instr1_IN, RegWrite_IN, WriteRegister1_IN, ReadRegisterA1_IN, ReadRegisterB1_IN);
    if (!RESET) begin
        $display("RENAME: RESET");
        Issue_queue_entry = 0;
        Load_store_queue_entry = 0;
        ROB_entry = 0;
        Grabbed_regs = 0;
        Blocked = 1;    /* ??? TODO */
    end else if (!Instr1_Valid_IN) begin
        $display("RENAME: blocked while waiting for instruction.");
        Blocked = 1;
    end else if (ROB_full) begin
        $display("RENAME: blocked while ROB is full.");
        Blocked = 1;
    end else if (RegWrite_IN) begin     // this instruction writes to a register (either ld or ALU op)
        if (Free_reg_avail < num_needed_regs) begin
            $display("RENAME: blocked while waiting for free registers.");
            Blocked = 1;
        else if (Issue_queue_full) begin
            $display("RENAME: blocked while issue queue is full.");
            Blocked = 1;
        end else begin      // we have the registers, and our place in the ROB, but what about the issue queue/LS queue?
            if (MemRead_IN) begin       // we are a ld
                if (Load_store_queue_full) begin
                    $display("RENAME: blocked waiting for LS queue.");
                    Blocked = 1;
                end else begin      // we're good to go; we should only need one reg
                    Load_store_queue_entry = {0,0,Free_phys_reg,0};
                    Load_store_queue_entry_valid = 1;
                end
            end
            if (!MemRead_IN || !Load_store_queue_full) begin
                Issue_queue_entry = {ALU_Control1_IN, 
                    !ReadRegisterA1_IN ? 0 : Map_arch_to_phys[ReadRegisterA1_IN], OperandA1_IN, ALUSrc1 | (!ReadRegisterA1_IN & !Busy_list[ReadRegisterA1_IN]), 
                    !ReadRegisterB1_IN ? 0 : Map_arch_to_phys[ReadRegisterB1_IN], OperandB1_IN, ALUSrc1 | (!ReadRegisterB1_IN & !Busy_list[ReadRegisterB1_IN]),
                    ShiftAmount1_IN,
                    1, Free_phys_reg,
                    MemWrite1_IN, MemRead1_IN};
                Issue_queue_entry_valid = 1;
                Grabbed_regs = num_needed_regs;
                ROB_entry = {0, Instr1_IN, Instr1_addr, Alt_PC, Request_Alt_PC, 1, Free_phys_reg, WriteRegister1_IN};
            end
        end
    end else if (MemWrite_IN) begin     // this instruction stores to memory
        if (Issue_queue_full) begin
            $display("RENAME: blocked while issue queue is full.");
            Blocked = 1;
        end else begin
            Load_store_queue_entry = {1,0,!ReadRegisterA1_IN ? 0 : Map_arch_to_phys[ReadRegisterA1_IN],0};
            Load_store_queue_entry_valid = 1;
            Issue_queue_entry = {ALU_Control1_IN, 
                !ReadRegisterA1_IN ? 0 : Map_arch_to_phys[ReadRegisterA1_IN], OperandA1_IN, ALUSrc1 | (!ReadRegisterA1_IN & !Busy_list[ReadRegisterA1_IN]), 
                !ReadRegisterB1_IN ? 0 : Map_arch_to_phys[ReadRegisterB1_IN], OperandB1_IN, ALUSrc1 | (!ReadRegisterB1_IN & !Busy_list[ReadRegisterB1_IN]),
                ShiftAmount1_IN,
                0, 0,
                MemWrite_IN, MemRead_IN};
            Issue_queue_entry_valid = 1;
        end
    end else begin                      // this instruction is something else, like a branch or jump
        Issue_queue_entry = {ALU_Control1_IN, 
            !ReadRegisterA1_IN ? 0 : Map_arch_to_phys[ReadRegisterA1_IN], OperandA1_IN, ALUSrc1 | (!ReadRegisterA1_IN & !Busy_list[ReadRegisterA1_IN]), 
            !ReadRegisterB1_IN ? 0 : Map_arch_to_phys[ReadRegisterB1_IN], OperandB1_IN, ALUSrc1 | (!ReadRegisterB1_IN & !Busy_list[ReadRegisterB1_IN]),
            ShiftAmount1_IN,
            0, 0,
            MemWrite_IN, MemRead_IN};
        Issue_queue_entry_valid = 1;
        Grabbed_regs = num_needed_regs;
        ROB_entry = {0, Instr1_IN, Instr1_addr, Alt_PC, Request_Alt_PC, 0, 0, WriteRegister1_IN};
    end
end

endmodule
