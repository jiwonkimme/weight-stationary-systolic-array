module MAC_4X1_COL(
    input wire  CLK,
    input wire  RSTN,
    input wire  en_x_i,
    input wire  en_w_i,
    input wire  stop_mac,
    input wire  used_row,

    input wire  signed  [15:0] before_sum_1,
    input wire  signed  [15:0] before_sum_2,
    input wire  signed  [15:0] before_sum_3,
    input wire  signed  [15:0] before_sum_4,

    input wire  signed  [7:0]  x_i,
    input wire  signed  [7:0]  w_i,

    output wire signed  [15:0] after_sum_1,
    output wire signed  [15:0] after_sum_2,
    output wire signed  [15:0] after_sum_3,
    output wire signed  [15:0] after_sum_4
);

    wire signed [7:0]   x_o         [0:3];
    wire signed [7:0]   w_o         [0:3];
    wire        [3:0]   stop_mac_o;
    wire        [3:0]   used_row_o;

    // Instantiate the MAC module
    MAC_1X1_UNIT mac1 (
        .CLK(CLK),
        .RSTN(RSTN),
        .en_x_i(en_x_i),
        .en_w_i(en_w_i),
        .stop_mac(stop_mac),
        .used_row(used_row),
        .x_i(x_i),
        .w_i(w_i),
        .before_sum(before_sum_1),
        .stop_mac_o(stop_mac_o[0]),
        .used_row_o(used_row_o[0]),
        .x_o(x_o[0]),
        .w_o(w_o[0]),
        .after_sum(after_sum_1)
    );
    MAC_1X1_UNIT mac2 (
        .CLK(CLK),
        .RSTN(RSTN),
        .en_x_i(en_x_i),
        .en_w_i(en_w_i),
        .stop_mac(stop_mac_o[0]),
        .used_row(used_row_o[0]),
        .x_i(x_o[0]),
        .w_i(w_o[0]),
        .before_sum(before_sum_2),
        .stop_mac_o(stop_mac_o[1]),
        .used_row_o(used_row_o[1]),
        .x_o(x_o[1]),
        .w_o(w_o[1]),
        .after_sum(after_sum_2)
    );
    MAC_1X1_UNIT mac3 (
        .CLK(CLK),
        .RSTN(RSTN),
        .en_x_i(en_x_i),
        .en_w_i(en_w_i),
        .stop_mac(stop_mac_o[1]),
        .used_row(used_row_o[1]),
        .x_i(x_o[1]),
        .w_i(w_o[1]),
        .before_sum(before_sum_3),
        .stop_mac_o(stop_mac_o[2]),
        .used_row_o(used_row_o[2]),
        .x_o(x_o[2]),
        .w_o(w_o[2]),
        .after_sum(after_sum_3)
    );
    MAC_1X1_UNIT mac4 (
        .CLK(CLK),
        .RSTN(RSTN),
        .en_x_i(en_x_i),
        .en_w_i(en_w_i),
        .stop_mac(stop_mac_o[2]),
        .used_row(used_row_o[2]),
        .x_i(x_o[2]),
        .w_i(w_o[2]),
        .before_sum(before_sum_4),
        .stop_mac_o(stop_mac_o[3]),
        .used_row_o(used_row_o[3]),
        .x_o(x_o[3]),
        .w_o(w_o[3]),
        .after_sum(after_sum_4)
    );

endmodule