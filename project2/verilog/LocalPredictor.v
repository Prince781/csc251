`include "config.v"
module LocalPredictor(
    input CLK,
    input RESET,
    input      [31: 0] Instr_input,	 // instruction
    input      [31: 0] Instr_addr_input, // Inst Address
    input      Branch_resolved,
    input      [31: 0] Branch_resolved_addr,
    output Taken // main output of module - whether we jump/branch or not
    // 1 if branch
    // 0 if not
    );

    reg [9:0] bht [1023:0]; // Branch History Table
    reg [1:0] pht [1023:0]; // 10 bit Branch History Register needs 2^10 = 1024 entries

    always @(posedge CLK or negedge RESET) begin
        if (!RESET) begin
            Taken <= 0;
            $display("Hybrid: Local Predictor [RESET]");
        end else if (CLK) begin
            // Do prediction
            case(Instr_input[31:26])
                6'b000001:begin
                    case(Instr_input[20:16])
                        5'b00000,5'b10000:Taken<=pht[bht[Instr_addr_input[11:2]]][1];		  	//BLTZ,BLTZAL // appears correct
                        5'b00001,5'b10001:Taken<=pht[bht[Instr_addr_input[11:2]]][1];	//BGEZ,BGEZAL // appears correct
                        default: Taken<=1'b0; // not actually branching
                    endcase
                end
                6'b000100:Taken<=pht[bht[Instr_addr_input[11:2]]][1];						//BEQ //ops look correct
                6'b000101:Taken<=pht[bht[Instr_addr_input[11:2]]][1];						//BNE // ops look correct
                6'b000110:Taken<=pht[bht[Instr_addr_input[11:2]]][1];				//BLEZ // ops look correct
                6'b000111: begin
                    Taken<=pht[bht[Instr_addr_input[11:2]]][1];			//BGTZ  // ops look correct
                end
                default:Taken<=1'b0; // default, don't branch
            endcase
            // Update predictor
            $display("Hybrid: Local Predictor: %x", Instr_addr_input);
            if (Branch_resolved_addr != 0) begin
                if (Branch_resolved) begin
                    case(pht[bht[Branch_resolved_addr[11:2]]])
                        2'b11:pht[bht[Branch_resolved_addr[11:2]]] = pht[bht[Branch_resolved_addr[11:2]]];
                        default: pht[bht[Branch_resolved_addr[11:2]]]++;
                    endcase
                    assign bht[Branch_resolved_addr[11:2]] = bht[Branch_resolved_addr[11:2]] << 1 + Branch_resolved;
                end
                else begin
                    case(pht[bht[Branch_resolved_addr[11:2]]])
                        2'b00:pht[bht[Branch_resolved_addr[11:2]]] = pht[bht[Branch_resolved_addr[11:2]]];
                        default: pht[bht[Branch_resolved_addr[11:2]]]--;
                    endcase
                    assign bht[Branch_resolved_addr[11:2]] = bht[Branch_resolved_addr[11:2]] << 1 + Branch_resolved;
                end
            end
        end
    end
endmodule
