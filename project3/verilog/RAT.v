//-----------------------------------------
//           RAT
//-----------------------------------------

`define LOG_ARCH    $clog2(NUM_ARCH_REGS)
`define LOG_PHYS    $clog2(NUM_PHYS_REGS)

module RAT #(
	/*
	 * NUM_ARCH_REGS is the number of architectural registers present in the
	 * RAT.
	 *
	 * sim_main assumes that the value of LO is stored in architectural
	 * register 33, and that the value of HI is stored in architectural
	 * register 34.
	 *
	 * It is left as an exercise to the student to explain why.
	 */
    parameter NUM_ARCH_REGS = 35,
    parameter NUM_PHYS_REGS = 64,
    parameter NAME = "?-RAT"
    /* Maybe Others? */
)
(
    input CLK,
    input RESET,
	input [`LOG_ARCH-1:0] Register_update_src,      /* arch register */
	input [`LOG_PHYS-1:0] Register_update_dst,      /* phys register */
	input Write,

    output [`LOG_PHYS-1:0] Old_phys_register,

	// actual RAT memory
	output reg [`LOG_PHYS-1:0] regPtrs [NUM_ARCH_REGS-1:0] /*verilator public_flat*/
);
  reg [`LOG_PHYS-1:0] ptrs [NUM_ARCH_REGS-1:0];
  assign regPtrs = ptrs;
    /* Write Me */
	always @(posedge CLK or negedge RESET) begin
        if (!RESET) begin
            $display("%s RESET", NAME);
            // TODO: what should be done here?
        end else begin
            if (Write) begin
                $display("%s: AReg #%d -> PReg #%d", NAME, Register_update_src, Register_update_dst);
                Old_phys_register = ptrs[Register_update_src];
                ptrs[Register_update_src] = Register_update_dst;
            end else begin
                $display("%s: No action", NAME);
            end
        end
	end

endmodule
