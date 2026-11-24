// CMPE 230 2nd Project

.equ SYS_READ,      63
.equ SYS_WRITE,     64
.equ SYS_EXIT,      93

.equ STDIN,         0
.equ STDOUT,        1

.equ MAX_ORDERS,    10
.equ MAX_TICKS,     1024
.equ IN_BUF_SIZE,   4096
.equ OUT_BUF_SIZE,  4096

.equ RULE_FIRST,    0
.equ RULE_QUICK,    1
.equ RULE_TURNS,    2

// Order struct layout (32 bytes per order):
//   0: id            (1 byte)
//   1: in_station    (1 byte) - 1 if currently in cur_station queue
//   2: pending_enter (1 byte) - 1 if entering cur_station at start of cur_tick
//   3: pad           (1 byte)
//   4: arrival       (4 bytes, int32)
//   8: work[0]       (4 bytes, int32) - Prep
//  12: work[1]       (4 bytes, int32) - Cook
//  16: work[2]       (4 bytes, int32) - Plate
//  20: cur_station   (4 bytes, int32) - -1: unarrived, 0..2: station, 3: served
//  24: entry_time    (4 bytes, int32)
//  28: serve_time    (4 bytes, int32)
.equ ORDER_SIZE,    32

// Station struct layout (32 bytes per station):
//   0: rule            (4 bytes, int32)
//   4: q               (4 bytes, int32)
//   8: active_order    (4 bytes, int32) - used by FIRST (-1 if none)
//  12: turn_used       (4 bytes, int32) - used by TURNS-q
//  16: pending_requeue (4 bytes, int32) - used by TURNS-q (-1 if none)
//  20: q_len           (4 bytes, int32) - used by TURNS-q
.equ STATION_SIZE,  32
.equ QUEUE_STRIDE,  16

.section .bss
.align 4
in_buf:         .skip IN_BUF_SIZE
out_buf:        .skip OUT_BUF_SIZE
timelines:      .skip 3 * MAX_TICKS
orders:         .skip MAX_ORDERS * ORDER_SIZE
stations:       .skip 3 * STATION_SIZE
station_queues: .skip 3 * QUEUE_STRIDE
num_orders:     .skip 4
served_count:   .skip 4
cur_tick:       .skip 4

.section .text
.global _start

_start:
    bl      read_all_input

    mov     x0, #0
    mov     x8, #SYS_EXIT
    svc     #0

// -----------------------------------------------------------------------------
// read_all_input: Reads stdin into in_buf until '\n' or EOF.
// -----------------------------------------------------------------------------
read_all_input:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]

    adrp    x19, in_buf
    add     x19, x19, :lo12:in_buf
    mov     x20, #0                     // total bytes read

1:
    mov     x0, #STDIN
    add     x1, x19, x20
    mov     x2, #(IN_BUF_SIZE - 1)
    sub     x2, x2, x20
    cmp     x2, #0
    b.le    3f

    mov     x8, #SYS_READ
    svc     #0
    cmp     x0, #0
    b.le    3f

    add     x20, x20, x0
    sub     x1, x20, #1
    ldrb    w2, [x19, x1]
    cmp     w2, #'\n'
    b.ne    1b

3:
    strb    wzr, [x19, x20]             // null-terminate buffer
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret