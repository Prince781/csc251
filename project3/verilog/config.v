//Added during project 1
`define HAS_FORWARDING
`define INCLUDE_IF_CONTENT
`define HAS_WRITEBACK
`define INCLUDE_MEM_CONTENT

`ifdef HAS_FORWARDING
//Add files after project 1:
//  RegValue1.v
//  RegValue2.v
//  RegValue3.v
`endif

//Added during project 2 (usually removed for project 3; may be re-added for project 4)
//`define SUPERSCALAR

//Added during project 3
`define USE_ICACHE
`define USE_DCACHE

//Added before project 4 starts
`define OUT_OF_ORDER

`ifdef OUT_OF_ORDER
//Also, before project 4:
//  Cache.v
//  RegRead.v
//  PhysRegFile.v
//  RAT.v
//  RetireCommit.v
`endif

`define PROJ_NUM_PHYS_REGS 64
`define PROJ_LOG_PHYS    $clog2(`PROJ_NUM_PHYS_REGS)
`define PROJ_NUM_ARCH_REGS 35
`define PROJ_LOG_ARCH    $clog2(`PROJ_NUM_ARCH_REGS)

/* src1/src2 = ReadRegisterA1/ReadRegisterB1 */
/* src1/src2 val = OperandA1/OperandB1 */
/* anything in the issue queue has regwrite guaranteed */
`define ISSUE_QUEUE_ENTRY_BITS (6 /* ALU op */ + 1 /* has immediate? */ + 32 /* immediate */ + `PROJ_LOG_PHYS /* src1 reg */ + 1 /* src1 ready? */ + `PROJ_LOG_PHYS /* src2 */ + 1 /* src2 ready? */ + 5 /* shift amount */ + 1 /* regwrite? */ +  `PROJ_LOG_PHYS /* dest */ + 1 /* memwrite? */ + 1 /* memread? */)

`define LOAD_STORE_QUEUE_ENTRY_BITS (1 /* 0 = load, 1 = store */ + 1 /* ready? */ + `PROJ_LOG_PHYS /* dest/src */ + 32 /* addr */)

`define ROB_ENTRY_BITS (1 /* executed? */ + 32 /*instr*/ + 32 /* addr */ + 32 /* alt_pc */ + 1 /* request alt_pc? */ + 1 /* write to R-RAT? */ + `PROJ_LOG_PHYS /* phys register */ + `PROJ_LOG_ARCH /* arch register */ /* +  ??? */)
