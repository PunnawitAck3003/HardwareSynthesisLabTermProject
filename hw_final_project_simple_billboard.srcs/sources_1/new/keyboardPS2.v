`timescale 1ns / 1ps
//#############################################################################################//
//////////////////////////////   Begin Module Instantiation   ///////////////////////////////////
// Student:............. 
// Student ID........... 
// Course:.............. EET 343 - Advanced Digital Design 
// School:.............. Eastern New Mexico University
// Term:................ Fall 2018
// HDL:................. Verliog (Target Language)
// Hardware:............ DIGILENT Basys 3 - Rev C - XC7A35TCPG236-1
// Software Environment: Vivado Design Suite 2018.2 HL WebPACK (free)
// Implementation:...... Keyboard controllers are implemented as state machines
// Constraint File:..... Master Xilinx Design Constraint XDC: "Basys3_Master.xdc"
// Available I/O:....... pmods, 4-digit 7-segment display, 16 slide switches, 
//                       16 leds, 5 push-buttons, 16Mb RAM, XADC, VGA connector,
//                       USB/UART/JTAG/Host/HID (shared connector via PIC24FJ128 MCU)
/////////////////////////////////////////////////////////////////////////////////////////////////
// SPECIAL CREDIT TO:... 1. poketronics @ embeddedthoughts.com (Reference 5)
/////////////////////////////////////////////////////////////////////////////////////////////////
// Modeling Methods..... 1. Structural Modeling: gate-level modeling, elements as structures
//                          Notes: gate_type=keyword gate_name=chosen (port_list comma sep) 
//                                 wire=keyword gate_name1,gate_name2;
//
//     ( selected ) -->  2. Dataflow Modeling: relationship of input(s) & output(s) as a funtion
//                          Notes: assign=keyword output_name = some funtion of inputs
//                                 outsputs must be a scalar or vector. Merging Fns to condence
//                                 wire=keyowrd gate_name1,gate_name2; is also used here
//
//                       3. Behavioral Modeling: keywords for conditional & recursive statements
//                          Notes: always @ (sensitivity_list), an * triggers at any input change
//                                 triggering signals for behaviors specified in sensitivity list
//                                 signals can be comma separated or combined by the "or" keyword
//                                 inital=keyword for intilization of variables executed at time 0
//                                 reg=keyword saves the previous output
//                                 blocking assignment: "=" executed 1-by-1 (sequential or serial)
//                                 non-blocking assignment: "<=" executed concurrently (parallel)
//////////////////////////////////////////////////////////////////////////////////////////////////
// Realization Steps:... 1. Synthesize: transform system represented as code into FPGA blocks
//                       2. Simulation: feed input(s) & monitor output(s) via testbench file
//                       3. Implementation: optimzation, minimization, constraints
//                       4. Program: gen bit strm, HW mgr: open target/auto conn, program device
//////////////////////////////////////////////////////////////////////////////////////////////////


//#############################################################################################//
//////////////////////////////   Begin Module Instantiation   ///////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
// Explanation: module=keyword {module_name}(port_list); 
// Notes: module_name should be unique and not any pre-defined verilog keywords
//        the port_list odes not have a specific order
//        ports may be "input", "output", or "inout"
//        If the project consists of more than one module, they should be properly instiation
//        above this one, e.g. module_name(port_list);
//                             input input_name1,input_name2;
//                             output output_name1, output_name2;
//                             statements;
//                             endmodule
module keyboardPS2  // credit for formatting to embeddedthgouhts.com (Reference 5)
    (
//	      input wire clk, reset,
//        input wire PS2Data, PS2Clk,          // ps2 data and clock lines
//        output wire [7:0] scan_code,         // scan_code received from keyboard to process
//        output wire [7:0] led,               // For Degub Purposes (test scan codes are working)
//        output wire scan_code_ready,         // signal to outer controlsystem to sample scan_code
//        output wire letter_case_out          // output determines if scan code is converted to 
//                                             // lower or upper ascii code for a key

	    input wire clk, reset,                 // Bsys 3 System clock & reset (assignable)
        input wire PS2Data,                    // ps2 data line
        input wire PS2Clk,                     // ps2 clock line
        output [7:0] dataPS2
        //output [0:6] LED_out,                  // Cathodes for 7 segment displays (timed assign)
        //output [3:0] Anode_Activate            // 7 segment digit selector (timed)                    
    );
/////////////////////////////////////////////////////////////////////////////////////////////////

//#############################################################################################//
///////////////////////   Begin Port, Signal, & Constant  Declarations   ////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
// Explanation: use reg to hold previous value until new value is sent to it
// Examples: ou1, ou2, [1:0]sw, [1:0]led;
// constant declarations
    localparam  // these parameters to not belong to any other data type such as net or reg
            BREAK    = 8'hf0,       // break code
            SHIFT1   = 8'h12,       // first shift scan
            SHIFT2   = 8'h59,       // second shift scan
            CAPS     = 8'h58;       // caps lock

    // FSM symbolic states
    localparam [2:0] 
            lowercase          = 3'b000, // idle, process lower case letters
            ignore_break       = 3'b001, // ignore repeated scancode after break code -F0- rcvd
            shift              = 3'b010, // process uppercase letters for shift key held
            ignore_shift_break = 3'b011, // chk scancode after F0, either idle or go back to uCase
            capslock           = 3'b100, // process uppercase letter after capslock button pressed
            ignore_caps_break  = 3'b101; // chk scancode after F0, either ignore repeat, 
                                         // or decrement caps_num


    // internal signal declarations
    reg [2:0] state_reg, state_next;           // FSM state register and next state logic
    wire [7:0] scan_out;                       // scan code received from keyboard
    reg got_code_tick;                         // asserted to write curr scancode rcvd to FIFO
    wire scan_done_tick;                       // asserted to signal that ps2_rx has rcvd a scancode
    reg letter_case;                           // 0=lwrCase, 1=upCase, o/p 2 convert scancode 2 ascii
    reg [7:0] shift_type_reg, shift_type_next; // register holds scancodes of shiftkeys or capslock
    reg [1:0] caps_num_reg, caps_num_next;     // tracks num capslockscancodes rcvd in capslock state
                                               //      (3 before going back to lowecase state)
    wire [7:0] scan_code;                      // scan_code received from keyboard to process
    wire scan_code_ready;                      // signal to outer controlsystem to sample scan_code
    wire letter_case_out;                      // output determines if scan code is converted to   
    wire [7:0] ascii_code;                     // output of instant'd module fed into 7seg disp.

    
//#############################################################################################//
///////////////////////       Begin External Module Instantiations       ////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
    ps2_rx ps2_rx_unit (// instantiate ps2 receiver (project dependency)
        .clk(clk), 
        .reset(reset), 
        .rx_en(1'b1), 
        .PS2Data(PS2Data), 
        .PS2Clk(PS2Clk),
        .rx_done_tick(scan_done_tick),
        .rx_data(scan_out)
        );
    
    wire [7:0] dataPS2;                    
    key2ascii key2ascii (// instantiate key2ascii (project dependency)
        .letter_case(letter_case), 
        .scan_code(scan_code), 
        .ascii_code(ascii_code)
        );
    assign dataPS2 = ascii_code;    
    
    
//    Seven_segment_LED_Display_Controller Seven_segment_LED_Display_Controller (// 7segDisContr
//        .clk(clk), 
//        .reset(reset),  
//        .Anode_Activate(Anode_Activate), 
//        .LED_out(LED_out),
//        .ascii_code(ascii_code)
//        );

/////////////////////////////////////////////////////////////////////////////////////////////////                                   

//#############################################################################################//
////////////////////////////////   Begin System Description   ///////////////////////////////////
////////////////////////////////      Dataflow Modeling       ///////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////
//FSM next state logic
always @* // any change in the input signals will trigger the state machine case statement
    begin

    // defaults
    got_code_tick   = 1'b0;
    letter_case     = 1'b0;
    caps_num_next   = caps_num_reg;
    shift_type_next = shift_type_reg;
    state_next      = state_reg;

    case(state_reg)
    /////////////////////////////////////////////////////////////////////////////////////////////
    // State 1: Processes lwrcase key strokes, go to uppercase state to process shift/capslock //
    /////////////////////////////////////////////////////////////////////////////////////////////
       lowercase:
       begin
        if(scan_done_tick)                        // if scan code received
            begin
            if(scan_out == SHIFT1 || scan_out == SHIFT2) // if code is shift
                begin
                shift_type_next = scan_out;       // record which shift key was pressed
                state_next = shift;               // go to shift state
                end
            else if(scan_out == CAPS)             // if code is capslock
                begin                             // set caps_num to 3, num of capslock scancodes
                caps_num_next = 2'b11;            // to receive before going back to lwrCase               
                state_next = capslock;            // go to capslock state
                end
            else if (scan_out == BREAK)           // else if code is break code
                state_next = ignore_break;        // go to ignore_break state
            else                                  // else if code is none of the above
                got_code_tick = 1'b1;             // assert got_code_tick 2 write scan_out 2 FIFO
            end
        end

    /////////////////////////////////////////////////////////////////////////////////////////////
    // State 2: Ignores repeated scan code after break code FO received in lowercase state   // 
    /////////////////////////////////////////////////////////////////////////////////////////////
       ignore_break:
       begin
        if(scan_done_tick) state_next = lowercase;// if scancode received, goback 2 lwrCase state 
       end

    /////////////////////////////////////////////////////////////////////////////////////////////
    // State 3: Processes scan codes after shift received in lowercase state                   //
    /////////////////////////////////////////////////////////////////////////////////////////////
       shift:
       begin
           letter_case = 1'b1;                      // routed out to convert scan code to
                                                    // upper value for a key
           if(scan_done_tick)                       // if scan code received,
           begin
            if(scan_out == BREAK)                   // if code is break code                      
                state_next = ignore_shift_break;    // go to ignore_shift_break state to
                                                    // ignore repeated scan code after F0
            // else if code is not shift/capslock
            else if(scan_out != SHIFT1 && scan_out != SHIFT2 && scan_out != CAPS)
                got_code_tick = 1'b1;               // assert got_code_tick 2 write scan_out 2 FIFO
           end
       end
    
     /////////////////////////////////////////////////////////////////////////////////////////////
     // State 4: Ignores repeated scan code after break code F0 received in shift state         //
     /////////////////////////////////////////////////////////////////////////////////////////////
        ignore_shift_break:
         begin
         if(scan_done_tick)                      // if scan code received
             begin
             if(scan_out == shift_type_reg)      // if scan code is shift key initially pressed
                 state_next = lowercase;         // shft/capslock key unpressed, goback 2 lwrCase state
             else                                // else repeated scan code received,
             state_next = shift;                 // go back to uppercase state
             end
         end

     /////////////////////////////////////////////////////////////////////////////////////////////
     // State 5: Processes scan codes after capslock code received in lowecase state            //
     /////////////////////////////////////////////////////////////////////////////////////////////
        capslock:
         begin
         letter_case = 1'b1;                                    // routed out to convert scan code
                                                                // to upper value for a key
         if(caps_num_reg == 0)                                  // if capslock code received 3 times,
             state_next = lowercase;                            // go back to lowecase state
         if(scan_done_tick)                                     // if scan code received
             begin
             if(scan_out == CAPS)                               // if code is capslock,
                caps_num_next = caps_num_reg - 1;               // decrement caps_num
             else if(scan_out == BREAK)                         // else if code is break,
                state_next = ignore_caps_break;                 // go to ignore_caps_break state
             else if(scan_out != SHIFT1 && scan_out != SHIFT2)  // else if code isn't a shift key
                got_code_tick = 1'b1;                           // assert got_code_tick to
             end                                                // write scan_out to FIFO
         end
     /////////////////////////////////////////////////////////////////////////////////////////////
     // State 6: Ignores repeated scan code after break code F0 received in capslock state      //
     /////////////////////////////////////////////////////////////////////////////////////////////
        ignore_caps_break:
        begin
            if(scan_done_tick)                                  // if scan code received
                begin
                if(scan_out == CAPS)                            // if code is capslock
                    caps_num_next = caps_num_reg - 1;           // decrement caps_num
                    state_next = capslock;                      // return to capslock state
                end
            end
        endcase  
     end                                                        // end @always
//////////////////////////////////////////////////////////////////////////////////////////////////

// output, route letter_case to output to use during scan to ascii code conversion
assign letter_case_out = letter_case;

// output, route got_code_tick to out control circuit to signal when to sample scan_out
assign scan_code_ready = got_code_tick;

// route scan code data out
assign scan_code = (got_code_tick) ? scan_out : 8'hff;

//assign reset = 0;

// Represent ScanCode Via Binary output
// assign led[0] = got_code_tick; //produces no result
//assign led[7:0] = scan_code;  // works


// internal signal declarations for reference
//    reg [2:0] state_reg, state_next;           // FSM state register and next state logic
//    wire [7:0] scan_out;                       // scan code received from keyboard
//    reg [7:0] scan_code_last;                  // Store the last valid scan code
//    reg got_code_tick;                         // asserted to write curr scancode rcvd to FIFO
//    wire scan_done_tick;                       // asserted to signal that ps2_rx has rcvd a scancode
//    reg letter_case;                           // 0=lwrCase, 1=upCase, o/p 2 convert scancode 2 ascii
//    reg [7:0] shift_type_reg, shift_type_next; // register holds scancodes of shiftkeys or capslock
//    reg [1:0] caps_num_reg, caps_num_next;     // tracks num capslockscancodes rcvd in capslock state
//                                               //      (3 before going back to lowecase state)
//    wire [7:0] scan_code;                      // scan_code received from keyboard to process
//    wire scan_code_ready;                      // signal to outer controlsystem to sample scan_code
//    wire letter_case_out;                      // output determines if scan code is converted to 

endmodule



