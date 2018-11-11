`include "config.v"
// Bimodal branch predictor
module Bimodal(
    input CLK,
    input RESET,
    input FLUSH,
    input [31:0] Instr_input,           /* the current instruction */
    input [31:0] Instr_addr_input,      /* the current PC */
    input [31:0] Branch_instr,       /* the current instruction in MEM */
    input Branch_resolved,              /* whether the last branch resolved */
    input [31:0] Branch_resolved_addr,  /* the address the last branch resolved to */
    input [31:0] Branch_addr,           /* the address of the last branch instruction */
    output Taken,                       /* whether the branch is taken */
    output [31:0] Taken_addr            /* the predicted branch address */
);

wire last_branch_resolved;
wire [31:0] last_branch_addr;
wire [31:0] last_branch_resolved_addr;
wire branch1;
wire jump1;
wire is_branch_last;

wire branch2;
wire jump2;
wire is_branch;
wire pht_taken;
wire [31:0] btb_addr;

Decoder #(.TAG("BTB-BranchInstr")) IsBranch1(
    .Instr(Branch_instr),
    .Instr_PC(Branch_addr),
    .comment1(1'b0),
    .comment(1'b0),
    /* ignore everything else except for these two*/
    .Jump(jump1),
    .Branch(branch1)
);

assign is_branch_last = jump1 | branch1;

assign last_branch_resolved = (is_branch_last) ? Branch_resolved : 1'b0;
assign last_branch_addr = (is_branch_last) ? Branch_addr : 32'd0;
assign last_branch_resolved_addr = (is_branch_last) ? Branch_resolved_addr : 32'd0;

Decoder #(.TAG("BTB-CurInstr")) IsBranch2(
    .Instr(Instr_input),
    .Instr_PC(Instr_addr_input),
    .comment1(1'b0),
    .comment(1'b0),
    /* ignore everything else except for these two*/
    .Jump(jump2),
    .Branch(branch2)
);

assign is_branch = jump2 | branch2;

BTB BTB(
    .CLK(CLK),
    .Resolution_IN(last_branch_resolved),
    .Branch_addr_IN(last_branch_addr),
    .Branch_resolved_addr_IN(last_branch_resolved_addr),
    .Instr_Addr_IN(Instr_addr_input),
    .Is_Branch_IN(is_branch),
    .Addr_OUT(btb_addr)
);

PHT PHT(
    .CLK(CLK),
    .Resolution_IN(last_branch_resolved),
    .Branch_addr_IN(last_branch_addr),
    .Instr_Addr_IN(Instr_addr_input),
    .Is_Branch_IN(is_branch),
    .Taken_OUT(pht_taken)
);

always @(posedge CLK or negedge RESET) begin
    if (!RESET || FLUSH) begin
        Taken <= 0;
        Taken_addr <= 0;
        $display("Bimodal [RESET]");
    end else if (CLK) begin
        Taken <= pht_taken;
        Taken_addr <= btb_addr;
        $display("Bimodal: instr@%x=%x Taken? %x => %x", Instr_addr_input, Instr_input, pht_taken, btb_addr);
    end
    if (is_branch_last) begin
        $display("Bimodal: last branch@%x=%x actually %s", Branch_addr, Branch_instr, Branch_resolved ? "taken" : "not taken");
    end else begin
        $display("Bimodal: last instr@%x=%x", Branch_addr, Branch_instr);
    end
end

endmodule
