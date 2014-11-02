module aq_intreg(
  input RST_N,

  input CLKA,
  input DIN,

  input CLKB,
  output INT
);

reg data_in;
reg [2:0] data_in_rst;
reg [2:0] data_out;

always @(posedge CLKA or negedge RST_N) begin
  if(!RST_N) begin
    data_in <= 1'b0;
    data_in_rst[2:0] <= 3'd0;
  end else begin
    if(data_in_rst[2]) begin
      data_in <= 1'b0;
    end else begin
      data_in <= DIN;
    end
    data_in_rst[2:0] <= {data_in_rst[1:0], data_out[2]};
  end
end

always @(posedge CLKB or negedge RST_N) begin
  if(!RST_N) begin
    data_out[2:0] <= 3'd0;
  end else begin
    data_out[2:0] <= {data_out[1:0], data_in};
  end
end

assign INT = (data_out[2:1] == 2'b01)?1'b1:1'b0;

endmodule
