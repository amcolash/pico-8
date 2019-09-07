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
		if btn(4) then wait(60) end
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

-- draw the hud on the game
function draw_hud()
	rectfill(0,0,127,7,0)
	for i=0,lives-1 do
		print("♥",120-i*7,0,8)
	end
	print("score: "..score,2,0,7)
	print("combo: "..combo*combo2.."x",52,0,7)
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
	balls={}
	balls_del={}
	spawn_ball()
		
	ball_scalar=1
	ball_r=2
	ball_sticky=true
end

function spawn_ball(dx)
	local ball={}
	ball.x=pad_x+pad_w/2
	ball.y=pad_y-pad_h
	ball.dx=dx ~= nil and dx or 1
	ball.dy=-1
	ball.a=1
	add(balls,ball)
end

function serve_ball()
	init_paddle()
	init_ball()
	init_powerups()
end

function update_ball()
	for i=1,#balls do
		local ball=balls[i]
		
		-- if the ball has not launched
		-- then follow the paddle
		if ball_sticky then
			ball.x=pad_x+pad_w/2

			-- direction based on l/r
			if btn(⬅️) then ball.dx=-1
			elseif btn(➡️) then ball.dx=1 end
			
			-- launch the ball
			if btnp(5) then
				ball_sticky=false
			end

			-- don't update ball yet
			return
		end

		-- fancy speedup/slowdown value
		local prev_x,prev_y,scale
		scale = ball_scalar
		--if btn(4) then scale = 2 end
		--if btn(5) then scale = 0.1 end

		-- figure out where the ball will go
		prev_x = ball.x
		ball.x += ball.dx * scale
		prev_y = ball.y
		ball.y += ball.dy * scale

		-- check if the ball hits screen
		test_ball_screen(ball,prev_x,prev_y)

		-- check if ball hit paddle
		test_ball_paddle(ball,prev_x,prev_y)

		-- check if the ball hit bricks
		test_ball_bricks(ball,prev_x,prev_y)
	end
	
	for i=1,#balls_del do
		del(balls,balls_del[i])
	end
	
	if	#balls == 0 then
		lose_life()
	end
end

-- check if the ball hit the
-- edges of the screen
function test_ball_screen(ball,prev_x,prev_y)
	-- bounce off left/right sides
	if ball.x > 127-ball_r or ball.x < ball_r then
		bounce_x(ball,0)
		ball.x = mid(ball_r,ball.x,127-ball_r)
	end
	-- bounce off top of screen
	if ball.y < ball_r+8 then
		bounce_y(ball,0)
		ball.y = mid(ball_r,ball.y,127-ball_r)
	end
	-- delete ball when it hits bottom of screen
	if ball.y > 127-ball_r then
		add(balls_del,ball)
	end
end

-- check if the ball hit the
-- paddle and bounce accordingly
function test_ball_paddle(ball,prev_x,prev_y)
	if ball_collide(ball,pad_x,pad_y,pad_w,pad_h) then
		-- reset combo when paddle hit
		combo=1

		if collided_vertical(prev_y,ball.y,pad_y-ball_r,pad_y+pad_h+ball_r) then
			-- do some fancy stuff to
			-- make bouncing feel nice
			if abs(pad_dx) > 2 then
				if sign(ball.dx) == sign(pad_dx) then
					-- flatten angle
					set_ball_angle(ball,(ball.a-1)%3)
				else
					if ball.ang==2 then
						-- normal angle
						ball.dx = -ball.dx
					else
						-- raise angle
						set_ball_angle(ball,(ball.a+1)%3)
					end
				end
			else
				set_ball_angle(ball,1)
			end
			bounce_y(ball,1)
		end
		if collided_horizontal(prev_x,ball.x,pad_x-ball_r,pad_x+pad_w+ball_r)	then
			bounce_x(ball,1)
		end
	end
end

-- check if the ball hit any
-- bricks, but only bounce off
-- of the first one each frame
function test_ball_bricks(ball,prev_x,prev_y)
	-- only bounce once per frame
	local has_bounced=false
	local x_bounce=false
	local y_bounce=false

	-- for each brick...
	for i=1,num_bricks do
		bricks[i].c=1
		if bricks[i].s>0 and ball_collide(ball,bricks[i].x,bricks[i].y,brick_w,brick_h) then
			-- brick was hit, now figure
			-- out if we need to bounce
			-- and in what direction
			brick_hit(i,true)
			bricks[i].c=0

			if not megaball or bricks[i].s==9 then
				if collided_vertical(prev_y,ball.y,bricks[i].y-ball_r,bricks[i].y+brick_h+ball_r) and not has_bounced then
					bounce_y(ball)
					y_bounce=true
				end
				if collided_horizontal(prev_x,ball.x,bricks[i].x-ball_r,bricks[i].x+brick_w+ball_r) and not has_bounced then
					bounce_x(ball)
					x_bounce=true
				end

				-- stuck inside block?
				if not x_bounce and not y_bounce then
					bounce_x(ball)
					bounce_y(ball)
				end
				has_bounced=true
			end
		end
	end
end

-- set new ball angle so that
-- it bounces in interesting
-- ways off of the paddle
function set_ball_angle(ball,a)
	ball.angle=a
	if a==2 then
		ball.dx=1.3*sign(ball.dx)
		ball.dy=0.5*sign(ball.dy)
	elseif a==0 then
		ball.dx=0.5*sign(ball.dx)
		ball.dy=1.3*sign(ball.dy)
	else
		ball.dx=sign(ball.dx)
		ball.dy=sign(ball.dy)
	end
end

-- check if the ball is within
-- the bounds that were passed
function ball_collide(ball,x,y,w,h)
	if ball.x-ball_r > x+w or
			ball.x+ball_r < x or
			ball.y-ball_r > y+h or
			ball.y+ball_r < y then
		return false
	end

	return true
end

-- flip x dir and play sound
-- set up a bounce timer for
-- hitting blocks so that hitting
-- 2 does not always destroy both
function bounce_x(ball,fx)
	ball.dx = -ball.dx
	if fx ~= nil then sfx(fx) end
end

-- flip y dir and play sound
function bounce_y(ball,fx)
	ball.dy = -ball.dy
	if fx ~= nil then sfx(fx) end
end

function draw_ball()
	for i=1,#balls do
		local ball=balls[i]
		circfill(round(ball.x),round(ball.y),ball_r,10)
		if ball_sticky then
			line(ball.x+ball.dx*4,ball.y+ball.dy*4,ball.x+ball.dx*6,ball.y+ball.dy*6,10)
		end
	end
end
-->8
-- paddle

-- always init paddle around the
-- middle at the bottom
function init_paddle()
	base_pad_w=24
	tween_pad_w=base_pad_w
	pad_w=base_pad_w
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

	if pad_w < tween_pad_w then
		pad_w += 1
	elseif pad_w > tween_pad_w then
		pad_w -=1
	end

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
	brick_w=12
	brick_h=4

	bricks={}

	local level=generate_level(levels[level])
	i=0
	for y=1,num_rows do
		for x=1,num_columns do
			i+=1
			local brick={}
			brick.x=2+(x-1)*(brick_w+2)
			brick.y=10+(6*y)
			brick.s=get_brick_status(sub(level,i,i))
			brick.c=1
			add(bricks,brick)
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
	for i=1,#bricks do
		if bricks[i].s > 9 then
			bricks[i].s = 8
		end
	end
end

function update_explosions()
	-- handle sploders
	for i=1,#bricks do
		if bricks[i].s > 9 then
			-- increment value changes
			-- speed of flashing
			bricks[i].s += 0.07

			-- check value changes time
			-- before explosion trigger
			if bricks[i].s > 17 then
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
	if s==7 then return 8
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

	local status=bricks[i].s
	if status > 0 then
		if status==9 then
			-- invincible
			sfx(11)
		else
			if status==7 then
				-- powerup
				bricks[i].s=0
				spawn_powerup(i)
				sfx(min(combo-1,6) + 3)
			elseif status==8 then
				-- explode
				bricks[i].s=10
				sfx(min(combo-1,6) + 3)
			else
				-- normal brick

				-- speical megaball score
				if megaball and bricks[i].s > 1 then
					score += (bricks[i].s-1)*10*combo*combo2
					bricks[i].s=0
				else
					bricks[i].s-=1
				end
				sfx(min(combo-1,6) + 3)
			end

			score += 10*combo*combo2
			if add_combo then
				combo += 1
			end
		end
	end
end

function explode_brick(i)
	-- explode
	bricks[i].s=0
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
		if bricks[i].s>0 or bricks[i].c==0 then
			if bricks[i].s>0 then
				rectfill(bricks[i].x,bricks[i].y,bricks[i].x+brick_w,bricks[i].y+brick_h,get_brick_color(bricks[i].s)*bricks[i].c)
			elseif bricks[i].c==0 then
				rectfill(bricks[i].x,bricks[i].y,bricks[i].x+brick_w,bricks[i].y+brick_h,7)
			end
			-- fancy bricks?
			pset(bricks[i].x,bricks[i].y,1)
			pset(bricks[i].x+brick_w,bricks[i].y,1)
			pset(bricks[i].x,bricks[i].y+brick_h,1)
			pset(bricks[i].x+brick_w,bricks[i].y+brick_h,1)
		end
	end
end
-->8
-- powerups

function init_powerups()
	powerups={}
	
	-- reset powerup boosts
	combo=1
	combo2=1
	ball_scalar=1
	tween_pad_w=base_pad_w
	megaball=false
end

function spawn_powerup(i)
	local powerup = {}
	powerup.x=bricks[i].x
	powerup.y=bricks[i].y
	powerup.type=flr(rnd(6))+1
	powerup.type=3
	powerup.time=0
	add(powerups,powerup)
end

function update_powerups()
	for i=1,#powerups do
		local powerup=powerups[i]
		if powerup.y ~= -1 then
			local scale=1
			if btn(5) then scale = 0.3 end
			powerup.y += 0.7*scale
			
			if powerup_collide(i) then
				powerup_activate(i)
			end
			if powerup.y > 127 then
				powerup.y = -1
			end
		end

		-- update time-based powerups
		if powerup.time > 0 then
			powerup.time -= 1/60

			local t=powerup.type
			-- if a powerup has expired
			if powerup.time < 0 then
				if t==4 then
					ball_scalar = 1
				elseif t==5 or t==6 then
					tween_pad_w = base_pad_w
					combo2=1
				elseif t==7 then
					megaball=false
				end
			end
		end
	end
end

function powerup_collide(i)
	local x=powerups[i].x
	local y=powerups[i].y

	if x > pad_x+pad_w or
				x+16 < pad_x or
				y+6 < pad_y or
				y > pad_y+pad_h then
		return false
	end

	return true
end

function powerup_activate(i)
	sfx(12)
	local t = powerups[i].type

	-- kill existing powerups before
	-- replacing with new one
	-- note the special check for
	-- expand/shrink which stops
	-- the other on activation
	for i=1,#powerups do
		local pt = powerups[i].type
		if powerups[i].time > 0 then
			if t==pt or
				((t==5 or t==6) and (pt==5 or pt==6)) then
				powerups[i].time = 0
			end
		end
	end

	-- time-based powerups set up
	-- timers here
	if t >= 4 then powerups[i].time = 7 end

	-- figure out powerup
	if t == 1 then
		-- extra life
		lives = min(lives+1,5)
	elseif t == 2 then
		-- sticky ball
		init_ball()
	elseif t == 3 then
		-- multiball
		spawn_ball(1)
		spawn_ball(-1)
	elseif t == 4 then
		-- slowdown
		ball_scalar = 0.5
	elseif t == 5 then
		-- big paddle
		tween_pad_w = 1.5 * base_pad_w
		combo2 = 1
	elseif t == 6 then
		-- small paddle
		tween_pad_w = 0.5 * base_pad_w
		combo2=2
	elseif t == 7 then
		-- megaball
		megaball=true
	end
	
	powerups[i].y = -1
end

function get_powerup_sprite(i)
	local t = powerups[i].type
	return 1 -- todo
end

function draw_powerups()
	local spacer=1
	for i=1,#powerups do
		if powerups[i].y ~= -1 then
			spr(get_powerup_sprite(i),powerups[i].x,powerups[i].y)
		end
		if powerups[i].time > 0 then
			print(powerups[i].time,10,92+7*spacer)
			spr(get_powerup_sprite(i),0,90+7*spacer)
			spacer += 1
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

--l1="bi8/i9/ie7i/ie4i2ei/ie5iei/i7ei"
--l1="m3e3m3/m4e3m2/m5e3m/m6/m7/m7/"
--l1="ie3pepep/bi4/i5/i6e2i/i7/bi6/z"
--l1="e4ib3/e4im3/e4ibx/e4in2/e4ib2z"
--l1="n9/m9/n9/m9/pb8/i5b3p"
l1="b9/b9/b9/b9/p9/p9"
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
	for i=1,#bricks do
		if bricks[i].s>0 and bricks[i].s~=9 then return false end
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
