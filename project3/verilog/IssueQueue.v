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
    wire [31:0] memwritedata;
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


    always @(negedge CLK or negedge RESET) begin
        if (!RESET || !initialized) begin
            DequeueResult_OUT = 0;
            tail = 0;
            full = 0;
            for (i = 0; i == QUEUE_SIZE; i = i + 1) begin
               queue[i] = i;
            end
            if (!initialized) begin
                $display("Issue Queue: initializing");
                initialized = 1;
            end else begin
                $display("Issue Queue: RESET");
            end
        end
        else begin
            // Update, dequeue, then enqueue to make sure that register ready bit is updated before select phase
            // WAKE_UP
            if (ReadyUpdate_IN) begin
                for (i = 0; i != tail; i = i + 1) begin
                    {op, has_immediate, immediate, src1, src1ready, src2, src2ready, shift, regwrite, dest, memwrite, memwritedata, memread} = queue[i];
                    if (src1 == ReadyRegister_IN) begin
                        src1ready = 1;
                    end
                    if (src2 == ReadyRegister_IN) begin
                        src2ready = 1;
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
                $display("Issue Queue: attempting dequeue");
                for (i = 0; i < tail && ready_bits[i] != 1; i = (i + 1) % QUEUE_SIZE) begin
                end
                if (i != tail) begin
                    entry_selected = queue[i];
                    while ((i + 1) % QUEUE_SIZE < tail) begin
                        queue[i] = queue[(i + 1) % QUEUE_SIZE];
                        ready_bits[i] = ready_bits[(i + 1) % QUEUE_SIZE];
                    end
                    ready_bits[tail[`LOG_SIZE - 1:0]] = 0;
                    tail = tail - 1;
                    full = 0;
                    DequeueResult_OUT = 1;
                    $display("Issue Queue: Select entry %x", entry_selected);
                end else begin
                    $display("Issue Queue: nothing is ready");
                    DequeueResult_OUT = 0;
                end
            end else begin
                DequeueResult_OUT = 0;
            end
            //ENQUEUE
            if (Enqueue_IN) begin
                if (!full) begin
                    queue[tail] = IssueQueueEntry_IN;
                    if (IssueQueueEntry_IN[53] == 1 && IssueQueueEntry_IN[46] == 1) begin
                        $display("Issue Queue: entry is ready");
                        ready_bits[tail] = 1;
                    end
                    tail = (tail + 1) % QUEUE_SIZE;
                    if ((tail+1) == QUEUE_SIZE) begin
                        full = 1;
                    end
                    $display("Issue Queue: Enqueue size: instr@%x = %x", IssueQueueEntry_IN[131:99], {IssueQueueEntry_IN, 5'd0});
                end
            end
            Full_OUT = full;
        end
    end
endmodule
