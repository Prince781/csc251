`include "config.v"
/**************************************
* Module: Fetch
* Date:2013-11-24  
* Author: isaac     
*
* Description: Master Instruction Fetch Module
***************************************/
module  IF
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
    //Will be set to true if we need to just freeze the fetch stage.
    input STALL,
    
    //There was probably a branch -- please load the alternate PC instead of Instr_PC_Plus4.
    input Request_Alt_PC_MEM,
    input Request_Alt_PC_BP,
    //Alternate PC to load
    input [31:0] Alt_PC_MEM, 
    input [31:0] Alt_PC_BP,
    //Address from which we want to fetch an instruction
    output [31:0] Instr_address_2IM,
    //Instruction received from instruction memory
    input [31:0]   Instr1_fIM
);

    wire Request_Alt_PC;
    wire [31:0] Alt_PC;

    assign Request_Alt_PC = Request_Alt_PC_MEM | Request_Alt_PC_BP;
    assign Alt_PC = (Request_Alt_PC_MEM) ? Alt_PC_MEM : (Request_Alt_PC_BP ? Alt_PC_BP : 32'd0);

    wire [31:0] IncrementAmount;
    assign IncrementAmount = 32'd4; //NB: This might get modified for superscalar.
    
`ifdef INCLUDE_IF_CONTENT
    assign Instr_address_2IM = (Request_Alt_PC)?Alt_PC:Instr_PC_Plus4;
`else
    assign Instr_address_2IM = Instr_PC_Plus4;  //Are you sure that this is correct?
`endif

always @(posedge CLK or negedge RESET) begin
    if(!RESET) begin
        Instr1_OUT <= 0;
        Instr_PC_OUT <= 0;
        Instr_PC_Plus4 <= 32'hBFC00000;
        $display("FETCH [RESET] Fetching @%x", Instr_PC_Plus4);
    end if (!RESET && Request_Alt_PC) begin
        Instr_PC_Plus4 <= Alt_PC+IncrementAmount;   
    end else if(CLK) begin
        if(!STALL && !Request_Alt_PC_BP) begin
                Instr1_OUT  <= Instr1_fIM;
                Instr_PC_OUT<= Instr_address_2IM;
                $display("FETCH:ReqAlt=%d",Request_Alt_PC);
`ifdef INCLUDE_IF_CONTENT
                Instr_PC_Plus4 <= Instr_address_2IM + IncrementAmount;
                $display("FETCH:Instr@%x=%x;Next@%x",Instr_address_2IM,Instr1_fIM,Instr_address_2IM + IncrementAmount);
                $display("FETCH:ReqAlt[%d]=%x",Request_Alt_PC,Alt_PC);
`else
                /* You should probably assign something to Instr_PC_Plus4. */
                $display("FETCH:Instr@%x=%x;Next@%x",Instr_address_2IM,Instr1_fIM,Instr_address_2IM + IncrementAmount);
                $display("FETCH:ReqAlt[%d]=%x",Request_Alt_PC,Alt_PC);
`endif
        end else begin
            if (FLUSH) begin
                $display("FETCH [FLUSH]: Alt_PC = %x", Alt_PC);
            end else if (Request_Alt_PC_BP) begin
                $display("FETCH [BP-FLUSH]: Alt_PC = %x", Alt_PC);
            end
            if (FLUSH || Request_Alt_PC_BP) begin
                Instr_PC_Plus4 <= Alt_PC;
                Instr1_OUT <= 0;
            end
            $display("FETCH: Stalling; next request will be %x",Instr_address_2IM);
        end
    end
end

endmodule
