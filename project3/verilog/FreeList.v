`define LOG_PHYS    $clog2(NUM_PHYS_REGS)
//-----------------------------------------
//           FreeList
//-----------------------------------------

module FreeList #(
    parameter NUM_PHYS_REGS = 64,
    parameter LOG_PHYS = $clog2(NUM_PHYS_REGS)
)
(
    input CLK,
    input RESET,
    input Enqueue_IN, // 0 = no new data to enqueue, 1 = enqueue
    input reg [`LOG_PHYS - 1 : 0] Data_IN,
    input Dequeue_IN, // 0 = no need to dequeue, 1 = dequeue
    output DequeueResult_OUT, // 0 = no dequeue request or dequeue failed, 1 = dequeue succeeded
    output reg [`LOG_PHYS - 1 : 0] Data_OUT
);

`define FREE_LIST_NELEMS (head <= tail ? tail - head : (NUM_PHYS_REGS - head) + tail)
reg [`LOG_PHYS - 1 : 0] queue [NUM_PHYS_REGS - 1: 0];
reg [`LOG_PHYS:0] head;
reg [`LOG_PHYS:0] tail;
reg full;
integer counter;

initial begin
    head = 0;
    tail = NUM_PHYS_REGS-1;
    full = 0;
    counter = 0;
    // Initialize queue. Enqueue all physical registers. 
    for (counter = 0; counter < LOG_PHYS; counter = counter + 1) begin
        queue[counter] = counter;
    end
end

always @(posedge CLK or negedge RESET) begin
    DequeueResult_OUT = 0;
    if (!RESET) begin
        head <= 0;
        tail <= NUM_PHYS_REGS-1;
        full <= 0;
        counter <= 0;
        // Initialize queue. Enqueue all physical registers. 
        while (counter < `LOG_PHYS) begin
            queue[counter] <= counter;
            counter = counter + 1;
        end
    end else begin
        // Enqueue first so when the queue is empty and there are both enqueue request and dequeue request,
        // there will be free register to dequeue
        $display("Free List: Enqueue:%d,Dequeue:%d", Enqueue_IN, Dequeue_IN);
        if (Enqueue_IN) begin
            // Normally, the list should never be full before an enqueue because
            // the number of free registers should always be less than or equal to 
            // the total number of registers
            if (!full) begin
                queue[tail[`LOG_PHYS-1:0]] = Data_IN;
                tail = (tail + 1) % NUM_PHYS_REGS;
                if (tail == head) begin
                    full = 1;
                end
            end
            $display("Free List: Enqueue Reg:%d, tail:%d, full:%d", Data_IN, tail, full);
        end
        if (Dequeue_IN) begin
            if (!(head == tail && full == 0)) begin // only dequeue when the queue is not empty
                Data_OUT = queue[head[`LOG_PHYS-1:0]];
                head = (head + 1) % NUM_PHYS_REGS;
                full = 0;
                DequeueResult_OUT = 1;
                $display("Free List: Dequeue Reg:%d, head:%d, full:%d, DequeueResult: %d", Data_OUT, head, full, DequeueResult_OUT);
            end
        end
    end
end
endmodule
