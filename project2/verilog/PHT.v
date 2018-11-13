/*********
 * Predict History Table
 */
module PHT(
    input CLK,
    input FLUSH,
    input RESET,
    input Resolution_IN,            /* how the branch actually resolved */
    input [31:0] Branch_addr_IN,    /* the address of the last branch instruction*/
    input [31:0] Instr_Addr_IN,     /* current PC */
    input Is_Branch_IN,             /* is this a branch? */
    output reg Taken_OUT            /* taken? */
);

reg [1:0] fsms [1023:0];

wire[9:0] prev_idx;
wire[1:0] prev_fsm;
wire[9:0] idx;
wire[1:0] fsm;

assign prev_idx = {Branch_addr_IN[11:2]};
assign prev_fsm = fsms[prev_idx];

assign idx = {Instr_Addr_IN[11:2]};
assign fsm = fsms[idx];

always @(posedge CLK or negedge RESET) begin
    if (Branch_addr_IN != 0) begin
        if (Resolution_IN) begin
            /* saturate up */
            fsms[prev_idx] <= prev_fsm + (prev_fsm >= 2'b11 ? 2'b00 : 2'b01);
            $display("PHT: saturating up");
        end else begin
            /* saturate down */
            fsms[prev_idx] <= prev_fsm - (prev_fsm <= 2'b00 ? 2'b00 : 2'b01);
            $display("PHT: saturating down");
        end
        $display("PHT: updating FSM with %x => %s", Branch_addr_IN, Resolution_IN ? "taken" : "not taken");
    end

    if (FLUSH || !RESET) begin
        Taken_OUT <= 0;
        $display("PHT: [FLUSH]");
    end else begin
        if (Is_Branch_IN) begin
            if (fsm == 2'b00 || fsm == 2'b01) begin
                /* predict not taken */
                $display("PHT: predicting %x => not taken", Instr_Addr_IN);
                Taken_OUT <= 1'b0;
            end else if (fsm == 2'b11 || fsm == 2'b10) begin
                /* predict taken */
                $display("PHT: predicting %x => taken", Instr_Addr_IN);
                Taken_OUT <= 1'b1;
            end
        end else begin  /* not a branch */
            $display("PHT: current instr not a branch");
            Taken_OUT <= 0;
        end
    end
end

endmodule
