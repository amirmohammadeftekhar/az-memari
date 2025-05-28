`timescale 1ns / 1ps

// ALU Module
module ALU
#
(
    // Data Width
    parameter Data_Width = 16
)
(
    input Clock,
    // Operation Select
    input [2 : 0] Operation_Select,
    
    // Inputs
    // INPR
    input [((Data_Width / 2) - 1) : 0] Inp_0,
    // DR
    input [(Data_Width - 1) : 0] Inp_1,
    // AC
    input [(Data_Width - 1) : 0] Inp_2,
    // Input E
    input E_In,
    
    // Outputs
    // Output E
    output E_Out,
    // Calculation Output
    output [(Data_Width - 1) : 0] Out
);

// Outputs Variable Temporary
reg                        E_Out_Temp;
reg [(Data_Width - 1) : 0] Out_Temp;

wire                        div_dividend_valid;
wire                        div_dividend_ready;    // اضافه شده
wire [(Data_Width - 1) : 0] div_dividend;
wire                        div_divisor_valid;
wire                        div_divisor_ready;     // اضافه شده
wire [(Data_Width - 1) : 0] div_divisor;
wire [(Data_Width - 1) : 0] div_quotient;
wire [(Data_Width - 1) : 0] div_remainder;
wire                        div_result_valid;
wire                        div_result_ready;      // اضافه شده
wire [31 : 0]               div_result_data;       // تغییر از {remainder, quotient}

// Division control
reg div_start;
reg [(Data_Width - 1) : 0] div_result_reg;
reg div_operation_active;

div_gen_0 divider_ip (
    .aclk(Clock),
    .s_axis_dividend_tvalid(div_dividend_valid),
    .s_axis_dividend_tready(div_dividend_ready),     // اضافه شده
    .s_axis_dividend_tdata(div_dividend),
    .s_axis_divisor_tvalid(div_divisor_valid),
    .s_axis_divisor_tready(div_divisor_ready),       // اضافه شده
    .s_axis_divisor_tdata(div_divisor),
    .m_axis_dout_tvalid(div_result_valid),
    .m_axis_dout_tready(div_result_ready),           // اضافه شده
    .m_axis_dout_tdata(div_result_data)              // تغییر نام
);

// Division control logic
always @(posedge Clock)
begin
    // Start division when operation select is 111 (DIV)
    if (Operation_Select == 3'b111)
    begin
        div_start <= 1'b1;
        div_operation_active <= 1'b1;
    end
    else
    begin
        div_start <= 1'b0;
    end
    
    // Store result when valid
    if (div_result_valid)
    begin
        div_result_reg <= div_quotient;
        div_operation_active <= 1'b0;
    end
end

assign div_dividend_valid = div_start;           // تغییر نام از div_valid
assign div_divisor_valid = div_start;            // اضافه شده
assign div_dividend = Inp_2;
assign div_divisor = Inp_1;   
assign div_result_ready = 1'b1;                  // اضافه شده

assign div_quotient = div_result_data[15:0];     // Lower 16 bits: quotient
assign div_remainder = div_result_data[31:16];   // Upper 16 bits: remainder

// Combinational Circuit
always @(*)
begin
    E_Out_Temp = 1'b0;
    Out_Temp   =  'b0;
    
    case (Operation_Select)
        // Nothing
        3'b000:
        begin
            E_Out_Temp = 1'b0;
            Out_Temp   =  'b0;
        end
        
        // Nothing
        3'b001:
        begin
            E_Out_Temp = 1'b0;
            Out_Temp   =  'b0;
        end
        
        // AND
        3'b010:
        begin
            Out_Temp = Inp_1 & Inp_2;
        end
        
        // ADD
        3'b011:
        begin
            {E_Out_Temp, Out_Temp} = Inp_1 + Inp_2;
        end
        
        // CIR
        3'b100:
        begin
            E_Out_Temp = Out_Temp[0];
            Out_Temp   = {E_In, Inp_2[(Data_Width - 1) : 1]};
        end
        
        // CIL
        3'b101:
        begin
            E_Out_Temp = Inp_2[Data_Width - 1];
            Out_Temp   = {Inp_2[(Data_Width - 2) : 0], E_In};
        end
        
        // PASS 1 (AC[7 : 0] <- INPR)
        3'b110:
        begin
            Out_Temp[7 : 0] = Inp_0;
        end
        
       // DIV (AC <- AC / DR)
        3'b111:
        begin
            if (div_result_valid || (!div_operation_active))
            begin
                Out_Temp = div_result_reg;  // Return quotient
            end
            else
            begin
                Out_Temp = Inp_2;  // Return AC unchanged during division
            end
        end
        
        // Defaults
        default:
        begin
            E_Out_Temp = 1'b0;
            Out_Temp   =  'b0;
        end
    endcase
end

// Assign to Outputs
assign E_Out = E_Out_Temp;
assign Out   = Out_Temp;

endmodule
