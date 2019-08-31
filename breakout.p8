pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- main

function _init()
	cls()
	mode="start"
end

function _update60()
	if mode=="game" then
		update_game()
	elseif mode=="start" then
		update_start()
	elseif mode=="gameover" then
		update_gameover()
	end
end

function _draw()
	if mode=="game" then
		draw_game()
	elseif mode=="start" then
		draw_start()
	elseif mode=="gameover" then
		draw_gameover()
	end
end
-->8
-- modes

-- main setup for game
function start_game()
	mode="game"
	lives=3
	score=0
	init_paddle()
	init_ball()
	init_bricks()
end

-- update the peons
function update_game()
	update_paddle()
	update_ball()
	update_bricks()
end

-- lose life and handle gameover
function lose_life()
		sfx(2)
		lives -= 1
		wait(20)
		
		if lives > 0 then
			serve_ball()
		else
			mode="gameover"
		end
end

-- only start from ❎
function update_start()
	if btn(❎) then
	 start_game()
	end
end

-- only continue from ❎
function update_gameover()
	if btn(❎) then
		start_game()
	end
end

-- main game draw function
function draw_game()
	cls(1)
	draw_hud()
	draw_bricks()
	draw_paddle()
	draw_ball()
end

-- todo: move to different tab?
-- draw the hud on the game
function draw_hud()
	rectfill(0,0,127,7,0)
	for i=0,lives-1 do
		print("♥",118-i*7,0,8)
	end
	print("score: "..score,2,0,7)
end

-- start mode text
function draw_start()
	local text1="welcome to breakout"
	local text2="press ❎ to start"
	print(text1,hcenter(text1),vcenter()-7,7)
	print(text2,hcenter(text2),vcenter()+7,11)
end

-- gameover mode text
function draw_gameover()
	-- clear hearts on game over
	rectfill(115,0,127,7,0)
	
	-- bar in the middle for text
	rectfill(0,vcenter()-11,127,vcenter()+15,0)
	
	local text1="game over"
	local text2="press ❎ to restart"
	print(text1,hcenter(text1),vcenter()-7,8)
	print(text2,hcenter(text2),vcenter()+7,6)
end
-->8
-- ball

function init_ball()
	-- make things interesting
	-- with random positions
 --	ball_x = flr(rnd(100))+10
 ball_x=pad_x+pad_w/2
	ball_y=pad_y-pad_h
	--ball_dx = rnd(1) > 0.5 and -1 or 
	ball_dx=1
	ball_dy=-1
	ball_r=2
	ball_sticky=true
end

function serve_ball()
	init_ball()
end

function update_ball()
	-- if the ball has not launched
	-- then follow the paddle
	if ball_sticky then
		ball_x=pad_x+pad_w/2
		
		-- direction based on l/r
		if btn(⬅️) then ball_dx=-1 end
		if btn(➡️) then ball_dx=1 end
		
		-- launch the ball
		if btnp(5) then
			ball_sticky=false
		end
		
		-- don't update ball yet
		return
	end

	-- fancy speedup/slowdown value
	local prev_x,prev_y,scale
	scale = 1
	if btn(4) then scale = 2 end
	if btn(5) then scale = 0.5 end

	-- figure out where the ball will go
	prev_x = ball_x
	ball_x += ball_dx * scale
	prev_y = ball_y
	ball_y += ball_dy * scale
	
	-- bounce off left/right sides
	if ball_x > 127-ball_r or ball_x < ball_r then
		bounce_x(0)
		ball_x = mid(ball_r,ball_x,127-ball_r)
	end
	-- bounce off top of screen
	if ball_y < ball_r+9 then
		bounce_y(0)
		ball_y = mid(ball_r,ball_y,127-ball_r)
	end
	-- lose life if ball hits bottom
	if ball_y > 127-ball_r then
		lose_life()
	end
	
	-- check if ball hit paddle
	if ball_collide(pad_x,pad_y,pad_w,pad_h) then
		if collided_vertical(prev_y,ball_y,pad_y-ball_r,pad_y+pad_h+ball_r) then
				bounce_y(1)
				score+=1
		end
		if	collided_horizontal(prev_x,ball_x,pad_x-ball_r,pad_x+pad_w+ball_r)	then
				bounce_x(1)
				score+=1
		end
	end
	
	-- only bounce once per frame
	local has_bounced=false
	
 -- for each brick...
 for i=1,num_bricks do
		if brick_v[i] and	ball_collide(brick_x[i],brick_y[i],brick_w,brick_h) then
			if collided_vertical(prev_y,ball_y,brick_y[i]-ball_r,brick_y[i]+brick_h+ball_r) then
				brick_v[i]=false
				score += 10
				if not has_bounced then
					bounce_y(3)
					has_bounced=true
				end
			end
			if	collided_horizontal(prev_x,ball_x,brick_x[i]-ball_r,brick_x[i]+brick_w+ball_r)	then
 			brick_v[i]=false
 			score += 10
 		 if not has_bounced then
		 	 bounce_x(3)
					has_bounced=true
		 	end
		 end
		end
	end
end

-- check if the ball is within
-- the bounds that were passed
function ball_collide(x,y,w,h)
	if ball_x-ball_r > x+w or
				ball_x+ball_r < x or
			 ball_y-ball_r > y+h or
				ball_y+ball_r < y then
		return false
	end
	
	return true
end

-- flip x dir and play sound
-- set up a bounce timer for
-- hitting blocks so that hitting
-- 2 does not always destroy both
function bounce_x(fx)
	ball_dx = -ball_dx
	sfx(fx)
end

-- flip y dir and play sound
function bounce_y(fx)
	ball_dy = -ball_dy
	sfx(fx)
end

function draw_ball()
	circfill(ball_x,ball_y,ball_r,10)
	if ball_sticky then
		line(ball_x+ball_dx*4,ball_y+ball_dy*4,ball_x+ball_dx*6,ball_y+ball_dy*6,10)
	end
end
-->8
-- paddle

-- always init paddle around the
-- middle at the bottom
function init_paddle()
	pad_x=52
	pad_y=120
	pad_dx=0
	pad_w=24
	pad_h=3
end

-- move paddle l/r based on ⬅️➡️
-- but lock to edges of screen
function update_paddle()
	pad_dx *= 0.5
	if abs(pad_dx) < 0.1 then pad_dx = 0 end
	
	if btn(⬅️) then pad_dx=-4 end
	if btn(➡️) then pad_dx=4 end	

	pad_x += pad_dx
	pad_x = mid(0,pad_x,127-pad_w)
end

function draw_paddle()
	rectfill(pad_x,pad_y,pad_x+pad_w,pad_y+pad_h,7)
end
-->8
-- bricks

function init_bricks()
	num_columns=10
	num_rows=6
	num_bricks=num_columns*num_rows
	brick_x={}
	brick_y={}
	brick_v={}
	brick_w=10
	brick_h=4
	brick_c=12

	for y=1,num_rows do
		for x=1,num_columns do
			add(brick_x,4+(x-1)*(brick_w+2))
			add(brick_y,8+(6*y))
			add(brick_v,true)
		end
	end
end

function update_bricks()
-- noop for now... they are
-- not sentient - only the
-- ball knows what is happening
end

-- let the magic happen
function draw_bricks()
	for i=1,num_bricks do
		if brick_v[i] then
			rectfill(brick_x[i],brick_y[i],brick_x[i]+brick_w,brick_y[i]+brick_h,brick_c)
		end
	end
end
-->8
-- utils

-- collision helpers --

-- combine u/d checks here
function collided_vertical(prev,new,top,bottom)
	return
			collided_top(prev,new,top) or
			collided_bottom(prev,new,bottom)
end

-- combine l/r checks here
function collided_horizontal(prev,new,left,right)
	return
			collided_left(prev,new,left) or
			collided_right(prev,new,right)
end

-- check if something will
-- collide on the top edge
function collided_top(prev,new,edge)
	return prev < edge and new >= edge
end

-- check if something will
-- collide on the bottom edge
function collided_bottom(prev,new,edge)
	return prev > edge and new <= edge
end

-- check if something will
-- collide on the left edge
function collided_left(prev,new,edge)
	return prev < edge and new >= edge
end

-- check if something will
-- collide on the right edge
function collided_right(prev,new,edge)
	return prev > edge and new <= edge
end

-- wait a number of frames
function wait(a)
	for i = 1,a do flip() end
end

-- string utils --
function hcenter(s)
  -- screen center minus the
  -- string length times the 
  -- pixels in a char's width,
  -- cut in half
  return 64-#s*2
end

-- middle of screen (for text)
function vcenter()
  -- screen center minus the
  -- string height in pixels,
  -- cut in half
  return 61
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000018360183601835018330183201831018300183001d700187001570013700117000f7000d7000870003700107000870008700087000870007700077000770007700077000770000000000000000000000
00010000243602436024350243302432024310173000d3000b3000d3000f300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000000000000
000300001e3601d350183501134015340163301332015310073100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003b350353302f320353002130026300213001c300083000630006300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
