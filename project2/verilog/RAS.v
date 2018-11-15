/********
 * Return Address Stack
 */
module RAS(
    input CLK,
    input FLUSH,
    input RESET,
    input [31:0] Instr_input,          // the current instruction
    input [31:0] Instr_addr_input,     // for debug
    input [31:0] Last_Instr_input,
    input [31:0] Last_Instr_addr_input,
    output Valid_OUT,
    output [31:0] Addr_OUT
);

// 32 entries (technically 64, but we only use 32)
reg [31:0] stack [63:0];
reg [5:0] pos;      // from 0 to 31
reg [5:0] start;    // from 0 to 31

wire last_is_jump;
wire last_writes_reg;

wire cur_is_jump;
wire cur_writes_reg;

Decoder #(.TAG("RAS-Instr_input")) Last_Instr_input_Decode(
    .Instr(Last_Instr_input),
    .Instr_PC(Last_Instr_addr_input),
    .comment1(1'b0),
    .comment(1'b0),
    /* ignore everything except for these */
    .Jump(last_is_jump),
    .RegWrite(last_writes_reg)
);


Decoder #(.TAG("RAS-Instr_input")) Instr_input_Decode(
    .Instr(Instr_input),
    .Instr_PC(Instr_addr_input),
    .comment1(1'b0),
    .comment(1'b0),
    /* ignore everything except for these */
    .Jump(cur_is_jump),
    .RegWrite(cur_writes_reg)
);

always @(posedge CLK or negedge RESET) begin
    // manipulate the stack
    if (last_is_jump & !last_writes_reg) begin
        // pop
        if (pos == start) begin
            $display("RAS: instr@%x pop(): stack empty", Last_Instr_addr_input);
        end else begin
            pos = (pos - 1) % 6'd32;
            $display("RAS: instr@%x pop() from stack[%d]", Last_Instr_addr_input, pos[4:0]);
        end
    end else if (last_is_jump & last_writes_reg) begin
        // push
        if (pos == ((start + 6'd31) % 6'd32)) begin
            $display("RAS: stack full");
            start = (start + 1) % 6'd32;        // forget the earliest element
        end
        stack[pos] = Last_Instr_addr_input + 8;
        $display("RAS: instr@%x push(%x) to stack[%d]", Last_Instr_addr_input, Last_Instr_addr_input + 8, pos);
        pos = (pos + 1) % 6'd32;
    end

    if (FLUSH || !RESET) begin
        Addr_OUT <= 0;
        Valid_OUT <= 1'b0;
        $display("RAS: [FLUSH]");
    end
    // don't manipulate the stack for speculated instructions
    else if (cur_is_jump & !cur_writes_reg) begin
        if (pos != start) begin
            Valid_OUT <= 1;
            Addr_OUT <= stack[(pos - 1) % 6'd32];
            $display("RAS: peek() from stack[%d]: predicting %x => %x", pos, Instr_addr_input, stack[(pos - 1) % 6'd32]);
        end else begin
            Valid_OUT <= 0;
            Addr_OUT <= 0;
            $display("RAS: stack empty");
        end
    end
    else begin
        Valid_OUT <= 1'b0;
        Addr_OUT <= 0;
        $display("RAS: current instruction is not JR");
    end
end

endmodule
