module FIFO #(
    parameter SIZE = 16,
    parameter ELEM_SIZE_BITS = 96,
    parameter FROM = "??",
    parameter TO = "??"
)
(
    input CLK,
    input RESET,
    input reg [ELEM_SIZE_BITS-1:0] in_data,             // contains instr, addr, PC+4
    input pushing,
    input popping,
    output reg push_must_wait,
    output reg [ELEM_SIZE_BITS-1:0] out_data,
    output reg pop_must_wait
);

reg [ELEM_SIZE_BITS-1:0] queue [SIZE:0];        // not SIZE-1 because we're using modular arithmetic
reg [$clog2(SIZE):0] head, tail;                // not clog2(SIZE)-1 because we're using modular arithmetic

`define QUEUE_SIZE (tail >= head ? tail - head : tail + (SIZE - head))
`define QUEUE_FULL (`QUEUE_SIZE == SIZE)
`define QUEUE_ALMOST_FULL (`QUEUE_SIZE == SIZE - 1)
`define QUEUE_EMPTY (`QUEUE_SIZE == 0)
`define QUEUE_PUSH(data) queue[tail] <= data; tail <= (tail + 1) % SIZE
`define QUEUE_POP queue[head]; head <= (head + 1) % SIZE

initial begin
    head = 0;
    tail = 0;
end

string s1;
string s2;
string sb1;
string sb2;


always @(posedge CLK or negedge RESET) begin
    if (!RESET) begin
        push_must_wait <= 0;
        out_data <= 0;
        pop_must_wait <= 1;
        head <= tail;
        $display("FIFO %s -> %s RESET", FROM, TO);
    end else begin
        if (pushing && !popping) begin
            /**
             * We use this instead of QUEUE_FULL because of the clock delay.
             */
            if (`QUEUE_ALMOST_FULL) begin
                push_must_wait <= 1;
            end else begin
                `QUEUE_PUSH(in_data);
                push_must_wait <= 0;
            end
            pop_must_wait <= `QUEUE_EMPTY;
        end else if (!pushing && popping) begin
            if (`QUEUE_EMPTY) begin
                pop_must_wait <= 1;
            end else begin
                out_data <= `QUEUE_POP;
                queue[head] <= 0;
                pop_must_wait <= 0;
            end
            push_must_wait <= `QUEUE_FULL;
        end else if (pushing && popping) begin
            push_must_wait <= 0;
            pop_must_wait <= 0;
            if (`QUEUE_EMPTY) begin
                out_data <= in_data;
            end else begin
                out_data <= `QUEUE_POP;
                queue[head] <= 0;
                `QUEUE_PUSH(in_data);
            end
        end else begin
            pop_must_wait <= `QUEUE_EMPTY;
            push_must_wait <= `QUEUE_FULL;
        end

        $sformat(s1, "%x", in_data);
        $sformat(s2, "%x", out_data);
        $sformat(sb1, "%b", in_data);
        $sformat(sb2, "%b", out_data);
        $display("FIFO %s -> %s: size(queue) = %d, push: %s, pop: %s", FROM, TO, `QUEUE_SIZE,
            pushing ? (push_must_wait ? "halt" : s1) : "no",
            popping ? (pop_must_wait ? "halt": s2) : "no");
        $display("FIFO %s -> %s: size(queue) = %d, push: %s, pop: %s", FROM, TO, `QUEUE_SIZE,
            pushing ? (push_must_wait ? "halt" : sb1) : "no",
            popping ? (pop_must_wait ? "halt": sb2) : "no");
    end
end

endmodule
