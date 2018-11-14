/********
 * Return Address Stack
 */
module RAS(
    input CLK,
    input [31:0] Instr_input,          // the current instruction
    input [31:0] Instr_addr_input,     // for debug
    input [31:0] Last_Instr_input,
    input [31:0] Last_Instr_addr_input,// for debug
    input [31:0] Resolved_addr_IN,  // the address the last instruction resolved to
    output Valid_OUT,
    output [31:0] Addr_OUT
);

// 32 entries
reg [31:0] stack [31:0];
reg [5:0] pos;      // from 0 to 31
reg [5:0] start;    // from 0 to 31

wire last_is_jump;
wire last_writes_reg;

wire cur_is_jump;
wire cur_writes_reg;

wire [5:0] tmp;

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

always @(posedge CLK) begin
    // manipulate the stack
    if (last_is_jump & !last_writes_reg) begin
        // pop
        if (pos == start) begin
            $display("RAS: pop(): stack empty");
        end else begin
            pos = (pos - 1) % 6'd32;
            $display("RAS: pop() @ %x", Last_Instr_addr_input);
        end
    end else if (last_is_jump & last_writes_reg) begin
        // push
        if (pos == ((start + 6'd31) % 6'd32)) begin
            $display("RAS: stack full");
            start = (start + 1) % 6'd32;        // forget the earliest element
        end
        pos = (pos + 1) % 6'd32;
        stack[pos[4:0]] = Resolved_addr_IN;
        $display("RAS: push(%x) @ %x", Resolved_addr_IN, Last_Instr_addr_input);
    end

    // don't manipulate the stack for speculated instructions
    if (cur_is_jump & !cur_writes_reg) begin
        if (pos != start) begin
            Valid_OUT = 1;
            assign tmp = (pos - 1) % 6'd32;
            Addr_OUT = stack[tmp[4:0]];
            $display("RAS: peek(): predicting %x => %x", Instr_addr_input, stack[pos[4:0]]);
        end else begin
            Valid_OUT = 0;
            Addr_OUT = 0;
            $display("RAS: stack empty");
        end
    end
    else begin
        Valid_OUT = 0;
        Addr_OUT = 0;
        $display("RAS: current instruction is not JR");
    end
end

endmodule
