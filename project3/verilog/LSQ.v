`define LOG_PHYS    $clog2(NUM_PHYS_REGS)
//-----------------------------------------
//           LSQ
//-----------------------------------------

module LSQ #(
    parameter NUM_PHYS_REGS = 64,
    parameter ENTRY_SIZE = 1 + `LOG_PHYS + 32 // 1 load/store bit + physical register addr + memory addr
    parameter QUEUE_SIZE = 128 // TODO: Use more reasonable queue size
)
(
    input CLK,
    input RESET,
    input Enqueue_IN, // 0 = no new data to enqueue, 1 = enqueue
    input reg [ENTRY_SIZE - 1 : 0] Data_IN,
    input Dequeue_IN, // 0 = no need to dequeue, 1 = dequeue
    output Full_OUT, // 0 = not full, 1 = full
    output DequeueResult_OUT, // 0 = no dequeue request or dequeue failed, 1 = dequeue succeeded
    output EnqueueResult_OUT, // 0 = no enqueue request or enqueue failed, 1 = enqueue succeeded
    output reg [ENTRY_SIZE - 1 : 0] Data_OUT
);
    reg [ENTRY_SIZE - 1 : 0] queue [QUEUE_SIZE - 1 : 0];
    reg head, tail, full;

    initial begin
        head = 0;
        tail = 0;
        full = 0;
    end

    always @(posedge CLK or negedge RESET) begin
        EnqueueResult_OUT = 0;
        DequeueResult_OUT = 0;
        if (!RESET) begin
            head = 0;
            tail = 0;
            full = 0;
            Full_OUT = 0;
            $display("Load/Store Queue: RESET");
        end
        else
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
            if (Enqueue_IN) begin
                if (!full) begin
                    queue[tail] = Data_IN;
                    tail = (tail + 1) % QUEUE_SIZE;
                    if (tail == head) begin
                        full = 1;
                    end
                    EnqueueResult_OUT = 1;
                end
            end
            Full_OUT = full;
        end
    end
endmodule