`define LOG_PHYS    $clog2(NUM_PHYS_REGS)
//-----------------------------------------
//           IssueQueue
//-----------------------------------------

module IssueQueue #(
    parameter NUM_PHYS_REGS = 64,
    parameter QUEUE_SIZE = 16
)
(
    input CLK,
    input RESET,
    input Enqueue_IN, // 0 = no new data to enqueue, 1 = enqueue
    input ReadyUpdate_IN, // 0 = no new register being ready, 1 = new ready register
    input [`LOG_PHYS - 1:0] ReadyRegister_IN, // Register address that becomes ready
    input reg [`ISSUE_QUEUE_ENTRY_BITS - 1 : 0] IssueQueueEntry_IN,
    input Dequeue_IN, // 0 = no need to dequeue, 1 = dequeue
    output DequeueResult_OUT, // 0 = no dequeue request or dequeue failed, 1 = dequeue succeeded
    output EnqueueResult_OUT, // 0 = no enqueue request or enqueue failed, 1 = enqueue succeeded
    output Full_OUT, // 0 = issue queue is not full, 1 = full
    output reg [`ISSUE_QUEUE_ENTRY_BITS - 1 : 0] IssueQueueEntry_OUT
);
    reg [`ISSUE_QUEUE_ENTRY_BITS - 1 : 0] queue [QUEUE_SIZE - 1 : 0];
    reg ready_bits [QUEUE_SIZE]
    reg [QUEUE_SIZE - 1 : 0] tail;
    reg [QUEUE_SIZE - 1 : 0] full;
    reg counter; // I'm not sure if it should be reg or wire
    reg [`ISSUE_QUEUE_ENTRY_BITS - 1:0] entry_selected;

    // Structure of issue queue entry
    wire stall;
    wire memread;
    wire memwrite;
    wire [`LOG_PHYS - 1:0] dest;
    wire regwrite;
    wire [4:0] shift;
    wire src2ready;
    wire [31:0] src2val;
    wire [`LOG_PHYS - 1:0] src2;
    wire src1ready;
    wire [31:0] src1val;
    wire [`LOG_PHYS - 1:0] src1;
    wire [5:0] op;


    initial begin
        tail = 0;
        full = 0;
        counter = 0;
        while (counter < QUEUE_SIZE) begin
            ready_bits[counter] = 0;
        end
    end

    always @(posedge CLK or negedge RESET) begin
        EnqueueResult_OUT = 0;
        DequeueResult_OUT = 0;
        if (!RESET) begin
            tail = 0;
            full = 0;
            counter = 0;
            while (counter < QUEUE_SIZE) begin
                ready_bits[counter] = 0;
            end
            $display("Issue Queue: RESET");
        end
        else
            // Update, dequeue, then enqueue to make sure that register ready bit is updated before select phase 
            // `define ISSUE_QUEUE_ENTRY_BITS (6 /* ALU op */ + `LOG_PHYS /* src1 reg */ + 32 /* src1 val */ + 1 /* src1 ready? */ + `LOG_PHYS /* src2 */ + 32 /* src2 val */ + 1 /* src2 ready? */ + 5 /* shift amount */ + 1 /* regwrite? */ +  `LOG_PHYS /* dest */ + 1 /* memwrite? */ + 1 /* memread? */ + 1 /* stall mem? */)
            
            // WAKE_UP
            if (ReadyUpdate_IN) begin
                counter = 0;
                while (counter != tail) begin
                    {op, src1, src1val, src1ready, src2, src2val, src2ready, shift, regwrite, dest, memwrite, memread, stall} = queue[counter];
                    if (src1 == ReadyRegister_IN) begin
                        src1ready = 1;
                    end
                    if (src2 == ReadyRegister_IN) begin
                        src2ready = 1;
                    end
                    if (src1 == 1 && src2 == 1) begin
                        ready_bits[counter] = 1;
                    end
                    counter = counter + 1;
                end
            end
            // TODO: Better select algorithm
            // SELECT
            if (Dequeue_IN) begin
                counter = 0;
                while (counter < tail && ready_bits[counter] != 1) begin
                    counter = (counter + 1) % QUEUE_SIZE;
                end
                if (counter != tail) begin
                    entry_selected = queue[counter];
                    while ((counter + 1) % QUEUE_SIZE < tail) begin
                        queue[counter] = queue[(counter + 1) % QUEUE_SIZE];
                        ready_bits[counter] = ready_bits[(counter + 1) % QUEUE_SIZE];
                    end
                    ready_bits[tail] = 0;
                    tail = tail - 1;
                    full = 0;
                    DequeueResult_OUT = 1;
                end
            end
            //ENQUEUE
            if (Enqueue_IN) begin
                if (!full) begin
                    queue[tail] = Data_IN;
                    tail = (tail + 1) % QUEUE_SIZE;
                    if (tail == QUEUE_SIZE) begin
                        full = 1;
                    end
                    EnqueueResult_OUT = 1;
                end
            end
            Full_OUT = full;
            
            
        end
    end
endmodule