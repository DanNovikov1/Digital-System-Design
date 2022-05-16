--Original Source: https://github.com/kevinwlu/dsd/tree/master/Nexys-A7/Lab-6
-- VHDL arrays: https://www.nandland.com/vhdl/examples/example-array-type-vhdl.html
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY bat_n_ball IS
    PORT (
        v_sync : IN STD_LOGIC;
        pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        bat_x : IN STD_LOGIC_VECTOR (10 DOWNTO 0); -- current bat x position
        serve : IN STD_LOGIC; -- initiates serve
        red : OUT STD_LOGIC;
        green : OUT STD_LOGIC;
        blue : OUT STD_LOGIC
    );
END bat_n_ball;

ARCHITECTURE Behavioral OF bat_n_ball IS
    CONSTANT ball_count_max : INTEGER := 50; -- Maximum number of balls allowed
    SIGNAL ball_count : INTEGER := 0; -- Current number of balls
    TYPE ball_x_array is array(1 to 50) of std_logic_vector(10 DOWNTO 0); -- x position array
    SIGNAL ball_x_vec : ball_x_array; -- x posision of each ball
    TYPE ball_y_array is array(1 to 50) of std_logic_vector(10 DOWNTO 0); -- y position array
    SIGNAL ball_y_vec : ball_y_array; -- y position of each ball
    
    CONSTANT bsize : INTEGER := 8; -- ball size in pixels
    CONSTANT bat_w : INTEGER := 20; -- bat width in pixels
    CONSTANT bat_h : INTEGER := 20; -- bat height in pixels
    -- distance ball moves each frame
    CONSTANT ball_speed : STD_LOGIC_VECTOR (10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR (6, 11);
    SIGNAL ball_on : STD_LOGIC; -- indicates whether ball is at current pixel position
    SIGNAL bat_on : STD_LOGIC; -- indicates whether bat at over current pixel position
    SIGNAL game_on : STD_LOGIC := '0'; -- indicates whether ball is in play
    
    -- bat vertical position
    CONSTANT bat_y : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(500, 11);
    -- current ball motion - initialized to (+ ball_speed) pixels/frame in both X and Y directions
    --SIGNAL ball_x_motion, ball_y_motion : STD_LOGIC_VECTOR(10 DOWNTO 0) := ball_speed;
    TYPE ball_x_motion_array is array(1 to 50) of std_logic_vector(10 DOWNTO 0);
    SIGNAL ball_x_motion_vec : ball_x_motion_array; -- x posision of each ball
    TYPE ball_y_motion_array is array(1 to 50) of std_logic_vector(10 DOWNTO 0);
    SIGNAL ball_y_motion_vec : ball_y_motion_array; -- y velocity of each ball
    

    
    -- current ball position - intitialized to center of screen
    --SIGNAL ball_x : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(bat_x(0), 11);
    --SIGNAL ball_y : STD_LOGIC_VECTOR(10 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(300, 11);
BEGIN  
    red <= NOT bat_on; -- color setup for red ball and cyan bat on white background
    green <= NOT ball_on;
    blue <= NOT ball_on;
    
    -- process to draw round ball
    -- set ball_on if current pixel address is covered by ball position
    balldraw : PROCESS (ball_x_vec, ball_y_vec, pixel_row, pixel_col, ball_count) IS
        --VARIABLE vx, vy : STD_LOGIC_VECTOR (10 DOWNTO 0); -- 9 downto 0
        TYPE x is array(0 to 50) of STD_LOGIC_VECTOR (10 DOWNTO 0);
        VARIABLE vx : x;
        TYPE y is array(0 to 50) of STD_LOGIC_VECTOR (10 DOWNTO 0);
        VARIABLE vy : y;
    BEGIN
        FOR I in 1 to 50 LOOP
            IF I <= ball_count THEN
                IF pixel_col <= ball_x_vec(I) THEN -- vx = |ball_x - pixel_col|
                    vx(I) := ball_x_vec(I) - pixel_col;
                ELSE
                    vx(I) := pixel_col - ball_x_vec(I);
                END IF;
                IF pixel_row <= ball_y_vec(I) THEN -- vy = |ball_y - pixel_row|
                    vy(I) := ball_y_vec(I) - pixel_row;
                ELSE
                    vy(I) := pixel_row - ball_y_vec(I);
                END IF;
                IF ((vx(I) * vx(I)) + (vy(I) * vy(I))) < (bsize * bsize) THEN -- test if radial distance < bsize
                    ball_on <= game_on;
                ELSE
                    ball_on <= '0';
                END IF;
            END IF;
        END LOOP;
    END PROCESS;
    -- process to draw bat
    -- set bat_on if current pixel address is covered by bat position
    batdraw : PROCESS (bat_x, pixel_row, pixel_col) IS
        VARIABLE vx, vy : STD_LOGIC_VECTOR (10 DOWNTO 0); -- 9 downto 0
    BEGIN
        IF ((pixel_col >= bat_x - bat_w - pixel_row + bat_y) OR (bat_x <= bat_w)) AND
         pixel_col <= (bat_x + bat_w + pixel_row - bat_y) AND
             pixel_row >= bat_y - bat_h AND
             pixel_row <= bat_y + bat_h THEN
                bat_on <= '1';
        ELSE
            bat_on <= '0';
        END IF;
    END PROCESS;
    -- process to move ball once every frame (i.e., once every vsync pulse)
    mball : PROCESS
        TYPE temp_array is array(1 to 50) of STD_LOGIC_VECTOR (11 DOWNTO 0);
        VARIABLE temp : temp_array;
        VARIABLE temp2 : STD_LOGIC_VECTOR (11 DOWNTO 0);
        VARIABLE t : STD_LOGIC_VECTOR (10 DOWNTO 0);
    BEGIN
        WAIT UNTIL rising_edge(v_sync);
        IF serve = '1' AND ball_count <= 50 THEN -- test for new serve
            ball_count <= ball_count + 1;
            game_on <= '1';
            --ball_y_motion <= (NOT ball_speed) + 1; -- set vspeed to (- ball_speed) pixels
            ball_y_motion_vec(ball_count) <= (NOT ball_speed) + 1;
            ball_x_vec(ball_count) <= CONV_STD_LOGIC_VECTOR(bat_x(0), 11);
            ball_y_vec(ball_count) <= CONV_STD_LOGIC_VECTOR(bat_y(0), 11);
        END IF;
        FOR I in 1 to 50 LOOP
            IF I <= ball_count THEN
                IF ball_y_vec(I) <= bsize THEN -- bounce off top wall
                    ball_y_motion_vec(I) <= ball_speed; -- set vspeed to (+ ball_speed) pixels
                ELSIF ball_y_vec(I) + bsize >= 600 THEN -- if ball meets bottom wall
                    ball_y_motion_vec(I) <= (NOT ball_speed) + 1; -- set vspeed to (- ball_speed) pixels
                    --game_on <= '0'; -- and make ball disappear
                    
                    FOR J in I to 49 LOOP -- Remove ball and shift all balls in arrays
                        IF J < ball_count THEN
                            ball_x_vec(J) <= ball_x_vec(J+1);
                            ball_y_vec(J) <= ball_y_vec(J+1);
                            ball_x_motion_vec(J) <= ball_x_motion_vec(J+1);
                            ball_y_motion_vec(J) <= ball_y_motion_vec(J+1);
                        ELSE
                           ball_x_vec(J) <= CONV_STD_LOGIC_VECTOR(bat_x(0), 11);
                           ball_y_vec(J) <= CONV_STD_LOGIC_VECTOR(bat_y(0), 11);
                           ball_x_motion_vec(J) <= CONV_STD_LOGIC_VECTOR(0, 11);
                           ball_y_motion_vec(J) <= CONV_STD_LOGIC_VECTOR(0, 11); 
                        END IF;
                    END LOOP;
                    ball_count <= ball_count - 1;
                END IF;
                -- allow for bounce off left or right of screen
                IF ball_x_vec(I) + bsize >= 800 THEN -- bounce off right wall
                    ball_x_motion_vec(I) <= (NOT ball_speed) + 1; -- set hspeed to (- ball_speed) pixels
                ELSIF ball_x_vec(I) <= bsize THEN -- bounce off left wall
                    ball_x_motion_vec(I) <= ball_speed; -- set hspeed to (+ ball_speed) pixels
                END IF;
            
                -- allow for bounce off bat
                IF (ball_x_vec(I) + bsize/2) >= (bat_x - bat_w) AND
                (ball_x_vec(I) - bsize/2) <= (bat_x + bat_w) AND
                (ball_y_vec(I) + bsize/2) >= (bat_y - bat_h) AND
                (ball_y_vec(I) - bsize/2) <= (bat_y + bat_h) THEN
                    ball_y_motion_vec(I) <= (NOT ball_speed) + 1; -- set vspeed to (- ball_speed) pixels
                END IF;
                -- compute next ball vertical position
                -- variable temp adds one more bit to calculation to fix unsigned underflow problems
                -- when ball_y is close to zero and ball_y_motion is negative
                t :=  ball_y_motion_vec(I);
                temp(I) := ('0' & ball_y_vec(I)) + (t(10) & ball_y_motion_vec(I));
                temp2 := temp(I);
                IF game_on = '0' THEN
                    ball_y_vec(I) <= CONV_STD_LOGIC_VECTOR(440, 11);
                ELSIF temp2(11) = '1' THEN
                    ball_y_vec(I) <= (OTHERS => '0');
                ELSE ball_y_vec(I) <= temp2(10 DOWNTO 0); -- 9 downto 0
                END IF;
                        
                -- compute next ball horizontal position
                -- variable temp adds one more bit to calculation to fix unsigned underflow problems
                -- when ball_x is close to zero and ball_x_motion is negative
                t := ball_x_motion_vec(I);
                temp(I) := ('0' & ball_x_vec(I)) + (t(10) & ball_x_motion_vec(I));
                temp2 := temp(I);
                IF temp2(11) = '1' THEN
                    ball_x_vec(I) <= (OTHERS => '0');
                ELSE ball_x_vec(I) <= temp2(10 DOWNTO 0);
                END IF;
            END IF;
        END LOOP;
    END PROCESS;
END Behavioral;
