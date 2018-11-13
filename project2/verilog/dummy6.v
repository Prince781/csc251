`include "config.v"
/**************************************
* Module: dummy6
* Date:2018-10-24
* Author: uday
*
* Description: Master Instruction dummy6 Module
***************************************/
module  dummy6
(
    input CLK,
    input RESET,
    input FLUSH,
    //This should contain the fetched instruction
    output reg [31:0] Instr1_OUT,
    //This should contain the address of the fetched instruction [DEBUG purposes]
    output reg [31:0] Instr_PC_OUT,
    //This should contain the address of the instruction after the fetched instruction (used by ID)
    output reg [31:0] Instr_PC_Plus4,
    output reg [31:0] Instr_pc_IF_stall,
    output reg Branch_prediction_OUT,
    output reg [1:0] Branch_predictions_OUT,
    //Will be set to true if we need to just freeze the fetch stage.
    input STALL,
    //Address from which we want to fetch an instruction
    //Instruction received from IF
    input [31:0]   Instr1_IF,
    input [31:0]   Instr_PC_IF,
    input [31:0]   Instr_PC_Plus4_IF,
    input Branch_prediction_IN,
    input [1:0] Branch_predictions_IN
);
always @(posedge CLK or negedge RESET) begin
    if(!RESET || FLUSH) begin
        Instr1_OUT <= 0;
        Instr_PC_OUT <= 0;
        Instr_PC_Plus4 <= 0;
        Branch_prediction_OUT <= 0;
        Branch_predictions_OUT <= 0;
        $display(" DUMMY6 [RESET]");
    end else if(CLK) begin
        if(!STALL) begin
                Instr1_OUT <= Instr1_IF;
                Instr_PC_OUT <= Instr_PC_IF;
                Instr_PC_Plus4 <= Instr_PC_Plus4_IF;
                Branch_prediction_OUT <= Branch_prediction_IN;
                Branch_predictions_OUT <= Branch_predictions_IN;
                $display("Dummy6:Instr@%x=%x;Next@%x",Instr_PC_IF,Instr1_IF,Instr_PC_Plus4_IF);
        end else begin
            Instr_pc_IF_stall <= Instr_PC_IF;
            $display("Dummy6 stalling:Instr@%x=%x;Next@%x",Instr_PC_IF,Instr1_IF,Instr_PC_Plus4_IF);
        end
    end
end
endmodule
