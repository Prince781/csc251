module DCACHE
(
  input CLK,
  input RESET,
  input [31:0] Data_address_read,
  input [31:0] Data_address_write,
  input [1:0] Mem_read, //  0 = no read, 1 = has read
  input [1:0] Mem_write, // 0 = no write, 1 = has write
  input [31:0] Write_data,
  input [1:0] Write_size,
  input [255:0]  block_read_fDC,
  input block_read_valid,
  input block_write_valid,
  input Dcache_flush,
  output reg [31:0]   Data_read,
  output reg [255:0] Block_write,
  output [31:0] Data_address_OUT,
  output [1:0] valid
);

// Size (276) = dirty bit (1) + valid bit (1) + recently used bit (1) + tag(17) +  data (256)
// The 2-way associative cache is represented by two arrays each with size of 512 blocks
reg [275:0] cache_table_set1 [511:0];
reg [275:0] cache_table_set2 [511:0];
reg flushing; // Are we in the process of flushing?
reg flushing_ent; // Current block being flushed
reg flushing_set; // Current set being flushed
wire [9:0] index;
wire [16:0] tag;
wire [4:0] offset;
wire [274:0] cache_line_set1;
wire [274:0] cache_line_set2;
wire [31:0] cache_word_set1;
wire [31:0] cache_word_set2;
reg [3:0] penalty; // Miss penalty counter


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
  // Flush the cache
  else if (Dcache_flush || flushing) begin
    flushing = 1;
    // Write back each dirty block of the cache, one at a time
    if (flushing_ent < 512) begin
        if(flushing_set == 0) begin
          // only write back if the block is dirty
          if (cache_table_set1[flushing_ent][275] == 1) begin
            Block_write = cache_table_set1[flushing_ent][255:0];
            Data_address_OUT = {cache_table_set1[flushing_ent][272:256], index, 5'b00000};
            flushing_set = 1;
          end
        end
        else begin
          if (cache_table_set1[flushing_ent][275] == 1) begin
            Block_write = cache_table_set2[flushing_ent][255:0];
            Data_address_OUT = {cache_table_set2[flushing_ent][272:256], index, 5'b00000};
            flushing_set = 0;
            flushing_ent = flushing_ent + 1;
          end
        end
    end
    else begin // Invalidate all blocks
      integer i;
      for (i = 0; i < 512; i++) begin
        cache_table_set1[i] = 0;
        cache_table_set2[i] = 0;
      end
      $display("DCACHE: FLUSH");
      // Reset all counters
      penalty = 0;
      flushing_ent = 0;
      flushing_set = 0;
      flushing = 0;
    end
  end
  else begin
    // If there is no read or write request from MEM, there is no need to
    // wait, and therefore valid is true
    if (Mem_read == 0 && Mem_write == 0) begin
      valid = 1;
    end
    // If the request is load
    if (Mem_read == 1) begin
      assign tag = Data_address_read[31:14];
      assign index = Data_address_read[13:5];
      assign offset = Data_address_read[4:0];
      assign cache_line_set1 = cache_table_set1[index];
      assign cache_line_set2 = cache_table_set2[index];
      assign cache_word_set1 = cache_line_set1[255- 8 * offset -: 32];
      assign cache_word_set2 = cache_line_set2[255- 8 * offset -: 32];
      // Check if requested data is in the cache
      if (penalty <= 1 && (cache_line_set1[274]  == 1 || cache_line_set2[274] == 1)&& penalty == 0 && (tag == cache_line_set1[272:256] || tag == cache_line_set2[272:256])) begin
        $display("dCache hit. Addr: %x", Data_address_read);
        // Find it from the two sets.
        if (tag == cache_line_set1[272:256]) begin
          Data_read = cache_word_set1;
          cache_line_set1[273] = 1;
          cache_line_set2[273] = 0;
        end
        else begin
          Data_read = cache_word_set2;
          cache_line_set2[273] = 1;
          cache_line_set1[273] = 0;
        end
        penalty = 0;
        valid = 1;
        $display("dCache hit finished loading. ");
      end
      else begin
        $display("dCache miss. Addr: %x", Data_address_read);
        if (block_read_valid) begin
          // Evict the Least Recently Used (LRU) cache block of the two blocks
          // in corresponding set.
          if (cache_table_set1[index][273] == 0) begin
            // If the block is dirty, write back to memory
            if (cache_table_set1[index][275] == 1) begin
              Block_write = cache_table_set1[index][255:0];
              Data_address_OUT = {cache_table_set1[index][272:256], index, 5'b00000};
            end
            // Replace the block
            cache_table_set1[index] =  block_read_fDC;
            cache_table_set1[index][272:256] = tag;
            cache_table_set1[index][273] = 1;
            cache_table_set1[index][274] = 1;
          end
          else begin
            if (cache_table_set2[index][275] == 1) begin
              Block_write = cache_table_set2[index][255:0];
              Data_address_OUT = {cache_table_set1[index][272:256], index, 5'b00000};
            end
            cache_table_set2[index] =  block_read_fDC;
            cache_table_set2[index][272:256] = tag;
            cache_table_set2[index][273] = 1;
            cache_table_set2[index][274] = 1;
          end
        end
        // If the 10 cycles of miss penalty is done, get loaded data
        if (penalty >= 10) begin
          if (tag == cache_line_set1[272:256]) begin
            Data_read = cache_word_set1;
            cache_line_set1[273] = 1;
            cache_line_set2[273] = 0;
          end
          else begin
            Data_read = cache_word_set2;
            cache_line_set2[273] = 1;
            cache_line_set1[273] = 0;
          end
          penalty = 0;
          valid = 1;
          $display("dCache miss finished loading.");
        end
        // Align the address being read in order to read the block
        if (penalty == 0) begin
          Data_address_OUT = Data_address_read & 32'hFFFFFFE0;
        end
        else begin
          penalty = penalty + 1;
          valid = 0;
        end
      end
    end
    // If the request is a store
    if (Mem_write == 1) begin
      assign tag = Data_address_write[31:14];
      assign index = Data_address_write[13:5];
      assign offset = Data_address_write[4:0];
      assign cache_line_set1 = cache_table_set1[index];
      assign cache_line_set2 = cache_table_set2[index];
      assign cache_word_set1 = cache_line_set1[255- 8 * offset -: 32];
      assign cache_word_set2 = cache_line_set2[255- 8 * offset -: 32];
      if (penalty <= 1 && (cache_line_set1[274]  == 1 || cache_line_set2[274] == 1) && penalty == 0 && (tag == cache_line_set1[272:256] || tag == cache_line_set2[272:256])) begin
        $display("dCache hit. Addr: %x", Data_address_write);
        if (tag == cache_line_set1[272:256]) begin
          // Write_size: 0 = entire word, 1 = a byte, 2 = half word, 3 = 0.75 word
          case (Write_size)
            0:  cache_word_set1 = Write_data;
            1:  cache_word_set1[7:0] = Write_data;
            2:  cache_word_set1[15:0] = Write_data;
            3:  cache_word_set1[23:0] = Write_data;
          endcase
          // The block is dirty and recently used
          cache_line_set1[275] = 1;
          cache_line_set1[273] = 1;
          // The corresponding block of the other set is therefore not recently used.
          cache_line_set2[273] = 0;
        end
        else begin
          case (Write_size)
            0:  cache_word_set2 = Write_data;
            1:  cache_word_set2[7:0] = Write_data;
            2:  cache_word_set2[15:0] = Write_data;
            3:  cache_word_set2[23:0] = Write_data;
          endcase
          //cache_word_set2 = Write_data;
          cache_line_set2[275] = 1;
          cache_line_set2[273] = 1;
          cache_line_set1[273] = 0;
        end
        penalty = 0;
        valid = 1;
        $display("dCache hit finished writing.");

      end
      else begin
        $display("dCache miss. Addr: %x", Data_address_write);
        // Replace cache block
        if (block_read_valid) begin
          if (cache_table_set1[index][273] == 0) begin
            // Write back original block if it's dirty
            if (cache_table_set1[index][275] == 1) begin
              Block_write = cache_table_set1[index][255:0];
              Data_address_OUT = {cache_table_set1[index][272:256], index, 5'b00000};
            end
            cache_table_set1[index] =  block_read_fDC;
            case (Write_size)
              0:  cache_table_set1[index][255- 8 * offset -: 32] = Write_data;
              1:  cache_table_set1[index][255- 8 * offset -: 32][7:0] = Write_data;
              2:  cache_table_set1[index][255- 8 * offset -: 32][15:0] = Write_data;
              3:  cache_table_set1[index][255- 8 * offset -: 32][23:0] = Write_data;
            endcase
            cache_table_set1[index][272:256] = tag;
            cache_table_set1[index][273] = 1;
            cache_table_set1[index][274] = 1;
            cache_table_set1[index][275] = 1;
          end
          else begin
            if (cache_table_set2[index][275] == 1) begin
              Block_write = cache_table_set1[index][255:0];
              Data_address_OUT = {cache_table_set1[index][272:256], index, 5'b00000};
            end
            cache_table_set2[index] =  block_read_fDC;
            case (Write_size)
              0:  cache_table_set2[index][255- 8 * offset -: 32] = Write_data;
              1:  cache_table_set2[index][255- 8 * offset -: 32][7:0] = Write_data;
              2:  cache_table_set2[index][255- 8 * offset -: 32][15:0] = Write_data;
              3:  cache_table_set2[index][255- 8 * offset -: 32][23:0] = Write_data;
            endcase
            cache_table_set2[index][272:256] = tag;
            cache_table_set2[index][273] = 1;
            cache_table_set2[index][274] = 1;
            cache_table_set2[index][275] = 1;
          end
        end
        if (penalty >= 10) begin
          penalty = 0;
          valid = 1;
          $display("dCache miss finished loading.");
        end
        if (penalty == 0) begin
          Data_address_OUT = Data_address_write & 32'hFFFFFFE0;
        end else begin
          penalty = penalty + 1;
          valid = 0;
        end
      end
    end
  end
end

endmodule