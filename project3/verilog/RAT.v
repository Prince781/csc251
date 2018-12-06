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
    parameter NUM_PHYS_REGS = 64
    /* Maybe Others? */
)
(	
    /* Write Me */
	input CLK,
    input RESET,
	input [`LOG_ARCH-1:0] Register_update_src,
	input [`LOG_PHYS-1:0] Register_update_dst,
	input [`LOG_ARCH-1:0] Register_request_in,
	input Read, 
	input Write,
	output Register_request_out

		); 

	// actual RAT memory
	reg [`LOG_PHYS-1:0] regPtrs [NUM_ARCH_REGS-1:0] /*verilator public_flat*/;

    /* Write Me */
	always @(Read or Write) begin
    if (!RESET) begin
        $display("RAT %s RESET", Register_src);
    end else begin
        if (Read) begin
			Register_request_out = regPtrs[Register_request_in];
		end

		if (Write) begin
			regPtrs[Register_update_src] = Register_update_dst;
		end
	end

endmodule

