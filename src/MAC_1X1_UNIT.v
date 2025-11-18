module MAC_1X1_UNIT(
    input wire                  CLK,
    input wire                  RSTN,
    input wire                  en_x_i,
    input wire                  en_w_i,

    input wire                  stop_mac,
    input wire                  used_row,

    input wire  signed   [7:0]  x_i,
    input wire  signed   [7:0]  w_i,
    input wire  signed   [15:0] before_sum,

    output wire                 stop_mac_o,
    output wire                 used_row_o,
    output reg  signed   [7:0]  x_o,
    output reg  signed   [7:0]  w_o,
    output wire signed   [15:0] after_sum
);

    reg                 stop_mac_reg;
    reg                 used_row_reg;
    reg signed   [7:0]  WEIGHT;

    reg signed   [15:0] SUM;
    wire signed  [15:0] MUL;

    // WEIGHT + stop_mac + used_row
    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) begin
            WEIGHT          <=  8'd0;
            stop_mac_reg    <=  1'b0;
            used_row_reg    <=  1'b0;
        end else if(en_w_i) begin
            WEIGHT          <=  w_i;
            used_row_reg    <=  used_row;
        end else begin
            WEIGHT          <=  WEIGHT;
            stop_mac_reg    <=  stop_mac;
            used_row_reg    <=  used_row_reg;
        end
    end

    // SUM
    // Weight Loading & used_row X & stop_mac O -> MAC operation X
    assign  MUL         =   WEIGHT * x_i;
    
    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) begin
            SUM         <=  16'd0;
        end else if(en_w_i||stop_mac_reg||~used_row_reg) begin
            SUM         <=  16'd0;
        end else begin
            SUM         <=  before_sum + MUL;
        end
    end

    // I/O interface
    always @(posedge CLK or negedge RSTN) begin
        if(!RSTN) begin
            x_o             <=  8'd0;
            w_o             <=  8'd0;
        end else begin
            x_o             <=  x_i;
            w_o             <=  w_i;
        end
    end

    assign  after_sum   =   SUM;
    assign  stop_mac_o  =   stop_mac_reg;
    assign  used_row_o  =   used_row_reg;
endmodule