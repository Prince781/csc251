module ICACHE
(
  input CLK,
  input RESET,
  input [31:0] Instr_address_2IC,
  input [255:0] block_read_fIC,
  input block_read_valid,
  output reg [31:0]   Instr1_OUT,
  output [1:0] valid
);

// Size (274) = valid bit (1) + tag(17) +  data (256)
reg [273:0] cache_table [1023:0];
wire [9:0] index;
wire [16:0] tag;
wire [4:0] offset;
wire [273:0] cache_line;
wire [31:0] cache_word;
reg [3:0] penalty;


always @(posedge CLK or negedge RESET) begin
  if (!RESET) begin
    integer i;
    for (i = 0; i < 1024; i++) begin
      cache_table[i] = 0;
    end
    $display("ICACHE: RESET: %x", Instr_address_2IC);
    penalty = 0;
  end
  else begin
    assign tag = Instr_address_2IC[31:15];
    assign index = Instr_address_2IC[14:5];
    assign offset = Instr_address_2IC[4:0];
    assign cache_line = cache_table[index];
    assign cache_word = cache_line[255- 8 * offset -: 32];
    if (penalty <= 1 && cache_line[273]  == 1 && tag == cache_line[272:256]) begin
      $display("Cache hit. Addr: %x", Instr_address_2IC);
      //Instr1_OUT = cache_word;
      if (penalty == 1) begin
        Instr1_OUT = cache_word;
        penalty = 0;
        valid = 1;
        $display("Cache hit finished loading. Addr: %x, Line: %274x, Word: %x", Instr_address_2IC, cache_line, cache_word);
      end
      else begin
        penalty = 1;
        valid = 0;
      end
    end
    else begin
      $display("Cache miss. Addr: %x", Instr_address_2IC);
      if (block_read_valid) begin
        cache_table[index] = block_read_fIC;
        cache_table[index][272:256] = tag;
        cache_table[index][273] = 1;
      end
      if (penalty >= 10) begin
        // Actual memory operation

        assign cache_line = cache_table[index];
        assign cache_word = cache_line[255- 8 * offset -: 32];

        Instr1_OUT = cache_word;
        penalty = 0;
        valid = 1;
        $display("Cache miss finished loading. Addr: %x, Line: %274x, Word: %x", Instr_address_2IC, cache_line, cache_word);
      end
      else begin
        penalty = penalty + 1;
        valid = 0;
      end
    end
  end
end

endmodule
