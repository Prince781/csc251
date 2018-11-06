/*********
 * Predict History Table
 */
module PHT(
    input CLK,
    input STALL,
    input Update_IN,                /* whether to update the predictor */
    input Resolution_IN,            /* how the branch actually resolved */
    input [31:0] Instr_Addr_IN,     /* current PC */
    input Is_Branch_IN,             /* is this a branch? */
    output reg Valid_OUT,           /* valid? */
    output reg Taken_OUT            /* taken? */
);

reg [1:0] fsms [1023:0];
reg needs_update;
reg [31:0] last_PC;

wire[9:0] prev_idx;
wire[9:0] idx;
wire[1:0] fsm;

assign prev_idx = {last_PC[11:2]};
assign prev_fsm = fsms[prev_idx];

assign idx = {Instr_Addr_IN[11:2]};
assign fsm = fsms[idx];

always @(posedge CLK) begin
    if (!STALL) begin
        /* TODO: delay update if we see another speculative instruction? */
        if (needs_update) begin
            if (Resolution_IN) begin
                /* saturate up */
                fsms[prev_idx] <= prev_fsm + (prev_fsm >= 1'b11 ? 1'b00 : 1'b01);
            end else begin
                /* saturate down */
                fsms[prev_idx] <= prev_fsm - (prev_fsm <= 1'b00 ? 1'b00 : 1'b01);
            end
            $display("PHT: updating with %x => %s", last_PC, Resolution_IN ? "taken" : "not taken");
        end

        if (Is_Branch_IN) begin
            if (fsm == 1'b00 || fsm == 1'b01) begin
                /* predict not taken */
                $display("PHT: predicting %x => not taken", Instr_Addr_IN);
                Taken_OUT <= 1'b0;
            end else if (fsm == 1'b11 || fsm == 1'b10) begin
                /* predict taken */
                $display("PHT: predicting %x => taken", Instr_Addr_IN);
                Taken_OUT <= 1'b1;
            end
            needs_update <= 1'b1;
            last_PC <= Instr_Addr_IN;
            Valid_OUT <= 1'b1;
        end else begin  /* not a branch */
            $display("PHT: not a branch");
            needs_update <= 1'b0;
            last_PC <= 0;
            Valid_OUT <= 0;
            Taken_OUT <= 0;
        end
    end else begin
        $display("PHT: stalling...");
        Taken_OUT <= 0;
        Valid_OUT <= 0;
    end
end
