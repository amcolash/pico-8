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
	elseif mode=="stageclear" then
		update_stageclear()
	end
end

function _draw()
	if mode=="game" then
		draw_game()
	elseif mode=="start" then
		draw_start()
	elseif mode=="gameover" then
		draw_gameover()
	elseif mode=="stageclear" then
		draw_stageclear()
	end
end
-->8
-- modes

-- main setup for game
function start_game()
	mode="game"
	lives=3
	score=0
	combo=1
	level=1
	init_paddle()
	init_ball()
	init_bricks()
	init_powerups()
end

-- update the peons
function update_game()
	update_paddle()
	update_ball()
	update_bricks()	
	update_powerups()
end

-- lose life and handle gameover
function lose_life()
	sfx(2)
	lives -= 1
	reset_explosions()
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
function update_stageclear()
	if btn(❎) then
		mode="game"
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
	draw_powerups()
end

-- todo: move to different tab?
-- draw the hud on the game
function draw_hud()
	rectfill(0,0,127,7,0)
	for i=0,lives-1 do
		print("♥",118-i*7,0,8)
	end
	print("score: "..score,2,0,7)
	print("combo: "..combo.."x",60,0,7)
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
	if lives == 0 then
		-- clear hearts on game over
		rectfill(100,0,127,7,0)
	end
	
	-- bar in the middle for text
	rectfill(0,vcenter()-11,127,vcenter()+15,0)
	
	local text1="game over"
	local text2="press ❎ to restart"
	print(text1,hcenter(text1),vcenter()-7,lives > 0 and 11 or 8)
	print(text2,hcenter(text2),vcenter()+7,6)
end

-- stageclear mode text
function draw_stageclear()
	-- bar in the middle for text
	rectfill(0,vcenter()-11,127,vcenter()+15,0)

	local text1="level "..(level-1).." complete"
	local text2="press ❎ to contine"
	print(text1,hcenter(text1),vcenter()-7,11)
	print(text2,hcenter(text2),vcenter()+7,6)
end
-->8
-- ball

function init_ball()
	ball_x=pad_x+pad_w/2
	ball_y=pad_y-pad_h
	ball_dx=1
	ball_dy=-1
	ball_r=2
	ball_a=1
	ball_sticky=true
	combo=1
end

function serve_ball()
	init_paddle()
	init_ball()
	init_powerups()
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
	if btn(5) then scale = 0.1 end

	-- figure out where the ball will go
	prev_x = ball_x
	ball_x += ball_dx * scale
	prev_y = ball_y
	ball_y += ball_dy * scale
	
	-- check if the ball hits screen
	test_ball_screen(prev_x,prev_y)
	
	-- check if ball hit paddle
	test_ball_paddle(prev_x,prev_y)

	-- check if the ball hit bricks
	test_ball_bricks(prev_x,prev_y)
end

-- check if the ball hit the
-- edges of the screen
function test_ball_screen(prev_x,prev_y)
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
end

-- check if the ball hit the
-- paddle and bounce accordingly
function test_ball_paddle(prev_x,prev_y)
	if ball_collide(pad_x,pad_y,pad_w,pad_h) then
		-- reset combo when paddle hit
		combo=1
		
		if collided_vertical(prev_y,ball_y,pad_y-ball_r,pad_y+pad_h+ball_r) then
			-- do some fancy stuff to
			-- make bouncing feel nice
			if abs(pad_dx) > 2 then
				if sign(ball_dx) == sign(pad_dx) then
					-- flatten angle
					set_ball_angle((ball_a-1)%3)
				else
					if ball_ang==2 then
						-- normal angle
						ball_dx = -ball_dx
					else
						-- raise angle
						set_ball_angle((ball_a+1)%3)
					end
				end
			else
				set_ball_angle(1)
			end
			bounce_y(1)
		end
		if collided_horizontal(prev_x,ball_x,pad_x-ball_r,pad_x+pad_w+ball_r)	then
			bounce_x(1)
		end
	end
end

-- check if the ball hit any
-- bricks, but only bounce off
-- of the first one each frame
function test_ball_bricks(prev_x,prev_y)		
	-- only bounce once per frame
	local has_bounced=false
	
	-- for each brick...
	for i=1,num_bricks do
		if brick_s[i]>0 and	ball_collide(brick_x[i],brick_y[i],brick_w,brick_h) then
			-- brick was hit, now figure
			-- out if we need to bounce
			-- and in what direction
			brick_hit(i,true)
			if collided_vertical(prev_y,ball_y,brick_y[i]-ball_r,brick_y[i]+brick_h+ball_r) and not has_bounced then
					bounce_y()
			end
			if collided_horizontal(prev_x,ball_x,brick_x[i]-ball_r,brick_x[i]+brick_w+ball_r) and not has_bounced then
				bounce_x()
			end
			has_bounced=true
		end
	end
end

-- set new ball angle so that
-- it bounces in interesting
-- ways off of the paddle
function set_ball_angle(a)
	ball_angle=a
	if a==2 then
		ball_dx=1.3*sign(ball_dx)
		ball_dy=0.5*sign(ball_dy)
	elseif a==0 then
		ball_dx=0.5*sign(ball_dx)
		ball_dy=1.3*sign(ball_dy)
	else
		ball_dx=sign(ball_dx)
		ball_dy=sign(ball_dy)
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
	if fx ~= nil then sfx(fx) end
end

-- flip y dir and play sound
function bounce_y(fx)
	ball_dy = -ball_dy
	if fx ~= nil then sfx(fx) end
end

function draw_ball()
	circfill(round(ball_x),round(ball_y),ball_r,10)
	if ball_sticky then
		line(ball_x+ball_dx*4,ball_y+ball_dy*4,ball_x+ball_dx*6,ball_y+ball_dy*6,10)
	end
end
-->8
-- paddle

-- always init paddle around the
-- middle at the bottom
function init_paddle()
	pad_w=24
	pad_h=3
	pad_x=(127-pad_w)/2
	pad_y=120
	pad_dx=0
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
	num_columns=9
	num_rows=6
	num_bricks=num_columns*num_rows

	brick_x={}
	brick_y={}
	brick_s={}
	brick_w=12
	brick_h=4

	local level=generate_level(levels[level])
	i=0
	for y=1,num_rows do
		for x=1,num_columns do
			i+=1
			add(brick_x,2+(x-1)*(brick_w+2))
			add(brick_y,10+(6*y))
			add(brick_s,get_brick_status(sub(level,i,i)))
		end
	end
end

-- check the level is complete
function update_bricks()
	update_explosions()
	if level_complete() then
		next_level()
	end
end

function reset_explosions()
	for i=1,#brick_s do
		if brick_s[i] > 9 then
			brick_s[i] = 8
		end
	end
end

function update_explosions()
	-- handle sploders
	for i=1,#brick_s do
		if brick_s[i] > 9 then
			-- increment value changes
			-- speed of flashing
			brick_s[i] += 0.07
			
			-- check value changes time
			-- before explosion trigger
			if brick_s[i] > 17 then
				explode_brick(i)
			end
		end
	end
end

-- status/health for brick type
function get_brick_status(t)
	if t=="e" then return 0
	-- 2 hit
	elseif t=="n" then return 2
	-- 3 hit
	elseif t=="m" then return 3
	-- powerup
	elseif t=="p" then return 7
	-- exploding
	elseif t=="x" then return 8
	-- invincible
	elseif t=="i" then return 9
	-- normal
	else return 1 end
end

-- get color of brick based on
-- brick status
function get_brick_color(s)
	-- powerup
	if s==7 then return level_color[level]
	-- exploding brick
	elseif s==8 then return 9
	-- invincible
	elseif s==9 then return 6
	-- exploding state
	elseif s>9 then return flr(s) % 2 == 0 and 8 or 9
	-- normal, based on hits left
	else return level_color[(level+s-1)%#level_color] end
end

-- when a brick is hit, play
-- a sound, increment combo and
-- increase score
function brick_hit(i,add_combo)
	if i <=0 or i>num_bricks then return end
	
	local status=brick_s[i]
	if status > 0 then
		if status==9 then
			-- invincible
			sfx(11)
		else
			if status==7 then
				-- powerup
				brick_s[i]=0
				spawn_powerup(i)
				sfx(min(combo-1,6) + 3)
			elseif status==8 then
				-- explode
				brick_s[i]=10
				sfx(min(combo-1,6) + 3)
			else
				-- normal
				brick_s[i]-=1
				sfx(min(combo-1,6) + 3)
			end
			
			score += 10*combo
			if add_combo then
				combo += 1
			end
		end
	end
end

function explode_brick(i)
	-- explode
	brick_s[i]=0
	sfx(10)
	
	-- hit surrounding bricks
	brick_hit(i-num_columns-1,false)
	brick_hit(i-num_columns,false)
	brick_hit(i-num_columns+1,false)
	brick_hit(i-1,false)
	brick_hit(i+1,false)
	brick_hit(i+num_columns-1,false)
	brick_hit(i+num_columns,false)
	brick_hit(i+num_columns+1,false)
end

-- let the magic happen
function draw_bricks()
	for i=1,num_bricks do
		if brick_s[i]>0 then
			rectfill(brick_x[i],brick_y[i],brick_x[i]+brick_w,brick_y[i]+brick_h,get_brick_color(brick_s[i]))
			-- fancy bricks?
			pset(brick_x[i],brick_y[i],1)
			pset(brick_x[i]+brick_w,brick_y[i],1)
			pset(brick_x[i],brick_y[i]+brick_h,1)
			pset(brick_x[i]+brick_w,brick_y[i]+brick_h,1)
		end
	end
end
-->8
-- levels

-- levels are created with a
-- string where different chars
-- mean different things

-- b -> normal block
-- n -> 2 health block
-- m -> 3 health block
-- p -> powerup
-- i -> invincible block
-- x -> exploding
-- e -> empty
-- / -> e's to end of row
-- z -> fill rest with e's
-- number -> fill based on prev

-- i.e "b5/" -> 5 blocks, 4 empty, repeated each row
-- "b2e2x" -> 2 blocks, 2 empty, rest of level empty

l1="ie3pepep/i4/i5/i6/i7/i8z"
--l1="e4ib3/e4im3/e4ibx/e4in2/e4ib2z"
--l2="b3e3b3/b4e3b2/b5e3b/b6/b7/b8/"
--l3="be"
--l4="b2e2b2/"
levels={l1,l1,l1,l1}
level_color={12,15,10,11,13,14}

-- gnerate a level based on the
-- syntax that is defined above
-- this level is a 1d array that
-- will be used to turn on/off
-- blocks and has a length of at
-- least num_bricks, but may be
-- longer if the pattern is long
function generate_level(lvl)
	local counter=0
	local final=""
	local prev,cur
	
	while counter < num_bricks do
		for i=1,#lvl do
			cur=sub(lvl,i,i)
			if cur=="z" then
				while counter < num_bricks do
					final = final.."e"
					counter+=1
				end
			elseif cur=="/" then
				y=flr(counter/num_columns)*num_columns
				x=counter-y
				if x>0 or prev=="/" then
					for j=x,num_columns-1 do
						final = final.."e"
						counter+=1
					end
				end
			elseif cur > "0" and cur <= "9" then
				for j=1,cur-1 do
					final = final..prev
					counter+=1
				end
			else
				final = final..cur
				counter+=1
			end
			prev=cur
		end
	end
	
	return final
end

-- check if all bricks are cleared
function level_complete()
	for i=1,#brick_s do
		if brick_s[i]>0 and brick_s[i]~=9 then return false end
	end
	return true
end

-- increment level, init new
-- bricks and reset paddle/ball
function next_level()
	-- re-render the scene after
	-- all bricks have been cleared
	-- and powerups are gone
	init_powerups()
	_draw()

	level+=1
	if level <= #levels then		
		-- setup for next level
		serve_ball()
		init_bricks()
		mode="stageclear"
	else
		mode="gameover"
	end
end
-->8
-- powerups

function init_powerups()
	powerup_x={}
	powerup_y={}
	powerup_t={}
end

function spawn_powerup(i)
	add(powerup_x,brick_x[i])
	add(powerup_y,brick_y[i])
	add(powerup_t,1)
end

function update_powerups()
	for i=1,#powerup_t do
		if powerup_t[i] ~= 0 then
			local scale=1
			if btn(5) then scale = 0.3 end
			powerup_y[i] += 0.7*scale
			if powerup_collide(i) then
				powerup_activate(i)
			end
			if powerup_y[i] > 127 then
				powerup_t[i] = 0
			end
		end
	end
end

function powerup_collide(i)
	local x=powerup_x[i]
	local y=powerup_y[i]
	
	if x > pad_x+pad_w or
				x+16 < pad_x or
				y+8 < pad_y or
				y > pad_y+pad_h then
		return false
	end
	
	return true
end

function powerup_activate(i)
	powerup_t[i] = 0
	sfx(12)
end

function get_powerup_sprite(i)
	return 1 -- todo
end

function draw_powerups()
	for i=1,#powerup_t do
		if powerup_t[i] ~= 0 then
			spr(get_powerup_sprite(i),powerup_x[i],powerup_y[i])
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

-- converts anything to string, even nested tables
function tostring(any)
	if type(any)=="function" then
		return "function"
	end
	if any==nil then
		return "nil"
	end
	if type(any)=="string" then
		return any
	end
	if type(any)=="boolean" then
		if any then return "true" end
		return "false"
	end
	if type(any)=="table" then
		local str = "{ "
		for k,v in pairs(any) do
			str=str..tostring(k)..":"..tostring(v).." "
		end
		return str.."}"
	end
	if type(any)=="number" then
		return ""..any
	end
	return "unkown" -- should never show
end

-- math utils --
function sign(n)
	if n>0 then return 1 end
	if n < 0 then return -1 end
	return 0
end

function round(n)
	if n-flr(n) > 0.5 then return flr(n)+1
	else return flr(n)
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700799889990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000999899990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000999889990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700999989990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000099889900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000018360183601835018330183201831018300183001d700187001570013700117000f7000d7000870003700107000870008700087000870007700077000770007700077000770000000000000000000000
00010000243602436024350243302432024310173000d3000b3000d3000f300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000000000000
000300001e3601d350183501134015340163301332015310073100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002b36030360303503033034300213001c30008300063000630000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300000000000000000
000200002d36032360323503233036300213001c30008300063000630000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300000000000000000
000200002e36034360343503433037300213001c30008300063000630000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300000000000000000
000200003036036360363503633039300213001c30008300063000630000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300000000000000000
00020000323603836038350383303b300213001c30008300063000630000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300000000000000000
00020000343603a3603a3503a3303b300213001c30008300063000630000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300000000000000000
000200003234035360393503d33035320383503e340383203b3303f31000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300000000000000000
000200002f6502e6502964024640216401e6301b63019630176301563013630116300f6200d6200b6200762005620026100061008600056000160000300003000030000300003000030000300003000030000300
000200002b350313303c32028300233001a3001830000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200001d3602336026350223401a34016330113301133014330163201e320283202d3202a3101f3103230036300383003e30000000000000000000000000000000000000000000000000000000000000000000
