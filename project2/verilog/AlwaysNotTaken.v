`include "config.v"
//-----------------------------------------
//           Quick Compare
//-----------------------------------------
module AlwaysNotTaken(
    input CLK,
    input RESET,
    input      [31: 0] Instr_input,	 // instruction
    input      [31: 0] Instr_addr_input, // Inst Address
    input      Branch_resolved,
    input      Branch_resolved_addr,
    output Taken // main output of module - whether we jump/branch or not
    // 1 if branch
    // 0 if not
    );

    always @(Instr_input) begin
        $display("AlwaysNotTaken: %x not taken", Instr_addr_input);
        case(Instr_input[31:26])
            6'b000001:begin
                case(Instr_input[20:16])
                    5'b00000,5'b10000:Taken=1'b0;		  	//BLTZ,BLTZAL // appears correct
                    5'b00001,5'b10001:Taken=1'b0;	//BGEZ,BGEZAL // appears correct
                    default: Taken=1'b0; // not actually branching
                endcase
            end
            6'b000100:Taken=1'b0;						//BEQ //ops look correct
            6'b000101:Taken=1'b0;						//BNE // ops look correct
            6'b000110:Taken=1'b0;				//BLEZ // ops look correct
            6'b000111: begin
                Taken=1'b0;			//BGTZ  // ops look correct
            end
            default:Taken=1'b0; // default, don't branch
        endcase
    end
endmodule
