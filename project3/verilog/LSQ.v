`define LOG_PHYS    $clog2(NUM_PHYS_REGS)
//-----------------------------------------
//           LSQ
//-----------------------------------------

module LSQ #(
    parameter NUM_PHYS_REGS = 64,
    parameter ENTRY_SIZE = 1 + 1 + `LOG_PHYS + 32
    // 1 load/store bit + 1 ready bit + physical register addr + memory addr
    parameter QUEUE_SIZE = 16 // TODO: Use more reasonable queue size
)
(
    input CLK,
    input RESET,
    input FLUSH,
    input Enqueue_IN, // 0 = no new data to enqueue, 1 = enqueue, 2 = update
    input [ENTRY_SIZE-1:0] Entry_IN, // entry
    input Dequeue_IN, // 0 = no need to dequeue, 1 = dequeue
    output Full_OUT, // 0 = not full, 1 = full
    output DequeueResult_OUT, // 0 = no dequeue request or dequeue failed, 1 = dequeue succeeded
    output EnqueueResult_OUT, // 0 = no enqueue request or enqueue failed, 1 = enqueue succeeded
    output reg [ENTRY_SIZE - 1 : 0] Data_OUT
);
    reg [ENTRY_SIZE - 1 : 0] queue [QUEUE_SIZE - 1 : 0];
    reg head, tail, full;
    wire temp;

    wire LoadStore_IN;
    wire Ready_IN;
    wire [`LOG_PHYS-1:0] Register_IN;
    wire [31:0] Addr_IN;

    initial begin
        head = 0;
        tail = 0;
        full = 0;
    end

    assign LoadStore_IN = Entry_IN[ENTRY_SIZE-1];
    assign Ready_IN = Entry_IN[ENTRY_SIZE - 1 - 1];
    assign Register_IN = Entry_IN[ENTRY_SIZE-2 - 1: (ENTRY_SIZE-2 - 1) - (LOG_PHYS-1)];
    assign Addr_IN = Entry_IN[31:0];

    always @(posedge CLK or negedge RESET) begin
        EnqueueResult_OUT = 0;
        DequeueResult_OUT = 0;
        if (!RESET) begin
            // TODO: Reset shouldn't flush LSQ
            head = 0;
            tail = 0;
            full = 0;
            Full_OUT = 0;
            $display("Load/Store Queue: RESET");
        end
        else if (FLUSH) begin
            head = 0;
            tail = 0;
            full = 0;
            Full_OUT = 0;
            $display("Load/Store Queue: FLUSH");
        end
        else begin
            // Dequeue first so when the queue is full and there are both enqueue request and dequeue request,
            // there will be space for new enqueue request
            if (Dequeue_IN) begin
                if (!(head == tail && full == 0)) begin // only dequeue when the queue is not empty
                    Data_OUT = queue[head];
                    head = (head + 1) % QUEUE_SIZE;
                    full = 0;
                    DequeueResult_OUT = 1;
                end
            end
            // Enqueue
            if (Enqueue_IN == 1) begin
                if (!full) begin
                    queue[tail] = {LoadStore_IN, Ready_IN, Register_IN, Addr_IN};
                    tail = (tail + 1) % QUEUE_SIZE;
                    if (tail == head) begin
                        full = 1;
                    end
                    EnqueueResult_OUT = 1;
                end
            end
            // Update
            if (Enqueue_IN == 2) begin
                temp = 0;
                // Locate the entry to update
                while ((temp < QUEUE_SIZE) && (queue[temp][ENTRY_SIZE - 1] != LoadStore_IN || queue[temp][(32 + `LOG_PHYS - 1) : 32] != Register_IN)) begin
                    temp = temp + 1;
                end
                if (temp < QUEUE_SIZE) begin
                    queue[temp] = {LoadStore_IN, 1'b1, Register_IN, Addr_IN};
                    EnqueueResult_OUT = 1;
                end else begin
                    $display("ERROR: Load Store Queue: Entry not found when updating");
                end
            end
            Full_OUT = full;
        end
    end
endmodule
