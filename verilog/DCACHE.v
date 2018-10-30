module DCACHE
(
  input CLK,
  input RESET,
  input [31:0] Data_address_read,
  input [31:0] Data_address_write,
  input [1:0] Mem_read, //  0 = no read, 1 = has read
  input [1:0] Mem_write, // 0 = no write, 1 = has write
  input [31:0] Write_data,
  input [255:0] block_read_fIC,
  input block_read_valid,
  input Dcache_flush,
  output reg [31:0]   Data_read,
  output reg [255:0] Block_write,
  output [31:0] Data_address_OUT,
  output [1:0] valid
);

// Size (276) = dirty bit (1) + valid bit (1) + recently used bit (1) + tag(17) +  data (256)
reg [275:0] cache_table_set1 [511:0];
reg [275:0] cache_table_set2 [511:0];
wire [9:0] index;
wire [16:0] tag;
wire [4:0] offset;
wire [274:0] cache_line_set1;
wire [274:0] cache_line_set2;
wire [31:0] cache_word;
reg [3:0] penalty;


always @(posedge CLK or negedge RESET) begin
  if (!RESET) begin
    integer i;
    for (i = 0; i < 512; i++) begin
      cache_table_set1[i] = 0;
      cache_table_set2[i] = 0;
    end
    $display("DCACHE: RESET");
    penalty = 0;
  end
  else if (Dcache_flush) begin
    integer i;
    for (i = 0; i < 512; i++) begin
      cache_table_set1[i] = 0;
      cache_table_set2[i] = 0;
    end
    $display("DCACHE: FLUSH");
    penalty = 0;
  end
  else begin
    if (Mem_read == 1) begin
      assign tag = Data_address_read[31:14];
      assign index = Data_address_read[13:5];
      assign offset = Data_address_read[4:0];
      assign cache_line_set1 = cache_table_set1[index];
      assign cache_line_set2 = cache_table_set2[index];
      assign cache_word_set1 = cache_line_set1[255- 8 * offset -: 32];
      assign cache_word_set2 = cache_line_set2[255- 8 * offset -: 32];
      if (penalty <= 1 && cache_line[274]  == 1 && penalty == 0 && (tag == cache_line_set1[272:256] || tag == cache_line_set2[272:256])) begin
        $display("dCache hit. Addr: %x", Data_address_read);
        if (tag == cache_line_set1[272:256]) begin
          Instr1_OUT = cache_word_set1;
          cache_line_set1[273] = 1;
          cache_line_set2[273] = 0;
        end
        else begin
          Instr1_OUT = cache_word_set2;
          cache_line_set2[273] = 1;
          cache_line_set1[273] = 0;
        end
        penalty = 0;
        valid = 1;
        $display("dCache hit finished loading. Addr: %x, Line: %274x, Word: %x", Data_address_2IC, cache_line, cache_word);

      end
      else begin
        $display("dCache miss. Addr: %x", Data_address_read);
        if (block_read_valid) begin
          if (cache_table_set1[index][273] == 0) begin
            if (cache_table_set1[index][275] == 1) begin
              // TODO: Verify if this is enough for writeback
              Block_write = cache_table_set1[index];
              Data_address_OUT = Data_address_write & 32'hFFFFFFE0;
            end
            cache_table_set1[index] = block_read_fIC;
            cache_table_set1[index][272:256] = tag;
            cache_table_set1[index][273] = 1;
            cache_table_set1[index][274] = 1;
          end
          else begin
            if (cache_table_set2[index][275] == 1) begin
              // TODO: Verify if this is enough for writeback
              Block_write = cache_table_set2[index];
              Data_address_OUT = Data_address_write & 32'hFFFFFFE0;
            end
            cache_table_set2[index] = block_read_fIC;
            cache_table_set2[index][272:256] = tag;
            cache_table_set2[index][273] = 1;
            cache_table_set2[index][274] = 1;
          end
        end
        if (penalty >= 10) begin
          // Actual memory operation

          assign cache_line = cache_table_set1[index];
          assign cache_word = cache_line[255- 8 * offset -: 32];

          Instr1_OUT = cache_word;
          penalty = 0;
          valid = 1;
          $display("dCache miss finished loading. Addr: %x, Line: %274x, Word: %x", Data_address_2IC, cache_line, cache_word);
        end
        if (penalty == 0) begin
          Data_address_OUT = Data_address_read & 32'hFFFFFFE0;
        end
        else begin
          penalty = penalty + 1;
          valid = 0;
        end
      end
    end
    if (Mem_write == 1) begin
      assign tag = Data_address_write[31:14];
      assign index = Data_address_write[13:5];
      assign offset = Data_address_write[4:0];
      assign cache_line_set1 = cache_table_set1[index];
      assign cache_line_set2 = cache_table_set2[index];
      assign cache_word_set1 = cache_line_set1[255- 8 * offset -: 32];
      assign cache_word_set2 = cache_line_set2[255- 8 * offset -: 32];
      if (penalty <= 1 && cache_line[274]  == 1 && penalty == 0 && (tag == cache_line_set1[272:256] || tag == cache_line_set2[272:256])) begin
        $display("dCache hit. Addr: %x", Data_address_write);
        if (tag == cache_line_set1[272:256]) begin
          //Instr1_OUT = cache_word_set1;
          cache_word_set1 = Write_data;
          cache_line_set1[275] = 1;
          cache_line_set1[273] = 1;
          cache_line_set2[273] = 0;
        end
        else begin
          cache_word_set2 = Write_data;
          cache_line_set2[275] = 1;
          cache_line_set2[273] = 1;
          cache_line_set1[273] = 0;
        end
        penalty = 0;
        valid = 1;
        $display("dCache hit finished writing. Addr: %x, Line: %274x, Word: %x", Data_address_2IC, cache_line, cache_word);

      end
      else begin
        $display("dCache miss. Addr: %x", Data_address_write);
        if (block_read_valid) begin
          if (cache_table_set1[index][273] == 0) begin
            if (cache_table_set1[index][275] == 1) begin
              // TODO: Verify that this is enough for writeback
              Block_write = cache_table_set1[index];
              Data_address_OUT = Data_address_write & 32'hFFFFFFE0;
            end
            cache_table_set1[index] = block_read_fIC;
            cache_table_set1[index][255- 8 * offset -: 32] = Write_data;
            cache_table_set1[index][272:256] = tag;
            cache_table_set1[index][273] = 1;
            cache_table_set1[index][274] = 1;
            cache_table_set1[index][275] = 1;
          end
          else begin
            if (cache_table_set2[index][275] == 1) begin
              // TODO: Verify that this is enough for writeback
              Block_write = cache_table_set1[index];
              Data_address_OUT = Data_address_write & 32'hFFFFFFE0;
            end
            cache_table_set2[index] = block_read_fIC;
            cache_table_set2[index][255- 8 * offset -: 32] = Write_data;
            cache_table_set2[index][272:256] = tag;
            cache_table_set2[index][273] = 1;
            cache_table_set2[index][274] = 1;
            cache_table_set2[index][275] = 1;
          end
        end
        if (penalty >= 10) begin
          penalty = 0;
          valid = 1;
          $display("dCache miss finished loading. Addr: %x, Line: %274x, Word: %x", Data_address_2IC, cache_line, cache_word);
        end
        if (penalty == 0) begin
          Data_address_OUT = Data_address_read & 32'hFFFFFFE0;
        else begin
          penalty = penalty + 1;
          valid = 0;
        end
      end
    end
  end
end

endmodule
