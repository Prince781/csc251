/************************
 * Branch Target Buffer
 * With 2-way set-associative cache.
 ************************/
module BTB(
    input CLK,
    input STALL,
    input [31:0] Instr_IN,          /* instruction; used to determine whether this is a branch */
    input [31:0] Instr_Addr_IN,     /* current PC */
    output reg Valid_OUT,
    output reg [31:0] Addr_OUT      /* new PC */
);

/* (32 + 1 valid bit + 20-bit tag + 1 LRU bit) * 2-way = 108 bits */
reg[107:0] cache [1023:0];  // [107:54] = entry 1, [53:0] = entry 2
reg last_missed;
reg[31:0] last_PC;

wire is_branch;
wire[9:0] idx;
wire[107:0] cache_set;
wire[19:0] tag_in;

wire islru1;
wire valid1;
wire[19:0] tag1;
wire[31:0] target1;
wire islru2;
wire valid2;
wire[19:0] tag2;
wire[31:0] target2;

wire[19:0] last_tag;

always @(Instr_IN) begin
    case (Instr_IN[31:26])
        6'b010001,
        6'b000100,
        6'b000001,
        6'b000111,
        6'b010111,
        6'b000011,
        6'b000010,
        6'b000101: assign is_branch = 1'b1;
        6'b000000: begin
            case(Instr_IN[5:0])
                6'b001001,
                6'b001000: assign is_branch = 1'b1;
                default: assign is_branch = 1'b0;
            endcase
        end
        default: assign is_branch = 1'b0;
    endcase
end

assign idx = {Instr_Addr_IN[11:2]};
assign cache_set = cache[idx];
assign tag_in = {Instr_Addr_IN[31:12]};

assign islru1 = {cache_set[107]};
assign valid1 = {cache_set[106]};
assign tag1 = {cache_set[105:86]};
assign target1 = {cache_set[85:54]};

assign islru2 = {cache_set[53]};
assign valid2 = {cache_set[52]};
assign tag2 = {cache_set[51:32]};
assign target2 = {cache_set[31:0]};

assign last_tag = {last_PC[31:12]};

always @(posedge CLK) begin
    if (!STALL) begin
        $display("BTB: Instr = %x", Instr_IN);
        /* update the cache if we missed the last time */
        /* TODO: delay update if we see another speculative instruction? */
        if (last_missed) begin
            /* find LRU */
            if (islru1) begin
                cache[idx] <= {1'b1,valid2,tag2,target2,1'b0,1'b1,last_tag,last_PC};
            end else begin
                cache[idx] <= {1'b0,1'b1,last_tag,last_PC,1'b1,valid1,tag1,target1};
            end
            $display("BTB: updating cache with %x => %x", last_PC, Instr_Addr_IN);
        end

        if (is_branch) begin
            if (valid1 && tag_in == tag1) begin
                Addr_OUT <= target1;
                Valid_OUT <= 1'b1;
                cache[idx] <= {1'b1,valid2,tag2,target2,1'b0,valid1,tag1,target1};
                $display("BTB: hit in block 1");
                last_PC <= 0;
                last_missed <= 0;
            end else if (valid2 && tag_in == tag2) begin
                Addr_OUT <= target2;
                Valid_OUT <= 1'b1;
                cache[idx] <= {1'b0,valid2,tag2,target2,1'b1,valid1,tag1,target1};
                $display("BTB: hit in block 2");
                last_PC <= 0;
                last_missed <= 0;
            end else begin  /* cache miss */
                if (valid1 | valid2) begin
                    $display("BTB: PC tag: %x, tag1: %x, tag2: %x", tag_in, tag1, tag2);
                end
                Addr_OUT <= 0;
                Valid_OUT <= 1'b0;
                last_PC <= Instr_Addr_IN;
                last_missed <= 1'b1;
            end

            if (Valid_OUT) begin
                $display("BTB: valid entry %x (PC) => %x", Instr_Addr_IN, Addr_OUT);
            end else begin
                $display("BTB: no entry for %x (PC)", Instr_Addr_IN);
            end

        end else begin  /* not a branch */
            Addr_OUT <= 0;
            Valid_OUT <= 1'b0;
            last_PC <= 0;
            last_missed <= 1'b0;
        end
    end else begin
        Valid_OUT <= 1'b0;
        Addr_OUT <= 0;
    end
end

endmodule
