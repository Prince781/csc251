`include "config.v"
module GlobalPredictor(
    input CLK,
    input RESET,
    input      [31: 0] Instr_input,	 // instruction
    input      [31: 0] Instr_addr_input, // Inst Address
    input      Branch_resolved,
    input      [31: 0] Branch_addr_IN,
    output Taken // main output of module - whether we jump/branch or not
    // 1 if branch
    // 0 if not
);

    reg [11:0] ghr; // Global History Register
    reg [1:0] pht [4095:0]; // 12 bit Global History Register needs 2^12 = 4096 entries

    always @(posedge CLK or negedge RESET) begin
        // Do prediction
        case(Instr_input[31:26])
            6'b000001:begin
                case(Instr_input[20:16])
                    5'b00000,5'b10000:Taken<=pht[ghr][1];		  	//BLTZ,BLTZAL // appears correct
                    5'b00001,5'b10001:Taken<=pht[ghr][1];	//BGEZ,BGEZAL // appears correct
                    default: Taken<=1'b0; // not actually branching
                endcase
            end
            6'b000100:Taken<=pht[ghr][1];						//BEQ //ops look correct
            6'b000101:Taken<=pht[ghr][1];						//BNE // ops look correct
            6'b000110:Taken<=pht[ghr][1];				//BLEZ // ops look correct
            6'b000111: begin
                Taken<=pht[ghr][1];			//BGTZ  // ops look correct
            end
            default:Taken<=1'b0; // default, don't branch
        endcase
        // Update predictor
        $display("Hybrid: Global Predictor: %x Taken? %x", Instr_addr_input, Taken);
        if (Branch_addr_IN != 0) begin
            if (Branch_resolved) begin
                case(pht[ghr])
                    2'b11: begin
                        pht[ghr] = pht[ghr];
                        $display("Hybrid: Global Predictor: no change");
                    end
                    default: begin
                        pht[ghr]++;
                        $display("Hybrid: Global Predictor: saturating up");
                    end
                endcase
            end
            else begin
                case(pht[ghr])
                    2'b00: begin
                        pht[ghr] = pht[ghr];
                        $display("Hybrid: Global Predictor: no change");
                    end
                    default: begin
                        pht[ghr]--;
                        $display("Hybrid: Global Predictor: saturating down");
                    end
                endcase
            end
            assign ghr = {ghr[10:0], Branch_resolved};
            $display("Hybrid: Global Predictor: updating history to %b", ghr);
        end
    end
endmodule
