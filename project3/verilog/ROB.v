// ------------------------
// Reorder buffer / retire
// ------------------------
`include "config.v"

`define LOG_ARCH $clog2(NUM_ARCH_REGS)
`define LOG_PHYS $clog2(NUM_PHYS_REGS)

module ROB #(
    parameter SIZE = 64,
    parameter ENTRY_BITS = `ROB_ENTRY_BITS,
    parameter NUM_ARCH_REGS = `NUM_ARCH_REGS,
)
(
    input CLK,
    input RESET,

    input Entry_valid_IN,
    input [ENTRY_BITS-1:0] Entry_IN,

    output reg Full,                    // whether the ROB is full

    output [LOG_ARCH-1:0] Arch_reg,
    output [LOG_PHYS-1:0] Phys_reg,
    output RegUpdate,                   // whether the R-RAT is actually updated

    output ReadyCommit                  // whether the ROB is ready to commit the top instruction,
                                        // and top instruction has been popped
);

reg [ENTRY_BITS-1:0] queue [SIZE:0];
reg [$clog2(SIZE):0] head, tail;

wire [ENTRY_BITS-1:0] entry_OUT;

`define QUEUE_SIZE (tail >= head ? tail - head : tail + (SIZE - head))
`define QUEUE_FULL (`QUEUE_SIZE == SIZE)
`define QUEUE_EMPTY (`QUEUE_SIZE == 0)
`define QUEUE_PUSH(data) queue[tail] = data; tail = (tail + 1) % SIZE
`define QUEUE_POP queue[head]; head = (head + 1) % SIZE

assign Arch_reg = 0;
assign Phys_reg = 0;
assign RegUpdate = 0;
assign ReadyCommit = 0;

initial begin
    head = 0;
    tail = 0;
    entry_OUT = 0;
end

always @(posedge CLK or negedge RESET) begin
    if (!RESET) begin
        $display("ROB/RETIRE: RESET");
        Full = 0;
    end else if (CLK) begin     // is this necessary?
        // accepting a new instruction
        if (`QUEUE_FULL) begin
            $display("ROB/RETIRE: full - won't accept any more instructions");
            Full = 1;
        end else if (Entry_valid_IN) begin
            // we're not full
            QUEUE_PUSH(Entry_IN);
            $display("ROB/RETIRE: accepting instruction");
        end

        // retiring an instruction
        if (`QUEUE_EMPTY) begin
            $display("ROB/RETIRE: empty - won't retire any instructions");
        end
    end
end

endmodule
