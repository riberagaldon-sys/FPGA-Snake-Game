`timescale 1ns/1fs

// Teaching-manual Chapter 11 -> chapter10_snake_200t.xpr.
// Simulation top: tb_chapter11_all. Run 200 us. Expected: CH11 PASS.
// Real project hierarchy: dut (game_system_5slot) -> u_game2_snake.
// Root aliases expose array elements as head_x/y, body1/2/3_x/y, tail_x/y.
// Clock 51.2 MHz; the original MOVE_TICK_DIV=10, 25x13 grid, 32-pixel cells
// and MAX_LEN=128 are retained. Original initial snake length is FOUR.
// Only simulation FOOD_X_INIT/Y_INIT are overridden from (18,8) to (7,6)
// so a normal first movement eats food. No RTL edits, forces or register
// deposits are used. All body/self/wall tests use the public event ports.
// game_tick is an accelerated port stimulus, not a 60 Hz timing measurement.
// This is a game-interface simulation, not PS/2/I2C/MMCM/LCD/board testing.
// Internal display-copy checks use the actual zero-coordinate condition;
// that condition is not a genuine single-cycle LCD frame_start.
// No $finish/$stop: keep the Vivado waveform window open for screenshots.
//
// Figure 11-1: 2.5..27.5 us. Direction events, accepted_direction, direction,
//              pending_direction, turn_locked, game_tick, move_enable,
//              move_div_count. Direction: 0 up, 1 down, 2 left, 3 right.
// Figure 11-2: first movement/eating near 5.8 us (use 5.7..6.2 us).
//              state_live, shift_index, check_index, head/body/tail aliases,
//              old_tail_x/y, snake_len, score_live, food_x/y.
// Internal states: 0 READY, 1 RUN, 2 SHIFT, 3 CHECK, 4 EAT, 5 RESPAWN,
//                  6 PAUSED, 7 DEAD.
// Display game_state codes: 0 READY, 1 RUN, 2 PAUSED, 4 DEAD.

module tb_chapter11_all;
    reg clk = 1'b0;
    always #9.765625 clk = ~clk;
    reg rst_n = 1'b0;
    reg [2:0] ui_state_control = 3'd3;
    reg [2:0] ui_state_frame = 3'd3;
    reg event_up = 1'b0;
    reg event_down = 1'b0;
    reg event_left = 1'b0;
    reg event_right = 1'b0;
    reg event_ok = 1'b0;
    reg event_back = 1'b0;
    reg event_pause = 1'b0;
    reg game_tick = 1'b0;
    reg [10:0] pixel_x = 11'd128;
    reg [9:0] pixel_y = 10'd128;
    wire pixel_on;
    wire [23:0] pixel_rgb;
    wire [15:0] score;
    wire [3:0] game_state;
    wire exit_request;

    game_system_5slot dut (
        .clk(clk), .rst_n(rst_n),
        .ui_state_control(ui_state_control), .ui_state_frame(ui_state_frame),
        .event_up(event_up), .event_down(event_down),
        .event_left(event_left), .event_right(event_right),
        .event_ok(event_ok), .event_back(event_back),
        .event_pause(event_pause), .game_tick(game_tick), .tick_1s(1'b0),
        .pointer_x(11'd0), .pointer_y(10'd0), .pointer_down(1'b0),
        .pixel_x(pixel_x), .pixel_y(pixel_y), .pixel_on(pixel_on),
        .pixel_rgb(pixel_rgb), .score(score), .game_state(game_state),
        .exit_request(exit_request)
    );
    defparam dut.u_game2_snake.FOOD_X_INIT = 5'd7;
    defparam dut.u_game2_snake.FOOD_Y_INIT = 4'd6;

    wire [4:0] enable = dut.enable;
    wire game_enable = enable[1];
    wire [3:0] state_live = dut.u_game2_snake.state_live;
    wire [15:0] score_live = dut.u_game2_snake.score_live;
    wire [7:0] snake_len = dut.u_game2_snake.snake_len;
    wire [4:0] food_x = dut.u_game2_snake.food_x;
    wire [3:0] food_y = dut.u_game2_snake.food_y;
    wire [2:0] direction = dut.u_game2_snake.direction;
    wire [2:0] pending_direction = dut.u_game2_snake.pending_direction;
    wire [2:0] accepted_direction = dut.u_game2_snake.accepted_direction;
    wire turn_locked = dut.u_game2_snake.turn_locked;
    wire [7:0] move_div_count = dut.u_game2_snake.move_div_count;
    // Observation of the original movement-launch condition, not a new port.
    wire move_enable = game_enable && state_live == 1
                    && game_tick && move_div_count == 9;
    wire [4:0] candidate_head_x = dut.u_game2_snake.candidate_head_x;
    wire [3:0] candidate_head_y = dut.u_game2_snake.candidate_head_y;
    wire candidate_wall_hit = dut.u_game2_snake.candidate_wall_hit;
    wire [4:0] new_head_x = dut.u_game2_snake.new_head_x;
    wire [3:0] new_head_y = dut.u_game2_snake.new_head_y;
    wire [4:0] old_tail_x = dut.u_game2_snake.old_tail_x;
    wire [3:0] old_tail_y = dut.u_game2_snake.old_tail_y;
    wire [7:0] shift_index = dut.u_game2_snake.shift_index;
    wire [7:0] check_index = dut.u_game2_snake.check_index;
    wire collision_seen = dut.u_game2_snake.collision_seen;
    wire check_match = dut.u_game2_snake.check_match;
    wire [4:0] head_x = dut.u_game2_snake.snake_x[0];
    wire [3:0] head_y = dut.u_game2_snake.snake_y[0];
    wire [4:0] body1_x = dut.u_game2_snake.snake_x[1];
    wire [3:0] body1_y = dut.u_game2_snake.snake_y[1];
    wire [4:0] body2_x = dut.u_game2_snake.snake_x[2];
    wire [3:0] body2_y = dut.u_game2_snake.snake_y[2];
    wire [4:0] body3_x = dut.u_game2_snake.snake_x[3];
    wire [3:0] body3_y = dut.u_game2_snake.snake_y[3];
    wire [4:0] body4_x = dut.u_game2_snake.snake_x[4];
    wire [3:0] body4_y = dut.u_game2_snake.snake_y[4];
    wire [4:0] tail_x = dut.u_game2_snake.snake_x[snake_len-8'd1];
    wire [3:0] tail_y = dut.u_game2_snake.snake_y[snake_len-8'd1];

    integer case_id = 0;
    integer errors = 0;
    integer direction_tests = 0;
    integer growth_tests = 0;
    integer completed_moves = 0;
    integer self_collision_tests = 0;
    integer wall_tests = 0;
    integer pause_tests = 0;
    integer restart_tests = 0;
    reg checks_done = 1'b0;
    reg checks_pass = 1'b0;

    task check;
        input condition;
        input [767:0] message;
        begin
            if (condition !== 1'b1) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("CH11 FAIL at %0.6f us: %0s", $realtime/1000.0, message);
            end
        end
    endtask

    task at_us;
        input integer target_us;
        real delay_ns;
        begin
            delay_ns = target_us * 1000.0 - $realtime;
            if (delay_ns > 0) #(delay_ns);
            @(negedge clk);
        end
    endtask

    // Mask bits: up/down/left/right/OK/Back/pause/game_tick.
    task pulse;
        input [7:0] mask;
        begin
            @(negedge clk);
            {game_tick,event_pause,event_back,event_ok,
             event_right,event_left,event_down,event_up} = mask;
            #0.001;
            if (mask[5]) begin
                check(dut.u_game2_snake.exit_request === game_enable,
                      "snake Back exit gating failed");
                check(exit_request === (|enable), "system Back exit gating failed");
            end
            @(negedge clk);
            {game_tick,event_pause,event_back,event_ok,
             event_right,event_left,event_down,event_up} = 8'd0;
            #0.001;
        end
    endtask

    // One pulse every ten clock periods; only the launch pulse occurs
    // after ten base ticks because MOVE_TICK_DIV remains its actual value 10.
    task ticks;
        input integer count;
        integer k;
        begin
            for (k = 0; k < count; k = k + 1) begin
                pulse(8'h80);
                repeat (8) @(negedge clk);
            end
            #0.001;
        end
    endtask

    task wait_move_done;
        integer waited;
        begin
            waited = 0;
            while (state_live != 1 && state_live != 7 && waited < 5000) begin
                @(negedge clk); waited = waited + 1;
            end
            #0.001;
            check(state_live == 1 || state_live == 7, "movement/food respawn did not finish");
        end
    endtask

    task check_initial_body;
        begin
            check(snake_len == 4 && score_live == 0 && direction == 3
               && pending_direction == 3 && !turn_locked && move_div_count == 0,
                  "initial length/score/direction/lock/divider mismatch");
            check(head_x == 6 && body1_x == 5 && body2_x == 4 && body3_x == 3
               && head_y == 6 && body1_y == 6 && body2_y == 6 && body3_y == 6
               && food_x == 7 && food_y == 6, "initial snake/food coordinates mismatch");
        end
    endtask

    task fresh_game;
        begin
            @(negedge clk); ui_state_control = 0;
            repeat (3) @(negedge clk);
            check(state_live == 0 && !game_enable, "disabled slot failed to enter READY");
            check_initial_body();
            ui_state_control = 3;
            pulse(8'h10);
            check(state_live == 1 && enable == 5'b00010, "second-slot start/selection failed");
        end
    endtask

    // Reference model snapshots the OLD body before a complete move.
    // It checks positions after the multi-cycle transaction has finished.
    reg [4:0] old_x [0:127];
    reg [3:0] old_y [0:127];
    integer old_len;
    integer old_score;
    integer expected_x;
    integer expected_y;
    integer old_food_x;
    integer old_food_y;
    reg expected_wall;
    reg expected_self;
    reg expected_eat;
    integer ref_i;
    integer ref_j;
    task move_one;
        begin
            check(state_live == 1 && move_div_count == 0, "move test began outside a fresh RUN period");
            old_len = snake_len; old_score = score_live;
            old_food_x = food_x; old_food_y = food_y;
            for (ref_i = 0; ref_i < old_len; ref_i = ref_i + 1) begin
                old_x[ref_i] = dut.u_game2_snake.snake_x[ref_i];
                old_y[ref_i] = dut.u_game2_snake.snake_y[ref_i];
            end
            expected_x = old_x[0]; expected_y = old_y[0];
            case (accepted_direction)
                0: expected_y = expected_y - 1;
                1: expected_y = expected_y + 1;
                2: expected_x = expected_x - 1;
                3: expected_x = expected_x + 1;
                default: check(1'b0, "invalid accepted direction");
            endcase
            expected_wall = expected_x < 0 || expected_x >= 25
                         || expected_y < 0 || expected_y >= 13;
            expected_self = 1'b0;
            for (ref_i = 0; ref_i < old_len-1; ref_i = ref_i + 1)
                if (old_x[ref_i] == expected_x && old_y[ref_i] == expected_y)
                    expected_self = 1'b1;
            expected_eat = expected_x == old_food_x && expected_y == old_food_y;
            ticks(10);
            wait_move_done();
            if (expected_wall) begin
                check(state_live == 7 && head_x == old_x[0] && head_y == old_y[0],
                      "wall collision did not stop without committing an out-of-grid head");
                wall_tests = wall_tests + 1;
            end else begin
                check(head_x == expected_x && head_y == expected_y, "new head moved to the wrong grid cell");
                for (ref_i = 1; ref_i < old_len; ref_i = ref_i + 1)
                    check(dut.u_game2_snake.snake_x[ref_i] == old_x[ref_i-1]
                       && dut.u_game2_snake.snake_y[ref_i] == old_y[ref_i-1],
                          "body did not shift from the old preceding segment");
                check(old_tail_x == old_x[old_len-1] && old_tail_y == old_y[old_len-1],
                      "old tail was not saved before the body shift");
                if (expected_self) begin
                    check(state_live == 7 && score_live == old_score,
                          "self collision did not enter DEAD without scoring");
                    self_collision_tests = self_collision_tests + 1;
                end else if (expected_eat) begin
                    check(state_live == 1 && score_live == old_score+1
                       && snake_len == old_len+1, "eating did not grow/score exactly once");
                    check(dut.u_game2_snake.snake_x[old_len] == old_x[old_len-1]
                       && dut.u_game2_snake.snake_y[old_len] == old_y[old_len-1],
                          "growth failed to append the saved old tail");
                    growth_tests = growth_tests + 1;
                end else check(state_live == 1 && score_live == old_score && snake_len == old_len,
                               "ordinary movement changed score/length or failed to return RUN");
                if (state_live == 1) begin
                    check(food_x < 25 && food_y < 13, "respawned food is outside the grid");
                    for (ref_i = 0; ref_i < snake_len; ref_i = ref_i + 1) begin
                        check(dut.u_game2_snake.snake_x[ref_i] < 25
                           && dut.u_game2_snake.snake_y[ref_i] < 13,
                              "completed snake body is outside the grid");
                        check(!(dut.u_game2_snake.snake_x[ref_i] == food_x
                             && dut.u_game2_snake.snake_y[ref_i] == food_y),
                              "respawned food landed on the snake");
                        for (ref_j = 0; ref_j < ref_i; ref_j = ref_j + 1)
                            check(dut.u_game2_snake.snake_x[ref_i] != dut.u_game2_snake.snake_x[ref_j]
                               || dut.u_game2_snake.snake_y[ref_i] != dut.u_game2_snake.snake_y[ref_j],
                                  "completed live snake has overlapping segments");
                    end
                end
            end
            check(move_div_count == 0 && !turn_locked, "movement failed to reset divider/turn lock");
            completed_moves = completed_moves + 1;
            $display("CH11 MOVE %0d at %0.6f us: head=(%0d,%0d) len=%0d score=%0d state=%0d",
                     completed_moves,$realtime/1000.0,head_x,head_y,snake_len,score_live,state_live);
        end
    endtask

    task snapshot_once;
        integer m;
        begin
            @(negedge clk); pixel_x = 0; pixel_y = 0;
            @(negedge clk); pixel_x = 128; pixel_y = 128;
            #0.001;
            check(dut.u_game2_snake.snake_len_frame == snake_len
               && score == score_live && game_state == dut.u_game2_snake.visible_state_live,
                  "local display state did not copy at zero coordinates");
            for (m = 0; m < snake_len; m = m + 1)
                check(dut.u_game2_snake.snake_x_frame[m] == dut.u_game2_snake.snake_x[m]
                   && dut.u_game2_snake.snake_y_frame[m] == dut.u_game2_snake.snake_y[m],
                      "local displayed body copy mismatch");
        end
    endtask

    integer n;
    reg [4:0] saved_head_x;
    reg [3:0] saved_head_y;
    reg [7:0] saved_len;
    reg [15:0] saved_score;
    initial begin
        at_us(1); rst_n = 1'b1;
        check(state_live == 0, "reset did not enter READY"); check_initial_body();
        at_us(2); pulse(8'h10);
        check(state_live == 1, "OK did not start RUN");

        // Figure 11-1: direct reverse; valid turn; another turn while locked.
        at_us(3); case_id = 1; pulse(8'h04);
        check(direction == 3 && accepted_direction == 3 && !turn_locked,
              "RIGHT-to-LEFT reverse was accepted"); direction_tests = direction_tests + 1;
        at_us(4); move_one();
        check(head_x == 7 && head_y == 6 && snake_len == 5 && score_live == 1,
              "first normal step did not eat the initial food");

        at_us(10); case_id = 2; pulse(8'h02);
        check(direction == 3 && accepted_direction == 1 && pending_direction == 1 && turn_locked,
              "valid DOWN request was not accepted/locked"); direction_tests = direction_tests + 1;
        at_us(12); case_id = 3; pulse(8'h01);
        check(direction == 3 && accepted_direction == 1 && pending_direction == 1 && turn_locked,
              "second turn replaced a locked DOWN request"); direction_tests = direction_tests + 1;
        at_us(14); move_one();
        check(direction == 1 && head_x == 7 && head_y == 7, "DOWN move/direction commit failed");

        at_us(18); case_id = 4; pulse(8'h01);
        check(direction == 1 && accepted_direction == 1 && !turn_locked,
              "DOWN-to-UP reverse was accepted"); direction_tests = direction_tests + 1;
        at_us(20); case_id = 5; pulse(8'h08);
        check(direction == 1 && accepted_direction == 3 && turn_locked,
              "valid RIGHT request was not accepted/locked"); direction_tests = direction_tests + 1;
        at_us(22); case_id = 6; pulse(8'h04);
        check(direction == 1 && accepted_direction == 3 && pending_direction == 3 && turn_locked,
              "second turn replaced a locked RIGHT request"); direction_tests = direction_tests + 1;
        at_us(24); move_one();
        check(direction == 3 && head_x == 8 && head_y == 7, "RIGHT move/direction commit failed");

        at_us(28); case_id = 7; ticks(3);
        check(move_div_count == 3 && head_x == 8 && head_y == 7, "divider moved before ten ticks");
        at_us(30); pulse(8'h40);
        saved_head_x = head_x; saved_head_y = head_y;
        saved_len = snake_len; saved_score = score_live;
        check(state_live == 6 && move_div_count == 0 && !turn_locked, "pause did not reset its timing/lock");
        at_us(32); pulse(8'h01); ticks(12);
        check(state_live == 6 && head_x == saved_head_x && head_y == saved_head_y
           && snake_len == saved_len && score_live == saved_score && move_div_count == 0,
              "paused snake responded to base ticks/direction events");
        snapshot_once(); check(game_state == 2, "display PAUSED code is not 2");
        at_us(36); pulse(8'h40);
        check(state_live == 1 && move_div_count == 0, "resume did not start a fresh divider period");
        at_us(38); ticks(9);
        check(move_div_count == 9 && head_x == saved_head_x && head_y == saved_head_y,
              "resume moved before its tenth tick");
        at_us(40); ticks(1); wait_move_done();
        check(head_x == saved_head_x+1 && head_y == saved_head_y && move_div_count == 0,
              "resume failed to move on exactly the tenth tick"); pause_tests = pause_tests + 1;

        // A normal four-move U-shaped route after eating creates self contact.
        at_us(50); case_id = 8; fresh_game();
        at_us(52); move_one(); // head (7,6), length 5
        at_us(56); pulse(8'h02); move_one(); // (7,7)
        at_us(60); pulse(8'h04); move_one(); // (6,7)
        at_us(64); case_id = 9; pulse(8'h01); move_one(); // (6,6) hits body
        check(state_live == 7 && head_x == 6 && head_y == 6, "natural route did not create self collision");
        snapshot_once(); check(game_state == 4, "display DEAD code is not 4");
        pulse(8'h88);
        check(state_live == 7 && head_x == 6 && head_y == 6, "DEAD responded to movement");

        at_us(68); case_id = 10; pulse(8'h10);
        check(state_live == 0, "first OK after death did not return READY"); check_initial_body();
        at_us(70); pulse(8'h10);
        check(state_live == 1, "second OK did not start a clean game"); restart_tests = restart_tests + 1;

        // Reach the right edge using real movements, then request one more.
        at_us(72); case_id = 11;
        for (n = 0; n < 18; n = n + 1) move_one();
        check(head_x == 24 && head_y == 6 && state_live == 1,
              "straight run failed to reach the right edge");
        case_id = 12; move_one();
        check(state_live == 7 && head_x == 24 && head_y == 6 && candidate_wall_hit,
              "right wall collision failed");
        snapshot_once();
        pixel_x = 512; pixel_y = 280; #0.001;
        check(game_state == 4 && pixel_rgb == 24'hA83A3A, "DEAD display color/state mismatch");

        at_us(120); case_id = 13; pulse(8'h10);
        check(state_live == 0, "wall death did not return READY on first OK"); check_initial_body();
        pulse(8'h10); check(state_live == 1, "wall restart did not start RUN"); restart_tests = restart_tests + 1;
        // A same-clock turn and tenth base tick use the accepted direction.
        at_us(122); ticks(9);
        pulse(8'h81); wait_move_done();
        check(direction == 0 && head_x == 6 && head_y == 5 && move_div_count == 0 && !turn_locked,
              "same-cycle direction/final-tick request was lost");

        at_us(130); case_id = 14; fresh_game(); snapshot_once();
        // Physical pixels corresponding to the centres of logical cells.
        pixel_x = 320; pixel_y = 272; #0.001;
        check(pixel_on && pixel_rgb == 24'hF4F4F4, "head color/second-slot output mux mismatch");
        pixel_x = 288; #0.001; check(pixel_rgb == 24'h62D394, "body pixel color mismatch");
        pixel_x = 352; #0.001; check(pixel_rgb == 24'hFF5A4F, "food pixel color mismatch");
        pixel_x = 111; pixel_y = 100; #0.001;
        check(pixel_rgb == 24'h6BCB9A, "board border color mismatch");
        pixel_x = 32; #0.001; check(pixel_rgb == 24'h101820, "outside-board color mismatch");
        pixel_x = 128; pixel_y = 128;
        move_one();
        check(dut.u_game2_snake.snake_x_frame[0] == 6
           && dut.u_game2_snake.snake_len_frame == 4 && score == 0,
              "displayed body changed with nonzero pixel coordinates");
        snapshot_once();
        check(dut.u_game2_snake.snake_x_frame[0] == 7
           && dut.u_game2_snake.snake_len_frame == 5 && score == 1,
              "next zero-coordinate copy missed completed growth");

        at_us(140); case_id = 15; pulse(8'h20);
        // The game's Back output is a request; page selection is the controller's job.
        check(state_live == 1, "standalone Back incorrectly changed snake state");
        @(negedge clk); ui_state_control = 2; // activate treasure, disable snake
        pulse(8'h9F);
        check(state_live == 0 && enable == 5'b00001 && !game_enable,
              "unselected snake slot consumed another slot's events"); check_initial_body();
        pulse(8'h20);
        check(!dut.u_game2_snake.exit_request, "disabled snake requested exit");

        at_us(160); case_id = 16; rst_n = 1'b0;
        #0.001;
        check(state_live == 0 && dut.u_game2_snake.state_frame == 0,
              "asynchronous reset failed to restore live/display READY"); check_initial_body();
        at_us(161); rst_n = 1'b1;
        at_us(195);
        check(direction_tests == 6 && growth_tests >= 2 && self_collision_tests == 1
           && wall_tests == 1 && pause_tests == 1 && restart_tests == 2,
              "a required direction/growth/collision/pause/restart test was skipped");
        checks_done = 1'b1;
        checks_pass = (errors == 0);
        if (checks_pass)
            $display("CH11 PASS: directions=%0d growth=%0d self=%0d wall=%0d pause=%0d restarts=%0d errors=%0d",
                     direction_tests,growth_tests,self_collision_tests,wall_tests,pause_tests,restart_tests,errors);
        else $display("CH11 FAIL: errors=%0d", errors);
    end
endmodule
