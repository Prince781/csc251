// ------------------------
// Reorder buffer / retire
// ------------------------
`include "config.v"

`define LOG_ARCH $clog2(NUM_ARCH_REGS)
`define LOG_PHYS $clog2(NUM_PHYS_REGS)

module ROB #(
    parameter ENTRY_BITS = `ROB_ENTRY_BITS,
    parameter NUM_ARCH_REGS = `NUM_ARCH_REGS,
)
(
    input CLK,
    input RESET,

    input Entry_valid_IN,
    input [ENTRY_BITS-1:0] Entry_IN,

    output [LOG_ARCH-1:0] Arch_reg,
    output [LOG_PHYS-1:0] Phys_reg,

    output RegUpdate,                   // whether the R-RAT is actually updated
    output Ready                        // whether the ROB is ready to commit the top instruction,
                                        // and top instruction has been popped
);

assign Arch_reg = 0;
assign Phys_reg = 0;
assign RegUpdate = 0;
assign Ready = 0;

always @(posedge CLK or negedge RESET) begin
    if (!RESET) begin
        $display("ROB/RETIRE: RESET");
    end else if (CLK) begin     // is this necessary?
        // TODO 
    end
end

endmodule
