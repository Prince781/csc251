`define LOG_PHYS    $clog2(NUM_PHYS_REGS)
`define LOG_SIZE    $clog2(QUEUE_SIZE)
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
    reg [`ISSUE_QUEUE_ENTRY_BITS - 1 : 0] queue [QUEUE_SIZE : 0];
    reg ready_bits [QUEUE_SIZE];
    reg [`LOG_SIZE: 0] tail;
    reg full;
    reg [`ISSUE_QUEUE_ENTRY_BITS - 1:0] entry_selected;

    // Structure of issue queue entry
    wire memread;
    wire memwrite;
    wire [`LOG_PHYS - 1:0] dest;
    wire regwrite;
    wire [4:0] shift;
    wire src2ready;
    wire [`LOG_PHYS - 1:0] src2;
    wire src1ready;
    wire [`LOG_PHYS - 1:0] src1;
    wire [31:0] immediate;
    wire has_immediate;
    wire [5:0] op;

    reg initialized;

    initial begin
        initialized = 0;
    end

    integer i;

    assign IssueQueueEntry_OUT = entry_selected;


    always @(posedge CLK or negedge RESET) begin
        EnqueueResult_OUT <= 0;
        DequeueResult_OUT <= 0;
        if (!RESET || !initialized) begin
            tail <= 0;
            full <= 0;
            for (i = 0; i <= QUEUE_SIZE; i = i + 1) begin
               queue[i] <= i;
            end
            if (!initialized) begin
                $display("Issue Queue: initializing");
                initialized <= 1;
            end else begin
                $display("Issue Queue: RESET");
            end
        end
        else begin
            // Update, dequeue, then enqueue to make sure that register ready bit is updated before select phase
            //`define ISSUE_QUEUE_ENTRY_BITS (6 /* ALU op */ + 1 /* has immediate? */ + 32 /* immediate */ + `PROJ_LOG_PHYS /* src1 reg */ + 1 /* src1 ready? */ + `PROJ_LOG_PHYS /* src2 */ + 1 /* src2 ready? */ + 5 /* shift amount */ + 1 /* regwrite? */ +  `PROJ_LOG_PHYS /* dest */ + 1 /* memwrite? */ + 1 /* memread? */)
            // WAKE_UP
            if (ReadyUpdate_IN) begin
                for (i = 0; i != tail; i = i + 1) begin
                    {op, has_immediate, immediate, src1, src1ready, src2, src2ready, shift, regwrite, dest, memwrite, memread} <= queue[i];
                    if (src1 == ReadyRegister_IN) begin
                        src1ready <= 1;
                    end
                    if (src2 == ReadyRegister_IN) begin
                        src2ready <= 1;
                    end
                    if (src1 == 1 && src2 == 1) begin
                        ready_bits[i] = 1;
                    end
                end
                $display("Issue Queue: Wake up Reg:%d", ReadyRegister_IN);
            end
            // TODO: Better select algorithm
            // SELECT
            if (Dequeue_IN) begin
                for (i = 0; i < tail && ready_bits[i] != 1; i = (i + 1) % QUEUE_SIZE) begin
                end
                if (i != tail) begin
                    entry_selected <= queue[i];
                    while ((i + 1) % QUEUE_SIZE < tail) begin
                        queue[i] = queue[(i + 1) % QUEUE_SIZE];
                        ready_bits[i] = ready_bits[(i + 1) % QUEUE_SIZE];
                    end
                    ready_bits[tail[`LOG_SIZE - 1:0]] <= 0;
                    tail <= tail - 1;
                    full <= 0;
                    DequeueResult_OUT <= 1;
                    $display("Issue Queue: Select entry %x", entry_selected);
                end
            end
            //ENQUEUE
            if (Enqueue_IN) begin
                if (!full) begin
                    queue[tail] <= IssueQueueEntry_IN;
                    tail <= (tail + 1) % QUEUE_SIZE;
                    if ((tail+1) == QUEUE_SIZE) begin
                        full <= 1;
                    end
                    EnqueueResult_OUT <= 1;
                    $display("Issue Queue: Enqueue entry %x", IssueQueueEntry_IN);
                end
            end
            Full_OUT <= full;


        end
    end
endmodule
