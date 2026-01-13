`timescale 1ns / 1ps

module Top_Level_tb;
    //========================================================================
    // TESTBENCH SIGNALS
    //========================================================================
    // Clock and Reset
    logic clk_i;
    logic rst_i;
    
    // DUT Inputs
    logic [31:0] data_i;
    logic data_valid_i;
    logic data_last_i;
    logic [31:0] polynomial_i;
    
    // DUT Outputs
    logic [31:0] crc_o;
    logic crc_valid_o;
    
    // Testbench Control
    int test_count;
    int pass_count;
    int fail_count;
    
    // Testbench Memory
    logic [255:0] test_sequence;
    int shift_count;
    logic [31:0] crc_result;
    
    //========================================================================
    // CLOCK GENERATION (200MHz = 5ns period)
    //========================================================================
    initial begin
        clk_i = 0;
        forever #2.5 clk_i = ~clk_i;
    end
    
    //========================================================================
    // DUT INSTANTIATION
    //========================================================================
    
    Top_Level dut(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .data_i(data_i),
        .data_valid_i(data_valid_i),
        .data_last_i(data_last_i),
        .polynomial_i(polynomial_i),
        .crc_o(crc_o),
        .crc_valid_o(crc_valid_o)
    );
    
    //========================================================================
    // TASKS - Reusable test procedures
    //========================================================================
    
    // Task: Apply Reset
    task automatic apply_reset();
        begin
            $display("[%0t] Applying reset...", $time);
            rst_i = 1;
            data_valid_i = 0;
            data_i = 0;
            repeat(5) @(posedge clk_i);
            rst_i = 0;
            @(posedge clk_i);
            $display("[%0t] Reset Complete", $time);
        end
    endtask
    
    // Task: Send CRC Data to System
    task automatic send_data(input [255:0] data, input [31:0] polynomial);
        begin
            for (int i = 0; i < 8; i++) begin
                @(posedge clk_i);
                data_i = data[i*32 +: 32];  // Indexed part-select
                polynomial_i = polynomial;
                data_valid_i = 1;
                data_last_i = (i == 7);  // Assert on last transfer
            end
            @(posedge clk_i);
            data_valid_i = 0;
            data_i = 0;
            data_last_i = 0;
            $display("[%0t] Sent data: 0x%h with polynomial: 0x%h",
                $time, data, polynomial); 
        end
    endtask
    
    // Task: Wait for CRC output
    task automatic wait_for_crc(output [31:0] crc_result);
        begin
            // Wait for crc_valid_o to assert
            fork
                begin
                    wait(crc_valid_o == 1);
                    @(posedge clk_i);
                    crc_result = crc_o;
                    $display("[%0t] CRC output received: 0x%h", $time, crc_result);
                end
                begin
                    repeat(20) @(posedge clk_i);  // Timeout after 20 cycles
                    $display("[%0t] WARNING: Timeout waiting for CRC", $time);
                end
            join_any
            disable fork;
        end
    endtask
    
    // Task: Check result
    task automatic check_result(input [31:0] expected, input [31:0] actual, 
                                input string test_name);
        begin
            test_count++;
            if (expected == actual) begin
                $display("[%0t] ? PASS: %s", $time, test_name);
                $display("        Expected: 0x%h, Got: 0x%h", expected, actual);
                pass_count++;
            end else begin
                $display("[%0t] ? FAIL: %s", $time, test_name);
                $display("        Expected: 0x%h, Got: 0x%h", expected, actual);
                fail_count++;
            end
        end
    endtask
    
    //========================================================================
    // TEST SCENARIOS
    //========================================================================
    initial begin
        // Initialize counters
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Initialize inputs
        rst_i = 0;
        data_i = 0;
        data_valid_i = 0;
        polynomial_i = 0;
        
        $display("========================================");
        $display("  CRC32 Engine Testbench");
        $display("========================================");
        
        //--------------------------------------------------------------------
        // TEST 1: Reset Test
        //--------------------------------------------------------------------
        $display("\n--- TEST 1: Reset Functionality ---");
        apply_reset();
        @(posedge clk_i);
        
        if (crc_o == 0 && crc_valid_o == 0) begin
            $display("[%0t] ? PASS: Reset test - outputs cleared", $time);
            pass_count++;
        end else begin
            $display("[%0t] ? FAIL: Reset test - outputs not cleared", $time);
            fail_count++;
        end
        test_count++;
        
        //--------------------------------------------------------------------
        // TEST 2: Simple Data Test with Standard CRC32 Polynomial
        //--------------------------------------------------------------------
        $display("\n--- TEST 2: Simple Data Test ---");
        
        
        // Standard CRC32 polynomial (Ethernet): 0x04C11DB7
        send_data(256'h1234567890ABCDEF, 32'h04C11DB7);
        
        wait_for_crc(crc_result);
        check_result(32'h46fd7aa9, crc_result, "Simple Data CRC Test");
        $display("[%0t] INFO: CRC calculation completed", $time);
        
        //--------------------------------------------------------------------
        // TEST 3: All Zeros Data
        //--------------------------------------------------------------------
        $display("\n--- TEST 3: All Zeros Data ---");
        send_data(256'h0, 32'h04C11DB7);
        wait_for_crc(crc_result);
        check_result(32'ha008d0fb, crc_result, "All zeros CRC");
        
        //--------------------------------------------------------------------
        // TEST 4: Reset During Operation
        //--------------------------------------------------------------------
        $display("\n--- TEST 4: Reset During Operation ---");
        send_data(256'hAAAAAAAA, 32'h04C11DB7);
        repeat(2) @(posedge clk_i);
        apply_reset();
        
        if (crc_o == 0) begin
            $display("[%0t] ? PASS: Reset during operation clears outputs", $time);
            pass_count++;
        end else begin
            $display("[%0t] ? FAIL: Reset during operation failed", $time);
            fail_count++;
        end
        test_count++;
        
        //--------------------------------------------------------------------
        // TEST SUMMARY
        //--------------------------------------------------------------------
        repeat(10) @(posedge clk_i);
        
        $display("\n========================================");
        $display("  TEST SUMMARY");
        $display("========================================");
        $display("Total Tests:  %0d", test_count);
        $display("Passed:       %0d", pass_count);
        $display("Failed:       %0d", fail_count);
        $display("Pass Rate:    %0.1f%%", (pass_count * 100.0) / test_count);
        $display("========================================\n");
        
        if (fail_count == 0) begin
            $display("? ALL TESTS PASSED!");
        end else begin
            $display("? SOME TESTS FAILED");
        end
        
        $finish;
   end
   
   //========================================================================
    // TIMEOUT WATCHDOG
    //========================================================================
    initial begin
        #100000;  // 100us timeout
        $display("\n[ERROR] Simulation timeout!");
        $finish;
    end
    
endmodule
