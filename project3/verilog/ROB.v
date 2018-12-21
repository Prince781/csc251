// ------------------------
// Reorder buffer / retire
// ------------------------
`include "config.v"

`define LOG_ARCH $clog2(NUM_ARCH_REGS)
`define LOG_PHYS $clog2(NUM_PHYS_REGS)

module ROB #(
    parameter SIZE = 64,
    parameter ENTRY_BITS = `ROB_ENTRY_BITS,
    parameter NUM_ARCH_REGS = `PROJ_NUM_ARCH_REGS,
    parameter NUM_PHYS_REGS = `PROJ_NUM_PHYS_REGS
)
(
    input CLK,
    input RESET,

    input Entry_valid_IN,
    input [ENTRY_BITS-1:0] Entry_IN,

    output reg Full,                    // whether the ROB is full

    output [`LOG_ARCH-1:0] Arch_reg,
    output [`LOG_PHYS-1:0] Phys_reg,
    output RegUpdate,                   // whether the R-RAT is actually updated

    output ReadyCommit                  // whether the ROB is ready to commit the top instruction,
                                        // and top instruction has been popped
);

reg [ENTRY_BITS-1:0] queue [SIZE:0];
reg [$clog2(SIZE):0] head, tail;

reg [31:0] Instr1;
reg [31:0] Instr1_PC;
reg [31:0] Alt_PC;
reg Request_Alt_PC;

`define ROB_QUEUE_SIZE (tail >= head ? tail - head : tail + (SIZE - head))
`define ROB_QUEUE_FULL (`ROB_QUEUE_SIZE == SIZE)
`define ROB_QUEUE_EMPTY (`ROB_QUEUE_SIZE == 0)
`define ROB_QUEUE_PUSH(data) queue[tail] <= data; tail <= (tail + 1) % SIZE
// `define ROB_QUEUE_POP queue[head]; head <= (head + 1) % SIZE

always @(posedge CLK or negedge RESET) begin
    if (!RESET) begin
        $display("ROB: RESET");
        Arch_reg <= 0;
        Phys_reg <= 0;
        RegUpdate <= 0;
        ReadyCommit <= 0;
        Full <= 0;
    end else if (CLK) begin     // is this necessary?
        // accepting a new instruction
        if (`ROB_QUEUE_FULL) begin
            $display("ROB: full - won't accept any more instructions");
            Full <= 1;
        end else begin
            if (Entry_valid_IN) begin
                // we're not full
                `ROB_QUEUE_PUSH(Entry_IN);
                $display("ROB: accepting instruction");
            end
            Full <= 0;
        end

        // retiring an instruction
        if (`ROB_QUEUE_EMPTY) begin
            $display("ROB: empty - won't retire any instructions");
            Arch_reg <= 0;
            Phys_reg <= 0;
            RegUpdate <= 0;
            ReadyCommit <= 0;
        end else begin
            {ReadyCommit, Instr1, Instr1_PC, Alt_PC, Request_Alt_PC, RegUpdate, Phys_reg, Arch_reg} <= queue[head];
            if (ReadyCommit) begin
                $display("ROB: popping");
                queue[head] <= 0;
                head <= (head + 1) % SIZE;
            end
        end
    end
end

endmodule
