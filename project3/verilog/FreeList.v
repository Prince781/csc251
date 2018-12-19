`define LOG_PHYS    $clog2(NUM_PHYS_REGS)
//-----------------------------------------
//           FreeList
//-----------------------------------------

module FreeList #(
    parameter NUM_PHYS_REGS = 64,
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
    reg [`LOG_PHYS - 1 : 0] queue [NUM_PHYS_REGS - 1 : 0];
    reg head;
    reg tail;
    reg full;
    wire counter;

    initial begin
        head = 0;
        tail = 0;
        full = 0;
        counter = 1;
        // Initialize queue. Enqueue all physical registers. 
        while (counter < `LOG_PHYS) begin
            queue[counter] = counter;
            counter = counter + 1;
        end
    end

    always @(posedge CLK or negedge RESET) begin
        DequeueResult_OUT = 0;
        if (!RESET) begin
            head = 0;
            tail = 0;
            full = 0;
            counter = 1;
            // Initialize queue. Enqueue all physical registers. 
            while (counter < `LOG_PHYS) begin
                queue[counter] = counter;
                counter = counter + 1;
            end
            $display("Free List: RESET");
        end
        else
            // Enqueue first so when the queue is empty and there are both enqueue request and dequeue request,
            // there will be free register to dequeue
            if (Enqueue_IN) begin
                // Normally, the list should never be full before an enqueue because
                // the number of free registers should always be less than or equal to 
                // the total number of registers
                if (!full) begin
                    queue[tail] = Data_IN;
                    tail = (tail + 1) % NUM_PHYS_REGS;
                    if (tail == head) begin
                        full = 1;
                    end
                end
            end
            if (Dequeue_IN) begin
                if (!(head == tail && full == 0)) begin // only dequeue when the queue is not empty
                    Data_OUT = queue[head];
                    head = (head + 1) % NUM_PHYS_REGS;
                    full = 0;
                    DequeueResult_OUT = 1;
                end
            end
            
        end
    end
endmodule
