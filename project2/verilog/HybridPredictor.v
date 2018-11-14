`include "config.v"
// Hybrid Branch Predictor
module HybridPredictor(
    input CLK,
    input RESET,
    input FLUSH,
    input [31:0] Instr_input,           /* the current instruction */
    input [31:0] Instr_addr_input,      /* the current PC */
    input [31:0] Branch_instr,       /* the current instruction in MEM */
    input Branch_resolved,              /* whether the last branch resolved */
    input [31:0] Branch_resolved_addr,  /* the address the last branch resolved to */
    input [31:0] Branch_addr,           /* the address of the last branch instruction */
    input [1:0] Branch_predictions,     /* [1] = global, [0] = local prediction; from latest-resolved branch */
    output Taken,                       /* whether the branch is taken */
    output [31:0] Taken_addr,           /* the predicted branch address */
    output [1:0] Branch_predictions_OUT /* the global/local predictions for the current branch (if it is one) */
);

wire Branch_local_prediction;
wire Branch_global_prediction;

wire last_branch_resolved;
wire [31:0] last_branch_addr;
wire [31:0] last_branch_addr_not_jump;
wire [31:0] last_branch_resolved_addr;
wire branch1;
wire jump1;
wire is_branch_last;

wire branch2;
wire jump2;
wire is_branch;
wire meta_use_global;
wire global_taken;
wire local_taken;

wire [31:0] btb_addr;
wire btb_valid;

wire [31:0] ras_addr;
wire ras_valid;

assign Branch_global_prediction = Branch_predictions[1];
assign Branch_local_prediction = Branch_predictions[0];

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
assign last_branch_addr_not_jump = (branch1) ? last_branch_addr : 32'd0;
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
    .RESET(RESET),
    .FLUSH(FLUSH),
    .Resolution_IN(last_branch_resolved),
    .Branch_addr_IN(last_branch_addr),
    .Branch_resolved_addr_IN(last_branch_resolved_addr),
    .Instr_Addr_IN(Instr_addr_input),
    .Is_Branch_IN(is_branch),
    .Addr_OUT(btb_addr),
    .Valid_OUT(btb_valid)
);

MetaPredictor MetaPredictor(
    .CLK(CLK),
    .RESET(RESET),
    .Branch_resolved(last_branch_resolved),
    .Branch_local_prediction(Branch_local_prediction),
    .Branch_global_prediction(Branch_global_prediction),
    .Branch_addr_IN(last_branch_addr),
    .Instr_addr_input(last_branch_addr_not_jump),
    .Instr_input(Instr_input),
    .Use_global(meta_use_global)
);

GlobalPredictor GlobalPredictor(
    .CLK(CLK),
    .RESET(RESET),
    .Instr_input(Instr_input),
    .Instr_addr_input(Instr_addr_input),
    .Branch_resolved(last_branch_resolved),
    .Branch_addr_IN(last_branch_addr_not_jump),
    .Taken(global_taken)
);

LocalPredictor LocalPredictor(
    .CLK(CLK),
    .RESET(RESET),
    .Instr_input(Instr_input),
    .Instr_addr_input(Instr_addr_input),
    .Branch_resolved(last_branch_resolved),
    .Branch_addr_IN(last_branch_addr_not_jump),
    .Taken(local_taken)
);

RAS RAS(
    .CLK(CLK),
    .Instr_input(Instr_input),
    .Instr_addr_input(Instr_addr_input),
    .Last_Instr_input(Branch_instr),
    .Last_Instr_addr_input(Branch_addr),
    .Resolved_addr_IN(Branch_resolved_addr),
    .Valid_OUT(ras_valid),
    .Addr_OUT(ras_addr)
);

always @(posedge CLK or negedge RESET) begin
    if (!RESET || FLUSH) begin
        Taken = 0;
        Taken_addr = 0;
        Branch_predictions_OUT = 0;
        $display("Hybrid [RESET]");
    end else if (CLK) begin
        if (ras_valid) begin
            Taken = ras_valid;
            Taken_addr = ras_addr;
            Branch_predictions_OUT = 0;     // don't train the metapredictor next time
            $display("Hybrid: instr@%x=%x Taken? 1 => %x (using RAS)", Instr_addr_input, Instr_input, ras_addr);
        end else begin
            Taken = ((meta_use_global ? global_taken : local_taken) | branch2) & btb_valid;
            Taken_addr = btb_addr;
            Branch_predictions_OUT = {global_taken,local_taken};
            $display("Hybrid: instr@%x=%x Taken? %x (%x)=> %x", Instr_addr_input, Instr_input, ((meta_use_global ? global_taken : local_taken) | branch2), btb_valid, btb_addr);
        end
    end
    if (is_branch_last) begin
        $display("Hybrid: last branch@%x=%x actually %s", Branch_addr, Branch_instr, Branch_resolved ? "taken" : "not taken");
    end else begin
        $display("Hybrid: last instr@%x=%x", Branch_addr, Branch_instr);
    end
end

endmodule
