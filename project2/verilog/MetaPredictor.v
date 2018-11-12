`include "config.v"
module MetaPredictor(
    input CLK,
    input RESET,
    input      [31: 0] Instr_input,	 // instruction
    input      [31: 0] Instr_addr_input, // Inst Address
    input      Branch_resolved,
    input      Branch_resolved_addr,
    output Use_global // main output of module - whether we use global or local
    // 1 = global
    // 0 = local
    );

    reg [1:0] fsm [1023:0]; // Branch History Table

    always @(Instr_input) begin // Do prediction
        $display("Hybrid: Meta Predictor: %x", Instr_addr_input);
        case(Instr_input[31:26])
            6'b000001:begin
                case(Instr_input[20:16])
                    5'b00000,5'b10000:Use_global=fsm[Instr_addr_input[11:2]][1];		  	//BLTZ,BLTZAL // appears correct
                    5'b00001,5'b10001:Use_global=fsm[Instr_addr_input[11:2]][1];	//BGEZ,BGEZAL // appears correct
                    default: Use_global=1'b1; // not actually branching
                endcase
            end
            6'b000100:Use_global=fsm[Instr_addr_input[11:2]][1];						//BEQ //ops look correct
            6'b000101:Use_global=fsm[Instr_addr_input[11:2]][1];						//BNE // ops look correct
            6'b000110:Use_global=fsm[Instr_addr_input[11:2]][1];				//BLEZ // ops look correct
            6'b000111: begin
                Use_global=fsm[Instr_addr_input[11:2]][1];			//BGTZ  // ops look correct
            end
            default:Use_global=1'b1; // default, don't branch
        endcase
    end

    always @(Branch_resolved) begin // Update predictor
        $display("Hybrid: Meta Predictor: %x", Instr_addr_input);
        if (Branch_resolved_addr != 0) begin
            if (Branch_resolved) begin
                case(bht[Branch_resolved_addr[11:2]])
                    2'b11:fsm[Branch_resolved_addr[11:2]] = fsm[Branch_resolved_addr[11:2]];
                    default: fsm[Branch_resolved_addr[11:2]]++;
                endcase

            end
            else
                case(fsm[Branch_resolved_addr[11:2]])
                    2'b00:fsm[Branch_resolved_addr[11:2]] = fsm[Branch_resolved_addr[11:2]];
                    default: fsm[Branch_resolved_addr[11:2]]--;
                endcase

            end
        end
    end
endmodule
