pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main

--x is primary weapon
--z is movement buff (if have)
--x+z (hold) is special weapon

--animation counter
--provides for anim. of still entities
acnt=1

--animation for player track
track_anim={20,21,22,23}
player_x=64
player_y=70
player_moved=false

top_border=9
bot_border=120
midline=60
r_border=120
l_border=0

max_heat=90

enemies={}
current_mode=nil

in_prompt=false

--type 0
empty_gun={
	t=0,
	part=0,
	lbl=32,
	charge_anim={},
	fire_anim={},
	heat_color=0,
	charge=0,
	heat_rate=0,
	damage_heat_mod=0,
	rate=0
}

--type 1
beam_gun={
	t=1,
	lbl=11,
	charge=30,
	heat_rate=2,
	damage_heat_mod=10,
	rate=5
}
--type 2
chain_gun={
	t=2,
	lbl=10,
	charge=0,
	heat_rate=10,
	damage_heat=1.5,
	rate=5
}

--x is primary/fast
x_gun={
	spec=chain_gun,
	heat=100.0,
	heat_mod=1.0,
	heated=false,
	max_heat=150,
	cool=1.0,
	c=0,
	r=0
}
--z is secondary/slow
z_gun={
	spec=nil
	--c=0,
	--r=0
}
	
sp_heat=0.0
sp_max_heat=200
sp_health=100
sp_max_health=100
sp_heated=true
sp_heat_dis=1.0

function reset_sp()
	player_x=64
	player_y=70
	sp_health=sp_max_health
	sp_heat=200.0 --testing
end

--to skip navigating in the map
dev_shortcut = true

function _init()
	if dev_shortcut then
		reset_sp()
		current_mode=stage_mode
		reactor()
	else
		reset_sp()
		current_mode=map_mode
		build_map()
	end
end

prompt_msg=""
prompt_loc=nil
function prompt_mode()
	cls()
	print(prompt_msg)
	bx=5 --❎
	b=btn()
	if b>0 then
		if b&0x20>0 then
			prompt_status=0 --confirm
			prompt_loc.launches()
			current_mode=
					prompt_loc.mode
		end
		if b&0x10>0 then
			in_prompt=false
			prompt_status=1 --return
		end
	else
		in_prompt=true --wait
	end
end

function map_mode()
	cls()
	player_moved=false
	
	player_control()
	draw_map()
	draw_player()
	check_player_choice()
	if in_prompt then
		prompt_mode()
	end
end

function stage_mode()
	cls()
	player_moved=false
	
	player_control()
	gun_control()
	
	draw_player()
	draw_enemies()
	
	draw_bullets()
	draw_hud()
	x_gun.heat-=x_gun.cool
	if x_gun.heat<0 then
		x_gun.heat=0
	end
	if z_gun.spec!=nil then
		z_gun.heat-=z_gun.cool
		if z_gun.heat<0 then
			z_gun.heat=0
		end
	end
	if sp_heat > sp_max_heat then
		sp_heated=true
	end
	sp_heat-=sp_heat_dis
	if sp_heat<0 then
		sp_heat=0.0
		sp_heated=false
	end

end

function _update()	
	if acnt > 1000 then
		acnt = 0
	end
	acnt+=1
	current_mode()
end


-->8
--hud

health_col={8,9,10,11}
heat_col={1,12,11,10,9,8}

function draw_hud()
	--10, 11
	rectfill(0,0,128,7,5)
	--draw x meter
	draw_gun_hud(45,z_gun)
	--draw z meter
	draw_gun_hud(0,x_gun)
	--draw g meter
	spr(12,85,0)
	health_meter(91,1,sp_health)
	
end

function draw_gun_hud(offset,gun)
	--pal(7, health_col[gun.dur])
	palt(0, false)
	lbl=nil
	if gun.spec==nil then
		lbl=31
	else
		lbl=gun.spec.lbl
	end
	spr(lbl,offset,0)
	heat_meter(offset+6,1,
		flr(gun.heat))
	for i=1,5 do
		gi=i*3
		col=0
		rectfill(
			offset+19+gi,3,
			offset+20+gi,5,
			col
		)
	end
	palt(0, true)
end

function health_meter(x,y)
	--heat meter
	gi=1*2
	
	warning=sp_health <=
		sp_max_health/2
	danger=sp_health <=
		sp_max_health/4
	col=11 --green
	if warning then
		col=10 --yellow
	elseif danger then
		col=8
	end
	x1=x+12
	x2=x+2
	y1=y
	y2=y+5
	rectfill(x1,y1,x2,y2,col)
	if (acnt%4==0 or acnt%2==0) and
				sp_heated then
		--blinks red until cooled to 0
		rectfill(
			x+12,y,x+2,
			y+5,8
			)
	end
end

function heat_meter(x,y,heat)
--heat meter
	for i=1,6 do
		gi=i*2
		if heat >= i*10 then
			rectfill(
				x+gi,y,x+1+gi,
				y+5,
				heat_col[i]
				)
				if (acnt%4==0 or acnt%2==0) and
							heat >= 70 then
					rectfill(
						x+gi,y,x+1+gi,
						y+5,8
						)
				end
		else
			rectfill(
				x+gi,y,x+1+gi,
				y+5,0
				)
		end
	end
end
-->8
--controls

player_speed=1

function player_control()
	l=0
	r=1
	u=2
	d=3
	bx=5
	bz=4
	x=player_x
	y=player_y
	if btn(l) then
		player_x-=player_speed
	end
	if btn(r) then
		player_x+=player_speed
	end
	if btn(u) then
		player_y-=player_speed
	end
	if btn(d) then
		player_y+=player_speed
	end
	if player_y != y or 
			 player_x != x then
			 player_moved=true
	else
			player_moved=false
	end
	--keep from going out of bounds
	m=midline
	if not in_stage then
		m=1
	end
	if player_y<m or
				player_y>bot_border then
		player_y=y
	end
	if player_x<l_border or
				player_x>r_border then
		player_x=x
	end
end


function gun_control()
	bx=5
	bz=4
	x=player_x
	y=player_y
	if btn(bx) then
		gun=x_gun
		spec=x_gun.spec
		
		gun.c+=1
		if gun.c>=spec.charge then
			if gun.r==spec.rate then
				gun.r=0
			else
				gun.r+=1
			end
			if gun.r==0 then
				shoot_pistol()
				x_gun.heat+=spec.heat_rate
				if x_gun.heat>x_gun.max_heat
				 then
					x_gun.heat=x_gun.max_heat
				end
			end
		end
	else
		x_gun.c=0
	end
	x_gun.r=max(x_gun.r,0)
	z_gun.r=max(z_gun.r,0)
end


-->8
--drawing

function draw_player()
	x=player_x
	y=player_y
	
	if player_moved then
			spr(track_anim[
				1+(acnt%#track_anim)],
				player_x,player_y)
	else
			spr(track_anim[1],
				player_x,player_y)
	end
end

function draw_enemies()
	for e in all(enemies) do
		tmp=acnt%#e.e.anim
		spr(e.e.anim[1+tmp],
			e.x, e.y)
	end
end

function draw_map()
 map(0,0,0,0,128,128)
	for l in all(locations) do
		--spr(l.loc.sprite,l.x,l.y,2,2)
	end
end
-->8
--projectiles

bullets={}

--example bullet
ex_bullet={
	x=0, --pos
	y=0, --pos
	size=1,
	damage=2,
	steps=1,
 friendly=true, --true for from player
--positive for spr, negative for 
--pixel color
	sprite=-1
}

function draw_bullets()
	for b in all(bullets) do
		if b.sprite<0 then
			pset(b.x,b.y,abs(b.sprite))
		else
		 spr(b.x,b.y,b.sprite)
		end
		b=b.step_fn(b)
		
		if b.friendly then
		--	b.y-=1
		else
		--	b.y+=1
		end
	end
end

function shoot_pistol()
	x1=player_x+3
	y=player_y
	blt1=blt_straight(x1,y)
	add(bullets,blt1)
end

function blt_straight(x,y)
	blt={}
	blt.x=x
	blt.y=y
	blt.xend=x
	blt.yend=0
	blt.size=1
	blt.damage=1
	blt.steps=1
	blt.friendly=true
	blt.sprite=-7
	blt.step_fn=step_straight
	return blt
end


-->8
--step functions

function step_straight(b)
	--modify x,y
	if b.x<b.xend then
		b.x+=1
	elseif b.x>b.xend then
		b.x-=1
	end
	if b.y<b.yend then
		b.y+=1
	elseif b.y>b.yend then
		b.y-=1
	end
	
	return b
end
-->8
--enemies

--enemy that stays still and 
--shoots toward the location
--of the player sprite
enemy_spitter={
	anim={16,17,18,19},
	--speed of shooting bullets
	speed=2,
	gun=chain_gun,
	trace_fn=trace_still,
	health=5
}

function add_spitter(x,y)
	spitter={
		x=x,
		y=y,
		e=enemy_spitter
	}
	add(enemies,spitter)
end

--traces are enemy movement
--patterns
function trace_still(e)
	--do nothing
	return e
end

-->8
--stages and maps

--the lab contains random stages

--the reactor contains fixed
--stages



function stage_1()
	add_spitter(10,30)
	add_spitter(80,30)
	

end

reactor_depth=1
reactor_stages={
	stage_1
}
function reactor()
	if 
		reactor_depth>#reactor_stages
		then
		reactor_stages
			[#reactor_stages]()
	else
		reactor_stages
			[reactor_depth]()
	end
	
end

locations={}

reactor_loc={
	sprite=64,
	launches=reactor,
	mode=stage_mode,
	msg=
		"enter reactor? (❎ for yes)"
}

function add_map_loc(x,y,loc)
	add(locations,{
		x=x,
		y=y,
		loc=loc
	})
end

function build_map()
	add_map_loc(12*8,3*8,
		reactor_loc)
	
end

function check_col(x1,y1,w1,h1,
										x2,y2,w2,h2)
	x_col=false
	if x1<=x2+w2 and x1>x2 then
		x_col=true
	end
	if x1-w1<=x2 and x1+w1>x2 then
		x_col=true
	end
	y_col=false
	if y1<=y2+h2 and y1>y2 then
		y_col=true
	end
	if y1-h1<=y2 and y1+h1>=y2 then
		y_col=true
	end
	
	return x_col and y_col
end

function check_player_choice()
	for l in all(locations) do
		if check_col(player_x,
							player_y,
							8,
							8,
							l.x,
							l.y,
							16,
							16) then
			--player chose
			prompt(l.loc)
			
		end
	end
end

function prompt(l)
	prompt_status=3 --waiting
	prompt_msg=l.msg
	in_prompt=true
	prompt_loc=l
	default_pos()
	
end

__gfx__
0007700000000000000000000000000000000000000000000cccccc0000009000090000090077009555555555555555555555555006666000066660000555500
00077000006c060000000500005000000060c600006006000a6cc6a0000005000050000080077008500000055606606550000005006006000696696006755760
050660500060c6000000666006660000006c0600006006000a6cc6a0000066600666000050066005500005055067760550555505666006666511115657a66a75
576d1675006c060000006167761600000060c600006006000a6cc6a00000616776160000576d16755066660556700765505cc505600000066518815655690655
5761d6750060c6000000616776160000006c0600006006000a6cc6a000006167761600005761d675506500055670076550466405600000066518815655609655
05066050006c060000006660066600000060c600006006000a6cc6a0000066600666000050066005506000055067760554444445666006666511115657a66a75
0007700000666600000000000000000000666600006666000aa66aa0000000000000000080077008500000055606606554000045006006000696696006766760
00077000000770000000000000000000000770000007700000a77a00000000000000000090077009555555555555555555555555006666000066660000566500
00555500055555500655556005555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
05555550556556556565565655555555006666000066660000666600006666000000000000000000000900000000000000000000000000000000000050000005
556666555666666556a66a6555666655063883600638836006388360063883600000000000900000009000000000000000000000000000000000000050000005
55609655556096555569065555690655063333600633336006333360063333600009000000090000900909000000000000000000000000000000000050000005
55690655556096555560965555690655063333600633336006333360063333600000000009000090090000900000000000000000000000000000000050000005
556666555666666556a66a65556666550ffffff00ffffffffffffffffffffff0009009000090090000900900000000000000000000000000000aa00050000005
05566550556666556566665655566555ff0000ffff00000ff000000ff00000ff000000000000000000000000000000000009900000a99a0000a99a0050000005
00566500055665500656656005566550f000000ff0000000000000000000000f0000000000000000000000000000000000099000000990000009900055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55585055050505555777777777777775033333333333333055555555555555555555555555555555555555555555550500000000000000000000000000000000
5650a55898955565577cccccc666666503ccccccccc3333077777777777777775555556555555555556555555555555500000000000000000000000000000000
5659500550a58065577cccccc6555555039cc8ccaac3333077777777777777775555666655555555555545554555605500000000000000000000000000000000
56059a8a9505a5655777777776666655039cc88caac3333077000066611611775555666655555555555555555555555500000000000000000000000000000000
5660a50005050a65577cc77cc6565655035555555553333077000006111161775556664666555555554550545455555500000000000000000000000000000000
5666666666666665577cc77cc656567503ccccccccc3333077000066661116775556044446665555555555555055455500000000000000000000000000000000
566655aaa5576665577cc77cc766667503c8ccccccc3663077000060616111775566444404466655555054555555505500000000000000000000000000000000
5666555a55576665577777777656567503c8c9ceecc3663077000066611611775660444444406655555555555055565500000000000000000000000000000000
5667a55a55a776655777777776565675033333333333663077000006111161775661446111446655564555555455555500000000000000000000000000000000
5667aaaaaaa77665577cc77cc7756775037337337333333077000066611116775611666610611665566555555555445500000000000000000000000000000000
5667a55555a77665577cc77cc776577507373373373333307706c060661111776414466666661465555555554555555000000000000000000000000000000000
5677777777777765577cc77cc775677507337373733333307706606661611177651466aaaa661465555505555555555500000000000000000000000000000000
567777666677776557777666667777750333333333333330770060061116117761146aa6a6a66446555550555555545500000000000000000000000000000000
6677776bb677776657777655567777750333555555553330770060666111617766466aa666a66646554555055545555500000000000000000000000000000000
6777776bb67777765777765556777775060000000000006077446460611116776666aaaa6aaa6666550554555555545500000000000000000000000000000000
6777776bb6777776577776555677777506000000000000607744646661111177666aaaaa6aaaa666555555555555555500000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888eeeeee888eeeeee888eeeeee888777777888888888888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88ee88eee88ee888ee88ee888ee88778787788888888888888888888888888888888888ff888ff888222222888222822888882282888888222888
888eee8e8ee8eeee8eee8eeeee8ee8eeeee8ee87778787788888e88888888888888888888888888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8eeee8eee8eee888ee8eeee88ee8777888778888eee8888888888888888888888888888ff888ff888222222888888222888228882888822288888
888eee8e8ee8eeee8eee8eee8eeee8eeeee8ee87777787788888e88888888888888888888888888888ff888ff888822228888228222888882282888222288888
888eee888ee8eee888ee8eee888ee8eee888ee877777877888888888888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee877777777888888888888888888888888888888888888888888888888888888888888888888888888888888888
111111111ddd1d1d1ddd1ddd1ddd1d111ddd11111ddd1d1d1d111d111ddd1ddd1111111111111111111111111111111111111111111111111111111111111111
111111111d111d1d1d1d1ddd1d1d1d111d1111111d1d1d1d1d111d111d1111d11111111111111111111111111111111111111111111111111111111111111111
1ddd1ddd1dd111d11ddd1d1d1ddd1d111dd111111dd11d1d1d111d111dd111d11111111111111111111111111111111111111111111111111111111111111111
111111111d111d1d1d1d1d1d1d111d111d1111111d1d1d1d1d111d111d1111d11111111111111111111111111111111111111111111111111111111111111111
111111111ddd1d1d1d1d1d1d1d111ddd1ddd11111ddd11dd1ddd1ddd1ddd11d11111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16661616111116661616161116111666166611111177111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16111616111116161616161116111611116117771171111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16611161111116611616161116111661116111111771111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16111616111116161616161116111611116117771171111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16661616166616661166166616661666116111111177111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161611111ccc11111111111111111ddd11dd11dd111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161617771c1c11111111111111111d1d1d1d1d11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111116111111c1c111111111ddd1ddd1ddd1d1d1ddd111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161617771c1c11711111111111111d111d1d111d111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161611111ccc17111111111111111d111dd11dd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161611111ccc11111111111111111ddd11dd11dd111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161617771c1c11111111111111111d1d1d1d1d11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111166611111c1c111111111ddd1ddd1ddd1d1d1ddd111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111617771c1c11711111111111111d111d1d111d111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111166611111ccc17111111111111111d111dd11dd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111116616661666166611111cc11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611116111161611177711c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666116111611661111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111116116116111611177711c11171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111166116661666166611111ccc1711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116611666166616661166166611111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111616161616661616161116111777111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116161666161616661611166111111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116161616161616161616161117771c1111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116661616161616161666166611111ccc17111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111166166616661666116611111cc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116111161161116161611177711c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116661161166116661666111111c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111161161161116111116177711c1117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111661116116661611166111111ccc171111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666166616661666166116611611161611111ccc1ccc1c1c1ccc11111111111111111ddd1ddd1d1d1ddd11111ddd11dd1ddd11111ddd1ddd11dd1ddd1111
111116111616116116111616161616111616177711c11c1c1c1c1c11111111111111111111d11d1d1d1d1d1111111d111d1d1d1d11111d111d1d1d1d1ddd1111
111116611661116116611616161616111666111111c11cc11c1c1cc1111111111ddd1ddd11d11dd11d1d1dd111111dd11d1d1dd111111dd11dd11d1d1d1d1111
111116111616116116111616161616111116177711c11c1c1c1c1c11117111111111111111d11d1d1d1d1d1111111d111d1d1d1d11111d111d1d1d1d1d1d1111
111116111616166616661616166616661666111111c11c1c11cc1ccc171111111111111111d11d1d11dd1ddd11111d111dd11d1d11111d111d1d1dd11d1d1111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111ddd11dd11dd1ddd1ddd1ddd1d1d1ddd11111ddd11dd1ddd111111dd1ddd1ddd111111111dd11ddd11dd1ddd1ddd1ddd1d1d1ddd11111ddd11dd1ddd
111111111d1d1d1d1d1111d111d111d11d1d1d1111111d111d1d1d1d11111d111d1d1d1d111111111d1d1d111d111d1d11d111d11d1d1d1111111d111d1d1d1d
1ddd1ddd1ddd1d1d1ddd11d111d111d11d1d1dd111111dd11d1d1dd111111ddd1ddd1dd1111111111d1d1dd11d111ddd11d111d11d1d1dd111111dd11d1d1dd1
111111111d111d1d111d11d111d111d11ddd1d1111111d111d1d1d1d1111111d1d111d1d11d111111d1d1d111d1d1d1d11d111d11ddd1d1111111d111d1d1d1d
111111111d111dd11dd11ddd11d11ddd11d11ddd11111d111dd11d1d11111dd11d111d1d1d1111111d1d1ddd1ddd1d1d11d11ddd11d11ddd11111d111dd11d1d
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111ddd1ddd1d1d1ddd1d11111111dd11dd1d1111dd1ddd1111111111111111111111111111111111111111111111111111111111111111111111111111
111111111d1d11d11d1d1d111d1111111d111d1d1d111d1d1d1d1111111111111111111111111111111111111111111111111111111111111111111111111111
1ddd1ddd1ddd11d111d11dd11d1111111d111d1d1d111d1d1dd11111111111111111111111111111111111111111111111111111111111111111111111111111
111111111d1111d11d1d1d111d1111111d111d1d1d111d1d1d1d1111111111111111111111111111111111111111111111111111111111111111111111111111
111111111d111ddd1d1d1ddd1ddd111111dd1dd11ddd1dd11d1d1111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111116616661666166616661666111111111cc11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611161616161161116116111777111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116661666166111611161166111111ccc11c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111116161116161161116116111777111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111166116111616166611611666111111111ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11771111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
17711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116611666166616161111166616161611161116661666116611711171111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616161616161111161616161611161116111161161117111117111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116161661166616161111166116161611161116611161166617111117111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616161616661111161616161611161116111161111617111117111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661616161616661666166611661666166616661161166111711171111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee11ee1eee1111166611111eee1ee111111bbb1b111b1111711666161616111611166616661166117111111ee111ee1111111111111111111111111111
11111e111e1e1e1e11111616111111e11e1e11111b1b1b111b1117111616161616111611161111611611111711111e1e1e1e1111111111111111111111111111
11111ee11e1e1ee111111661111111e11e1e11111bbb1b111b1117111661161616111611166111611666111711111e1e1e1e1111111111111111111111111111
11111e111e1e1e1e11111616111111e11e1e11111b1b1b111b1117111616161616111611161111611116111711111e1e1e1e1111111111111111111111111111
11111e111ee11e1e1111166611111eee1e1e11111b1b1bbb1bbb11711666116616661666166611611661117111111eee1ee11111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1eee11111666111111661666166616661666166611171ccc11111eee1e1e1eee1ee1111111111111111111111111111111111111111111111111
1111111111e11e1111111616111116111616161611611161161111711c1c111111e11e1e1e111e1e111111111111111111111111111111111111111111111111
1111111111e11ee111111661111116661666166111611161166117111c1c111111e11eee1ee11e1e111111111111111111111111111111111111111111111111
1111111111e11e1111111616111111161611161611611161161111711c1c111111e11e1e1e111e1e111111111111111111111111111111111111111111111111
111111111eee1e1111111666117116611611161616661161166611171ccc111111e11e1e1eee1e1e111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111bbb11bb1bbb1bbb1171166611111616111116661111161611111bbb1bbb11bb1171166611111166166616661666166616661171117111111111
1111111111111b1b1b111b1111b11711161611111616111116161111161611111b1b1b1b1b111711161611111611161616161161116116111117111711111111
1111111111111bbb1bbb1bb111b11711166111111161111116611111166611111bbb1bb11bbb1711166111111666166616611161116116611117111711111111
1111111111111b11111b1b1111b11711161611111616117116161111111611711b1b1b1b111b1711161611111116161116161161116116111117111711111111
1111111111111b111bb11bbb11b11171166611711616171116661171166617111b1b1bbb1bb11171166611711661161116161666116116661171117111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1e1111ee1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111e111e111e111e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111ee11e111eee1ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111e111e11111e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1eee1ee11eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111bb1bbb1bbb11711666111116161111166611111616111116661111116616661666166616661666117111111111111111111111111111111111
1111111111111b111b1b1b1b17111616111116161111161611111616111116161111161116161616116111611611111711111111111111111111111111111111
1111111111111bbb1bbb1bb117111661111111611111166111111666111116611111166616661661116111611661111711111111111111111111111111111111
111111111111111b1b111b1b17111616111116161171161611111116117116161111111616111616116111611611111711111111111111111111111111111111
1111111111111bb11b111b1b11711666117116161711166611711666171116661171166116111616166611611666117111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822282228882822282228888888888888888888888888888888888888888888888888222822282228882822282288222822288866688
82888828828282888888828882828828828882828888888888888888888888888888888888888888888888888282828282888828828288288282888288888888
82888828828282288888822282828828822282828888888888888888888888888888888888888888888888888222828282228828822288288222822288822288
82888828828282888888888282828828888282828888888888888888888888888888888888888888888888888282828288828828828288288882828888888888
82228222828282228888822282228288822282228888888888888888888888888888888888888888888888888222822282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__map__
4a4b4a4b4a4b4a4b4a4b4a4b4a4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b4a4b4a4b4a4b4b4a4b4a4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5b5a5b5a5b5a5b5a5b5b5a5b5a5b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4b46474a4a4b42434a4a4b40414a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5a5b56575a5a5b52535a5a5b50515a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4b4a4b4a4b4a4b4a4b4a4b4a4b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b4a4b5b4a4b5a5b5a5b5a5b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5b5a5b5a48495a5b4a4b4a4b4a4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b4a58594a4b4a4b4a4b4a4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5b5a5b5a5b4b5a5b5a5b5a5b5a5b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b5b5a5b4a4b4a4b4a4b4a4b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5b5a5b4b4a4b5a5b5a5b4a4b4a4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b5b5a5b4a4b4a4b5a5b5a5b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5b5a5b4b4a4b4a4b4a4b4a4b4a4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b5b5a5b5a5b5a5b5a5b5a5b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
