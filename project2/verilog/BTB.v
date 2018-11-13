/************************
 * Branch Target Buffer
 * With 2-way set-associative cache.
 ************************/
module BTB(
    input CLK,
    input Resolution_IN,                    /* whether the last branch resolved */
    input [31:0] Branch_addr_IN,            /* the addr of the last branch */
    input [31:0] Branch_resolved_addr_IN,   /* where the last branch resolved to */
    input [31:0] Instr_Addr_IN,             /* current PC */
    input Is_Branch_IN,                     /* whether the current instruction is a branch */
    output reg [31:0] Addr_OUT,             /* new PC */
    output reg Valid_OUT                    /* whether the entry is valid */
);

/* (32 + 1 valid bit + 20-bit tag + 1 LRU bit) * 2-way = 108 bits */
reg[107:0] cache [1023:0];  // [107:54] = entry 1, [53:0] = entry 2

wire[9:0] idx;
wire[107:0] cache_set;
wire[19:0] tag_in;

wire valid1;
wire[19:0] tag1;
wire[31:0] target1;
wire valid2;
wire[19:0] tag2;
wire[31:0] target2;

assign idx = {Instr_Addr_IN[11:2]};
assign cache_set = cache[idx];
assign tag_in = {Instr_Addr_IN[31:12]};

assign valid1 = {cache_set[106]};
assign tag1 = {cache_set[105:86]};
assign target1 = {cache_set[85:54]};

assign valid2 = {cache_set[52]};
assign tag2 = {cache_set[51:32]};
assign target2 = {cache_set[31:0]};



wire[9:0] last_idx;
wire[107:0] last_cache_set;
wire[19:0] last_tag_in;

wire last_islru1;
wire last_valid1;
wire[19:0] last_tag1;
wire[31:0] last_target1;
wire last_islru2;
wire last_valid2;
wire[19:0] last_tag2;
wire[31:0] last_target2;

assign last_idx = {Branch_addr_IN[11:2]};
assign last_cache_set = cache[last_idx];
assign last_tag_in = {Branch_addr_IN[31:12]};

assign last_islru1 = {last_cache_set[107]};
assign last_valid1 = {last_cache_set[106]};
assign last_tag1 = {last_cache_set[105:86]};
assign last_target1 = {last_cache_set[85:54]};

assign last_islru2 = {last_cache_set[53]};
assign last_valid2 = {last_cache_set[52]};
assign last_tag2 = {last_cache_set[51:32]};
assign last_target2 = {last_cache_set[31:0]};

always @(posedge CLK) begin
    /* update the cache if we missed the last time */
    if (Resolution_IN && Branch_resolved_addr_IN != 0) begin
        /* find LRU */
        if (last_islru1) begin
            cache[last_idx] <= {1'b1,last_valid2,last_tag2,last_target2,1'b0,1'b1,last_tag_in,Branch_resolved_addr_IN};
        end else begin
            cache[last_idx] <= {1'b0,1'b1,last_tag_in,Branch_resolved_addr_IN,1'b1,last_valid1,last_tag1,last_target1};
        end
        $display("BTB: updating cache with %x => %x", Branch_addr_IN, Branch_resolved_addr_IN);
    end

    if (Is_Branch_IN) begin
        if (valid1 && tag_in == tag1) begin
            Addr_OUT = target1;
            Valid_OUT = 1'b1;
            cache[idx] = {1'b1,valid2,tag2,target2,1'b0,valid1,tag1,target1};
            $display("BTB: hit in block 1");
        end else if (valid2 && tag_in == tag2) begin
            Addr_OUT = target2;
            Valid_OUT = 1'b1;
            cache[idx] = {1'b0,valid2,tag2,target2,1'b1,valid1,tag1,target1};
            $display("BTB: hit in block 2");
        end else begin  /* cache miss */
            if (valid1 | valid2) begin
                $display("BTB: PC tag: %x, tag1: %x, tag2: %x", tag_in, tag1, tag2);
            end
            Addr_OUT = 0;
            Valid_OUT = 1'b0;
            $display("BTB: cache miss");
        end

        if (Addr_OUT != 0) begin
            $display("BTB: valid entry %x (PC) => %x", Instr_Addr_IN, Addr_OUT);
        end else begin
            $display("BTB: no entry for %x (PC)", Instr_Addr_IN);
        end
    end else begin  /* not a branch */
        Addr_OUT = 0;
        Valid_OUT = 1'b0;
        $display("BTB: current instr not a branch");
    end
end

endmodule
