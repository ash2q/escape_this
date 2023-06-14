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

top_border=20
bot_border=120
midline=60
r_border=120
l_border=4

function contains(t,v)
	for i in all(t) do
		if i==v then
			return true
		end
	end
	return false
end

item_type={
	x_gun=1,
	z_gun=2,
	boost=3,
	module=4
}

enemies={}
current_mode=nil
prev_mode=nil

in_prompt=false

blink_spec={}

common_trash_range=
		{5,10,15,20}
uncommon_trash_range=
		{10,15,20,25,30}
rare_trash_range=
		{25,35,40,45,50}



function init_boosts()
	blink_spec={
		stype=item_type.boost,
		charge=0,
		regen_rate=200,
		activate_fn=blink_boost,
		update_fn=blink_update,
		draw_fn=draw_blink,
		lbl=48,
		--time before can activate 
		--again
		cooldown=20,
		heat=30,
		name="(b) bullet blink",
		desc=
"a mechanical eye which emits\n"..
"a powerful burst of magnetic\n"..
"energy upon blinking",
		pickup=nop,
		drop=nop,
		trash_range=rare_trash_range,
		base_cost=50
	}
	sb_boost={
 	spec=nil,
		--when r is 0 a charge
		--is added (if not full)
		r=0,
		--count for charge purpose
		c=0,
		frame_count=0,
		cooldown=0
	}
end

function nop()
end


--modules are general stat
--upgrades and some special
--upgrades
modules={}



dev_mode_mod={}
radiator_mod={}

function init_modules()
	dev_mode_mod={
		name="(m) dev mode",
		desc=
"there seems to be a bug stuck\n"..
"in the electronics. best to\n"..
"dismantle it",
		lbl=52,
		do_effect=do_dev_mode,
		undo_effect=undo_dev_mode,
		pickup=pickup_module,
		drop=drop_module,
		stype=item_type.module,
		trash_range=rare_trash_range,
		base_cost=200
	}
	
	radiator_mod={
		name="(m) radiator",
		desc=
"an ancient cooling device. not\n"..
"very efficient but better than\n"..
"nothing. looks shiny",
		lbl=52,
		do_effect=do_radiator,
		undo_effect=undo_radiator,
		pickup=pickup_module,
		drop=drop_module,
		stype=item_type.module,
		trash_range=uncommon_trash_range,
		base_cost=60
	}
end

function pickup_module(m)
	add(equipped_mods,m)
end

function drop_module(m)
	del(equipped_mods,m)
end

function do_dev_mode()
	printh("equipped dev mode")
	sb_currency+=50
end
function undo_dev_mode()
	printh("unequipped dev mode")
	sb_currency-=50
end

function do_radiator()
	sb_cool+=5
end
function undo_radiator()
	sb_cool-=5
end

empty_gun={}
beam_gun={}
simple_chain_gun={}
double_chain_gun={}
x_gun={}
z_gun={}

function init_guns()
	beam_gun={
		lbl=11,
		charge=30,
		heat_rate=2,
		damage_heat_mod=10,
		rate=5
	}
	simple_chain_gun={
		lbl=10,
		charge=0,
		--each projectile increases
		--sb_heat by this amount
		heat_rate=10.0,
		cool_rate=1.0,
		dmg=5,
		rate=5,
		shoot=shoot_chain,
		shoot_heated=shoot_heated_chain,
		name="(x) simple chain gun",
		desc=
"a simple machine gun. seems to\n"..
"give its holder slightly more\n"..
"max health",
		stype=item_type.x_gun,
		pickup=function(i)
			sb_health+=20
			sb_max_health+=20
		end,
		drop=function(i)
			sb_max_health-=20
		end,
		trash_range=common_trash_range,
		base_cost=40
	}
	double_chain_gun={
		lbl=53,
		charge=0,
		--each projectile increases
		--sb_heat by this amount
		heat_rate=8.0,
		cool_rate=1.0,
		dmg=4,
		rate=3,
		shoot=shoot_chain,
		shoot_heated=shoot_heated_chain,
		name="(x) double chain gun",
		desc=
"a double machine gun, shoots\n"..
"fast, warms up even faster\n",
		stype=item_type.x_gun,
		pickup=nop,
		drop=nop,
		trash_range=uncommon_trash_range,
		base_cost=80
	}
	
	--x is primary/fast
	x_gun={
		--spec should be const
		spec=chain_gun,
		heat=0.0,
		--multiplier for heat rate
		heat_mul=1.0,
		--bonus damage for heated gun
		heated_dmg=1.5,
		--damage multiplier
		dmg_mul=1.0,
		heated=false,
		--max heat
		--note: heat over 100 is
		--considered overheated
		max_heat=150,
		--multipler for cool rate
		cool_mod=1.0,
		c=0, --charge counter
		r=0 --rate counter
	}
	--z is secondary/slow
	z_gun={
		spec=nil
	}
end
--spider bot globals
--animation for player track
sb_anim={20,21,22,23}
--animation when heated
sb_heated_anim={32,33,34,35}
--spiberbot position
sb_x=64
sb_y=70
--if sb moved (for animation)
sb_moved=false

sb_heat=0.0
sb_max_heat=400
sb_health=100
--maximum health
sb_max_health=100
--if heated
sb_heated=false
--incoming damage increase for
--being heated
sb_heated_mul=2.0
--rate at which sb cools
sb_cool=1.5
--multiplier for gun heat
sb_gun_heat_mul=1.0
--speed of movement
sb_speed=1.0
--how quick of fire rate
sb_rate_mod=1.0
--while a gun is overheated add
--this amount to sb_heat
sb_gun_overheat=40.0
--invincibility
sb_inv_dur=100
sb_inv_count=0
--how many frames must wait to
--get another charge
sb_boost_timer=60
sb_boost_max_charges=2
sb_boost_charges=1
sb_boost=nil
sb_boost_heat_mul=1.0
sb_currency=0
--mod globals
sb_expert_mod=false

extra_lives=0

current_stage=nil

function reset_sb()
	sb_x=64.0
	sb_y=70.0
	--sb_health=sb_max_health
	sb_heat=0.0
	sb_heated=false
	x_gun.heat=0
	z_gun.heat=0
	sb_boost_charges=
			sb_boost_max_charges
	--sb_heat=200.0 --testing
	enemies={}
	bullets={}
	explosions={}
end

function reset_stage()
	reset_sb()
	current_mode=stage_mode
 current_stage()
end

--to skip navigating in the map
dev_shortcut = false
--dev_shortcut = true

begin_time=0
total_damage=0

function _init()
	begin_time=time()
	printh("--init--")
	init_guns()
	init_modules()
	init_enemies()
	init_boosts()
	init_locations()
	init_shops()
	sb_health=sb_max_health
	reset_sb()
	equip(simple_chain_gun)
	equip(double_chain_gun)
	equip(blink_spec)
	equip(dev_mode_mod)
	if dev_shortcut then
		--testing
		--load_pockets()
		current_mode=inv_mode
		--current_mode=stage_mode
		--reactor()
	else
		current_mode=map_mode
		build_map()
	end
end


prompt_msg_fn=nil
prompt_confirm=nil
prompt_cancel=nil
--the human must take their
--fingers off the keys
human_reset=false
function prompt_mode()
	if btn()==0 then
	 human_reset=true
	end
	cls()
	color(7)
	prompt_msg_fn()
	if not human_reset then
	 return
	end
	bx=5 --❎
	if btn(5) then
		prompt_confirm()
	elseif btn(4) then
		--if prompt_cancel!=nil then
		prompt_cancel()
		--end
	end
end

function goto_prompt(confirm,cancel)
	prompt_confirm=confirm
	prompt_cancel=cancel
	prev_mode=current_mode
	current_mode=prompt_mode
	human_reset=false
end

function map_mode()
	cls()
	sb_moved=false
	
	player_control()
	draw_map()
	draw_player()
	check_player_choice()
	--if in_prompt then
	--	prompt_mode()
		--human_reset=false
	--end
end


function stage_mode()
	cls()
	sb_moved=false
	
	player_control()
	gun_control()
	enemy_control()
	boost_control()
	
	--collisions
	move_bullets()
	boost_update()
	
	draw_player()
	draw_enemies()
	
	draw_bullets()
	draw_explosions()
	draw_hud()
	draw_boosts()
	
	clean_bullets()
	clean_enemies()
	
	x_gun.heat-=
		x_gun.spec.cool_rate*
		x_gun.cool_mod
		
	if x_gun.heat<0 then
		x_gun.heat=0
	end
	if z_gun.spec!=nil then
		z_gun.heat-=z_gun.cool
		if z_gun.heat<0 then
			z_gun.heat=0
		end
	end
	if sb_heat > sb_max_heat then
		sb_heated=true
		sb_heat=sb_max_heat
	end
	sb_heat-=sb_cool
	if sb_heat<0 then
		sb_heat=0.0
		sb_heated=false
	end
	if sb_health<=0 then
		extra_lives-=1
		human_reset=false
		current_mode=game_over_mode
	end
	if #enemies==0 then
		prompt_msg_fn=function()
			print("stage complete!\n"..
				"❎ to continue\n"..
				"🅾️ to return to map")
			end
		goto_prompt(next_stage,
			stage_exit)
		current_mode=prompt_mode
		human_reset=false
	end
end

end_time=0
function game_over_mode()
	if end_time==0 then
		end_time=time()
	end
	if btn()==0 then
		human_reset=true
	end
	cls()
	if extra_lives<0 then
		color(7)
		print("you could not escape this")
		print("chips: "..sb_currency..
				", pockets:")
		y=12
		y=print_pocket(y)
		color(7)
		stage="l-"
		if in_reactor then
			stage="r-"..reactor_depth
		end
		total_time=end_time-begin_time
		print("stage: "..
			stage..
			", time: "..flr(total_time)..
			"s",0,y)
			y+=8
		print("total damage: "..
				total_damage)
		print("❎ to reboot")
		y+=8
		if btn(5) and human_reset then
			extcmd("reset")
			stop()
		end
	else
		print("it seems as though you")
		print("have another chance")
		print("extra lives: "..
				extra_lives)
		print("❎ to try again")
		if btn(5) and human_reset then
			end_time=0
			reset_stage()
		end
	end
end


function _update()	
	if acnt > 1000 then
		acnt = 0
	end
	acnt+=1
	current_mode()
end

sb_pocket={}
sb_pocket_max=6
inv_line=1
function inv_mode()
	cls()
	color(7)
	print("❎=equip,⬅️=unequip")
	print("🅾️=dismantle, ➡️=exit")
	print("chips: "..sb_currency..
		", space: "..
		(sb_pocket_max-#sb_pocket))
	--offset includes
	--item icon and arrow
	x=14
	y=20
	lines={}
	for g in all(sb_pocket) do
		c=6
		if equipped(g) then
			c=10
		end
		add(lines,{
			y=y,
			i=g
		})
		print_item(g,x,y,c)
		y+=10
	end
	rect(0,103,127,127,7)
	item=lines[inv_line].i
	print(item.desc,2,105,7)
	inv_navigate(lines)
end
--1=x,2=z,3=b,4=m
inv_line_pocket=1
inv_line=1
inv_pressed=false

function inv_navigate(lines)
	if btn()==0 then
		human_reset=true
	end
	if not human_reset then
		return
	end
	item=lines[inv_line].i
	--draw pointer
	spr(49,0,lines[inv_line].y)
	
	--down
	if btn(3) and not inv_pressed
		then
		inv_pressed=true
		inv_line+=1
		if inv_line>#lines then
			inv_line=1
		end
	end
		--up
	if btn(2) and not inv_pressed
		then
		inv_pressed=true
		inv_line-=1
		if inv_line<1 then
			inv_line=#lines
		end
	end
	--equip
	if btn(5) and not inv_pressed
		then
		inv_pressed=true
		equip(item)
	end
	--exit
	if btn(1) and not inv_pressed
		then
		if in_shop then
			in_shop_inv=false
			human_reset=false
		else
			current_mode=map_mode
			in_prompt=false
		end
		
	end
	--unequip
	if btn(0) and not inv_pressed
		then
		inv_pressed=true
		unequip(item)
	end
	--dismantle
 if btn(4) and not inv_pressed
		then
		inv_pressed=true
		dismantle(item)
		inv_line=1
	end
	if btn()==0 then
		inv_pressed=false
	end
end

function pickup_item(a)
	if not 
			contains(sb_pocket,a)
		then
		add(sb_pocket, a)
		a.pickup()
		return a
	end
	--if already exists then nil
	return nil
end

function drop_item(a)
	if 
			contains(sb_pocket,a)
		then
		a.drop()
		del(sb_pocket, a)
		return a
	end
	--if already exists then nil
	return nil
end

in_dismantle=false
function dismantle(a)
	if equipped(a) then
	 --can't dismantle unless unequipped
		return
	end
	prompt_msg_fn=function()
print("dismantle "..
sub(a.name,5).."?\n"..
"(❎ to confirm)",8)
	end
	goto_prompt(function()
		drop_item(a)
		range=a.trash_range
		reward=flr(rnd(range))
		sb_currency+=reward
		prompt_msg_fn=function()
		print("you dismantled "..
				sub(a.name,5).."\n"..
				"and got "..reward.." chips")
	end
		goto_prompt(return_to_inv,
				return_to_inv)
end,
			return_to_inv)
end

function return_to_inv()
	if in_shop_inv then
		current_mode=shop_mode
	else
		current_mode=inv_mode
	end
end

function equipped(g)
	return (x_gun.spec==g or
				z_gun.spec==g or
				sb_boost.spec==g or
				contains(modules,g))
end

function equip(g)
	--pickup if not already in
	--pocket
	pickup_item(g)
	stype=g.stype
	if stype==item_type.x_gun then
		x_gun.spec=g
	elseif stype==item_type.z_gun then
		z_gun.spec=g
	elseif stype==item_type.boost then
		sb_boost.spec=g
	elseif stype==item_type.module then
		if not contains(modules,g) then
			g.do_effect()
			add(modules,g)
		else
			return
		end
	end
end

function unequip(g)
	stype=g.stype
	if stype==item_type.x_gun then
		--does nothing, can't unequip
		--x_gun
	elseif stype==item_type.z_gun then
		z_gun.spec=nil
	elseif stype==item_type.boost then
		sb_boost.spec=nil
	elseif stype==item_type.module then
		if contains(modules,g) then
			g.undo_effect(g)
			del(modules,g)
		end
	end
end

function print_pocket(y)
	x=10
	for i in all(sb_pocket) do
		if equipped(i) then
			print_item(i,x,y,10)
		else
			print_item(i,x,y,6)
		end
		y+=10
	end
	return y
end

function print_item(g,x,y,c)
		print(g.name,x,y+2,c)
		spr(g.lbl, x-10,y)
		y+=8
end


-->8
--hud

health_col={8,9,10,11}
heat_col={12,11,10,9,8,8}

function draw_hud()
	--10, 11
	rectfill(0,0,128,7,5)
	--draw x meter
	--draw_gun_hud(45,z_gun)
	--draw z meter
	draw_gun_hud(0,x_gun)
	--draw g meter
	spr(12,83,0)
	health_meter(91,1,sb_health)
	
	print("x"..extra_lives,105,2,7)
	draw_boost_hud()
	rectfill(115,1,126,6,8)
	
	--currency
	rectfill(60,1,60+20,6,0)
	spr(54,60,1)
	print(""..sb_currency,69,2,7)
	
	
	if in_reactor then
		print("r-"..reactor_depth,
				116,2,7)
	else
	 --todo when lab
	end
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
		flr(gun.heat),
			flr(gun.max_heat))
	if gun.spec.charge>0 then
		for i=1,5 do
			gi=i*3
			col=0
			rectfill(
				offset+19+gi,3,
				offset+20+gi,5,
				col
			)
		end
	end
	palt(0, true)
end

function health_meter(x,y)
	--heat meter
	warning=sb_health <=
		sb_max_health/2
	danger=sb_health <=
		sb_max_health/4
	col=11 --green
	if danger then
		col=8 --yellow
	elseif warning then
		col=10
	end
	x1=x
	x2=x+12
	y1=y
	y2=y+5
	--black box
	rectfill(x1,y1,x2,y2,0)
	--draw bar
	rectfill(
		x,y,
		x+(12.0*((sb_health+.0)
			/sb_max_health)),
		y+5,
		col)

		--rectfill(x1,y1,x+i*2,y2,col)
	if (acnt%4==0 or acnt%2==0) and
				sb_heated then
		--blinks red until cooled to 0
		if not danger then
			rectfill(
				x,y,
				x+(12.0*((sb_health+.0)
					/sb_max_health)),
				y+5,
				8)
		else
			rectfill(
				x,y,x+12,
				y+5,0
				)
		end
	end
end

function heat_meter(x,y,heat,
			max_heat)
--heat meter
	for i=1,6 do
		gi=i*2
		--10 pixel wide bars
		tmp=(i*10)
		tmp=(max_heat/60)*tmp
		if heat >= tmp then
			rectfill(
				x+gi,y,x+1+gi,
				y+5,
				heat_col[i]
				)
				if (acnt%4==0 or acnt%2==0) and
							heat >= 100 then
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

function draw_boost_hud()
	offset=40
	palt(0, false)
	boost=nil
	if sb_boost.spec==nil then
	--empty label
		spr(31,offset,0)
		palt(0,true)
		return
	end
	boost=sb_boost
	spr(boost.spec.lbl,offset,0)
	for i=1,sb_boost_max_charges
	 do
		x=(offset+8)+(i-1)*3
		y=3
		if sb_boost_charges>=i then
			rectfill(x,y,x+1,y+2,7)
		else
			rectfill(x,y,x+1,y+2,0)
		end
	end
	
	
	palt(0,true)
end
-->8
--controls and boosts



function player_control()
	l=0
	r=1
	u=2
	d=3
	bx=5
	bz=4
	x=sb_x
	y=sb_y
	if btn(l) then
		sb_x-=sb_speed
	end
	if btn(r) then
		sb_x+=sb_speed
	end
	if btn(u) then
		sb_y-=sb_speed
	end
	if btn(d) then
		sb_y+=sb_speed
	end
	if sb_y != y or 
			 sb_x != x then
			 sb_moved=true
	else
			sb_moved=false
	end
	--keep from going out of bounds
	m=midline
	if current_mode!=stage_mode
	 then
		m=1
	end
	if sb_y<m or
				sb_y>bot_border then
		sb_y=y
	end
	if sb_x<l_border or
				sb_x>r_border then
		sb_x=x
	end
end


function gun_control()
	bx=5
	bz=4
	x=sb_x
	y=sb_y
	local spec=x_gun.spec
	if btn(bx) and not btn(bz) then
		--do rate of fire
		if x_fire_rate() then
			--shoot bullet now
			if x_gun.heat>100 then
				spec.shoot_heated()
			else
				spec.shoot()
			end
			x_gun.heat+=
				(x_gun.spec.heat_rate*
				x_gun.heat_mul)*
			 sb_gun_heat_mul
			--x_gun.heat+=spec.heat_rate
			--x_gun.heat*=sb_gun_heat_mul
			if x_gun.heat>100
	 	then
				sb_heat+=sb_gun_overheat
			end
		else
			--in between bullets
		end
	end --end if btn(x)
	if x_gun.heat>x_gun.max_heat
		then
  x_gun.heat=x_gun.max_heat
 end
	x_gun.r=max(x_gun.r,0)
	--z_gun.r=max(z_gun.r,0)
	if sb_inv_count>0 then
		sb_inv_count-=1
	end
end

function boost_control()
--🅾️ is 4
--❎ is 5
	if sb_boost.cooldown>0 then
		sb_boost.cooldown-=1
		return
	end
	if btn(5) and btn(4) and
		(sb_expert_mod or not
		 sb_heated)
	then
		--reset timer on next boost
		sb_boost.r=
			sb_boost.spec.regen_rate
		if sb_boost.spec!=nil then
			if sb_boost_charges>0 then
				--use boost immediately
				sb_boost_charges-=1
				sb_boost.cooldown=
						sb_boost.spec.cooldown
				sb_boost.spec.activate_fn(
						sb_boost)
				sb_heat+=sb_boost.spec.heat*
						sb_boost_heat_mul
				end
			else
				sb_boost_charges=0
			end
	end
end


--this implements rate of fire
function x_fire_rate()
	if x_gun.r>=x_gun.spec.rate then
		x_gun.r=0
	else
		x_gun.r+=sb_rate_mod
	end
	if not sb_expert_mod then
		if sb_heated then
			return false
		end
	end
	return x_gun.r==0
end

		
--deletes all enemy bullets
function blink_boost(b)
	b.frame_count=3
	for b in all(bullets) do
		if not b.friendly then
			del(bullets,b)
		end
	end
end

function blink_update(b)
	b.frame_count-=1
end

function boost_update()
	if sb_boost.spec==nil then
		return
	end
	sb_boost.spec.update_fn(
			sb_boost)
	r=sb_boost.r
	if r<=0 and 
			sb_boost_charges<sb_boost_max_charges
	 then
		sb_boost_charges+=1
		sb_boost.r=
				sb_boost.spec.regen_rate
	elseif r>0 then
		sb_boost.r-=1
	end
end



-->8
--drawing

function draw_player()
	x=sb_x
	y=sb_y
	
	anim=sb_anim
	if sb_heated then
		anim=sb_heated_anim
		--particle effects
		for i=0,4 do
			rx=(x-5)+rnd(10)
			ry=(y-6)+rnd(8)
			pset(rx, ry, 8)
		end
	end
	if sb_inv_count==0 
				or acnt%3==0 then
		if sb_moved then
				spr(anim[
					1+(acnt%#anim)],
					sb_x-4,sb_y-4)
		else
				spr(anim[1],
					sb_x-4,sb_y-4)
		end
	end
end

function draw_enemies()
	for e in all(enemies) do
		tmp=acnt%#e.spec.anim
		spr(e.spec.anim[1+tmp],
			e.x-4, e.y-4,1,1,
			e.flip_x,e.flip_y)
	end
end

--these are cosmetic only
--s is background sprite
function add_big_explosion(s,x,y)
	e={
		s=s,
		x=x,
		y=y,
		anim={36,37,38,39,40,41},
		frame=1
	}
	add(explosions,e)
end

function draw_explosions()
	for ex in all(explosions) do
		--bottom layer
		if ex.s!=nil then
			spr(ex.s,ex.x,ex.y)
		end
		anim=ex.anim
		if ex.frame<=#anim then
			spr(anim[ex.frame],
				ex.x,ex.y)
		end
		ex.frame+=1
		if ex.frame>=#ex.anim then
			del(explosions,ex)
		end
	end
end

function draw_map()
 map(0,0,0,0,128,128)
	for l in all(locations) do
		--spr(l.loc.sprite,l.x,l.y,2,2)
	end
end

function draw_boosts()
	if sb_boost.spec==nil then
		return
	end
	sb_boost.spec.draw_fn(sb_boost)
end

function draw_blink(b)
	if b.frame_count>0 then
		rectfill(0,0,128,128,7)
	end
end
-->8
--projectiles

bullets={}
explosions={}

explosion_anim={
	36,37,38,39,40,41
}
hit_anim={43,44,45}

function draw_bullets()
	for b in all(bullets) do
		if b.sprite<0 then
			pset(b.x,b.y,abs(b.sprite))
		else
		 --spr(b.x,b.y,b.sprite)
		end
	end
end



function move_bullets()
	for b in all(bullets) do
		b.xprev=b.x
		b.yprev=b.y
		b.step_fn(b)
		--x,y now updated
		--check collisions
		check_bullet(b)
	end
end

function check_bullet(b)
	if b.friendly then
		for e in all(enemies) do
	--deduct centering offset
			if b.collision_fn(b,
					e.x-4,e.y-4)
			 then
			 e.health-=b.dmg
			 total_damage+=b.dmg
			 explode_hit(b.x,b.y)
			 del(bullets,b)
			end
		end
	else
		if b.collision_fn(b,
			sb_x-4, sb_y-4)
		then
			explode_hit(b.x,b.y)
			if sb_inv_count==0 then
				if sb_heated then
					sb_health-=
							b.dmg*sb_heated_mul
				else
					sb_health-=b.dmg
				end
				sb_inv_count+=
						sb_inv_dur
			end
			del(bullets,b)
		end
	end
end

function clean_bullets()
	for b in all(bullets) do
		if b.x<0 or b.y<0 or
					b.x>128 or b.y>128 then
			del(bullets,b)
		end
	end
end

function shoot_chain()
	x1=sb_x
	--undo draw centering
	y=sb_y-4
	dmg=x_gun.spec.dmg
	blt=blt_straight(x1,y,dmg)
	blt.speed=1.5
	add(bullets,blt)
end

function shoot_heated_chain()
	x1=sb_x
	--undo draw centering
	y=sb_y-4
	dmg=x_gun.spec.dmg
	blt=blt_heated_straight(x1,y,
		dmg)
	blt.speed=1.5
	add(bullets,blt)
end

function blt_straight(x,y,dmg)
	blt={}
	blt.x=x
	blt.y=y
	blt.xend=x
	blt.yend=0
	blt.size=1
	blt.dmg=dmg
	blt.steps=1
	--note be careful, speed
	--shouldn't be too fast
	blt.speed=1.0
	blt.friendly=true
	blt.sprite=-7
	blt.hit_fn=hit_blt
	blt.step_fn=step_straight
	blt.collision_fn=col_pixel
	return blt
end

function blt_heated_straight(x,y,dmg)
	blt=blt_straight(x,y,dmg)
	blt.sprite=-8
	return blt
end

function blt_line(x,y,dmg)
	--get default
	blt=blt_straight(x,y,dmg)
	blt.xend=sb_x
	blt.yend=sb_y
	blt.step_fn=step_line
	return blt
end

function hit_blt(blt, e)
	e.health-=blt.damage
end

function col_pixel(b,x2,y2,
			w,h)
--x1,y1 = pixel bullet
--x2,y2 = target sprite to check
--w,h = size of target sprite
	--defaults to 8x8
	w=w or 8
	h=h or 8
	if not check_col(b.x,b.y,1,1,
			x2,y2,w,h) then
		return false
	end
	return true
	--do pixel perfect check
	--assumes black background
	--col=pget(b.x,b.y)
	--return col!=0
end


function step_straight(b)
	--modify x,y
	if b.x<b.xend then
		b.x+=b.speed
	elseif b.x>b.xend then
		b.x-=b.speed
	end
	if b.y<b.yend then
		b.y+=b.speed
	elseif b.y>b.yend then
		b.y-=b.speed
	end
end

--follows a fixed line 
--toward end position
function step_line(b)
	if b.xstart==nil then
		b.xstart=b.x
	end
	if b.ystart==nil then
		b.ystart=b.y
	end
	xd=b.xstart-b.xend
	yd=b.ystart-b.yend
	ang=atan2(xd,yd)
	b.x-=b.speed*cos(ang)
	b.y-=b.speed*sin(ang)	
end

--e is enemy. optional
function explode_hit(x,y)
	local ex={}
	ex.s=nil
	ex.anim=hit_anim
	ex.frame=1
		--centering offset
	ex.x=x-4
	ex.y=y-4
	add(explosions,ex)
	return ex
end
-->8
--enemies

--enemy that stays still and 
--shoots toward the location
--of the player sprite

e_spec_spitter=nil
e_spec_flier=nil
e_spec_wall=nil

function init_enemies()
	e_spec_spitter={
		anim={16,17,18,19},
		speed=0,
		blt_speed=0.8,
		gun=chain_gun,
		trace=trace_still,
		update=spitter_update,
		health=50,
		rate=40,
		dmg=30,
		reward=2,
		flip_dir_h=false,
		flip_dir_v=false
	}
	e_spec_wall={
		anim={59},
		speed=0,
		blt_speed=0,
		gun=chain_gun,
		trace=trace_still,
		update=trace_still,
		health=50,
		rate=40,
		dmg=30,
		reward=1,
		flip_dir_h=false,
		flip_dir_v=false
	}
	e_spec_flier={
		anim={55,56,57,58},
		speed=0.5,
		blt_speed=0.6,
		gun=chain_gun,
		trace=trace_slide,
		update=flier_update,
		health=50,
		rate=40,
		dmg=30,
		reward=2,
		--flip sprite when moving 
		--opposite direction
		flip_dir_h=true,
		flip_dir_v=false
	}
end

function clean_enemies()
	for e in all(enemies) do
		if e.health<=0 then
			sb_currency+=e.reward
			del(enemies,e)
			add_big_explosion(
				e.spec.anim[1],
				e.x-4,e.y-4)
		end
	end
end

function spawn_wall(x,y)
	e={
		x=x,
		y=y,
		rate_mul=1.0,
		dmg_mul=1.0,
		reward=e_spec_wall.reward,
		health=e_spec_wall.health,
		spec=e_spec_wall,
		flip_x=false,
		flip_y=false
	}
	add(enemies,e)
	return e
end

function spawn_spitter(x,y)
	e={
		x=x,
		y=y,
		rate_mul=1.0,
		dmg_mul=1.0,
		reward=e_spec_spitter.reward,
		health=e_spec_spitter.health,
		spec=e_spec_spitter,
		flip_x=true,
		flip_y=false
	}
	add(enemies,e)
	return e
end

function spawn_flier(x,y)
	e={
		x=x,
		y=y,
		rate_mul=1.0,
		dmg_mul=1.0,
		reward=e_spec_flier.reward,
		health=e_spec_flier.health,
		spec=e_spec_flier,
		flip_x=true,
		flip_y=false,
		moved=false
	}
	add(enemies,e)
	return e
end

function enemy_control()
	for e in all(enemies) do
		e.spec.trace(e)
		e.spec.update(e)
	end
end

--traces are enemy movement
--patterns
function trace_still(e)
	--do nothing
end

--moves back and forth
--along x axis
--turns around if obstacle
--or border
function trace_slide(e)
	xold=e.x
	if e.flip_x then
		e.x+=e.spec.speed
	else
		e.x-=e.spec.speed
	end
	--check collisions
	--turn around if hit something
	for en in all(enemies) do
		if en!=e then
			if check_col(
					e.x,e.y,8,8,
					en.x,en.y,8,8)
					or e.x<=3
					or e.x>=125
				then
				e.x=xold
				e.flip_x=not e.flip_x
			end
		end
	end
end

function spitter_update(e)
	if e.r==nil then
		e.r=0
	end
	if e.r<e.spec.rate*e.rate_mul
	 then
		e.r+=1
		return
	end
	e.r=0
	--fire bullet
	blt=blt_line(e.x,e.y+4,
			e.spec.dmg*e.dmg_mul)
	blt.friendly=false
	blt.speed=e.spec.blt_speed
	add(bullets,blt)
end

function flier_update(e)
	if e.r==nil then
		e.r=0
	end
	if e.r<e.spec.rate*e.rate_mul
	 then
		e.r+=1
		return
	end
	e.r=0
	--fire bullet
	blt=blt_line(e.x,e.y+4,
			e.spec.dmg*e.dmg_mul)
	blt.friendly=false
	blt.speed=e.spec.blt_speed
	add(bullets,blt)
end

-->8
--stages and maps

--the lab contains random stages

--the reactor contains fixed
--stages



function stage_1()
	spawn_spitter(10,30)
	spawn_spitter(80,40)
	spawn_wall(30,15)
	spawn_flier(5,15)
end
function stage_2()
	spawn_spitter(10,30).reward+=1
	spawn_spitter(80,30).reward+=1
	spawn_spitter(40,30).reward+=1
end

in_reactor=false
reactor_depth=1

reactor_stages={
	stage_1,stage_2
}

function enter_reactor()
	in_reactor=true
	reset_sb()
	current_mode=stage_mode
	if 
		reactor_depth>#reactor_stages
		then
		current_stage=reactor_stages
			[#reactor_stages]
	else
		current_stage=reactor_stages
			[reactor_depth]
	end
	current_stage()
end

locations={}
reactor_loc=nil
home_loc=nil
mechanic_loc=nil


function init_locations()
	reactor_loc={
		launches=enter_reactor,
		cancel=stage_cancel,
		msg=
			"enter reactor? (❎ for yes)"
	}
	home_loc={
		launches=enter_home,
		cancel=back_to_map,
		msg=
			"enter home? (❎ for yes)"
	}
	mechanic_loc={
		launches=enter_mechanic,
		cancel=back_to_map,
		msg=
			"enter shop? (❎ for yes)"
	}
	
end

function enter_home()
	reset_sb()
	human_reset=false
	current_mode=inv_mode
end






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
	add_map_loc(4*8,7*8,
		home_loc)
	add_map_loc(2*8,3*8,
		mechanic_loc)
end

function check_col(x1,y1,w1,h1,
										x2,y2,w2,h2)
	x_col=false
	--right edge
	if x1<x2+w2 and x1>=x2 then
		x_col=true
	end
	--left edge
	if x1+w1>x2 and x1<=x2+w2 then
		x_col=true
	end
	y_col=false
	if y1<y2+h2 and y1>=y2 then
		y_col=true
	end
	if y1+h1>y2 and y1<=y2+h2 then
		y_col=true
	end
	
	return x_col and y_col
end

function check_player_choice()
	for l in all(locations) do
	--subtract 4 to deduct
	--draw centering
		if check_col(sb_x-4,
							sb_y-4,
							8,
							8,
							l.x,
							l.y,
							16,
							16) then
			--player chose
			prompt_msg_fn=function()
				print(l.loc.msg)
			end
			goto_prompt(l.loc.launches,
					l.loc.cancel)
			
			return
		end
	end
end

function back_to_map()
	reset_sb()
	current_mode=map_mode
	printh("back_to_map")
end


function next_stage()
	if in_reactor then
		reactor_depth+=1
		reset_stage()
		enter_reactor()
	else
		--todo
	end
end
function stage_exit()
	if in_reactor then
		reactor_depth+=1
		back_to_map()
	else
	--todo
		lab_depth+=1
		back_to_map()
	end
end
function stage_cancel()
	back_to_map()
end

function init_shops()
	mechanic_pocket={
		radiator_mod,
		simple_chain_gun
	}
	
end

function enter_mechanic()
	reset_sb()
	human_reset=false
	shop_msg=
"the mechanic bot watches you"
	shop_pocket=mechanic_pocket
	in_prompt=false
	current_mode=shop_mode
end

mechanic_pocket={}
vending_pockets={}
shop_pocket={}
in_shop=false
in_shop_inv=false
shop_line=1
shop_cost_mul=1.0
shop_msg=nil
shop_pressed=false
function shop_mode()
	assert(#shop_pocket>0)
	cls()
	in_shop=true
	if in_shop_inv then
		inv_mode()
		return
	end
	color(7)
	space=sb_pocket_max-#sb_pocket
	print(shop_msg)
	print("❎=buy,🅾️=inventory")
	print("➡️=exit")
	print("chips: "..sb_currency..
		", space: "..
		space)
	--offset includes
	--item icon and arrow
	x=14
	y=24
	lines={}
	for g in all(shop_pocket) do
		c=7
		add(lines,{
			y=y,
			i=g
		})
		cost=shop_cost(g.base_cost)
		if cost>sb_currency then
			c=8
		end
		if contains(sb_pocket,g) then
			c=5
		end
		print_shop_item(g,x,y,cost,c)
		y+=10
	end
	rect(0,103,127,127,7)
	item=lines[shop_line].i
	print(item.desc,2,105,7)
	shop_navigate(lines)
	in_shop=false
end

function shop_cost(base)
		cost=base*shop_cost_mul
		return cost
end

function shop_navigate(lines)
	if btn()==0 then
		human_reset=true
	end
	if not human_reset then
		return
	end
	item=lines[shop_line].i
	--draw pointer
	spr(49,0,lines[shop_line].y)
	
	--down
	if btn(3) and not shop_pressed
		then
		shop_pressed=true
		shop_line+=1
		if shop_line>#lines then
			shop_line=1
		end
	end
		--up
	if btn(2) and not shop_pressed
		then
		shop_pressed=true
		shop_line-=1
		if shop_line<1 then
			shop_line=#lines
		end
	end
	--buy
	if btn(5) and not shop_pressed
		then
		shop_pressed=true
		sb_currency-=shop_cost(
				item.base_cost)
		pickup_item(item)
	end
	--inventory
	if btn(4) and not shop_pressed
		then
		shop_pressed=true
		human_reset=false
		in_shop_inv=true
	end
	--exit
	if btn(1) and not shop_pressed
		then
		shop_pressed=true
		current_mode=map_mode
		in_prompt=false
		shop_pocket={}
	end
	if btn()==0 then
		shop_pressed=false
	end
end



function print_shop_item(g,x,y,cost,c)
		print("["..cost.."] ",x,y+2,10)
		print(g.name,x+16,y+2,c)
		spr(g.lbl, x-10,y)
		y+=8
end
__gfx__
0007700000000000000000000000000000000000000000000cccccc0000009000090000090077009555555555555555555555555006666000066660000555500
00077000006c060000000500005000000060c600006006000a6cc6a0000005000050000080077008500000055606606550000005006006000696696005755750
050660500060c6000000666006660000006c0600006006000a6cc6a0000066600666000050066005500005055067760550666605666006666511115657a66a75
576d1675006c060000006167761600000060c600006006000a6cc6a00000616776160000576d1675506666055670076550688605600000066518815655690655
5761d6750060c6000000616776160000006c0600006006000a6cc6a000006167761600005761d675506500055670076550f33f05600000066518815655609655
05066050006c060000006660066600000060c600006006000a6cc6a000006660066600005006600550600005506776055ffffff5666006666511115657a66a75
0007700000666600000000000000000000666600006666000aa66aa000000000000000008007700850000005560660655f0000f5006006000696696005766750
00077000000770000000000000000000000770000007700000a77a00000000000000000090077009555555555555555555555555006666000066660000566500
00555500005555000055550000555500000660000006600000066000000660000000000000000000000000000000000000000000000000000000000055555555
05555550056556500565565005555550006666000066660000666600006666000000000000000000000900000000000000000000000000000000000050000005
556666555666666556a66a655566665506c88c6006c88c6006c88c6006c88c600000000000900000009000000000000000000000000000000000000050000005
5560965555609655556906555569065506c33c6006c33c6006c33c6006c33c600009000000090000900909000000000000000000000000000000000050000005
5569065555609655556096555569065506cccc6006cccc6006cccc6006cccc600000000009000090090000900000000000000000000000000000000050000005
556666555666666556a66a65556666550ffffff00ffffffffffffffffffffff0009009000090090000900900000000000000000000000000000aa00050000005
05566550056666500566665005566550ff0000ffff00000ff000000ff00000ff000000000000000000000000000000000009900000a99a0000a99a0050000005
00566500005665000056650000566500f000000ff0000000000000000000000f0000000000000000000000000000000000099000000990000009900055555555
00099000000990000009900000099000000000000000000000055000000880000005000000550005000000000000000000000000000000005555555555555555
0099990000999900009999000099990000000000000550000058850000899800050550505050555000000000000000000008800000055000500cc005500cc005
09a88a9009a88a9009a88a9009a88a90000000000058850005899850089aa98000588500050550500005500000099000008998000055550050c11c0550c00c05
09a33a9009a33a9009a33a9009a33a900008800005899850589aa98589a77a98058aa8500058850500599500009aa900089aa980055aa5505c1711c55c6006c5
09aaaa9009aaaa9009aaaa9009aaaa900008800005899850589aa98589a77a98058aa8500058850000599500009aa900089aa980055aa5505c1111c550800805
0ffffff00ffffffffffffffffffffff0000000000058850005899850089aa98000588500000550000005500000099000008998000055550050c11c0550800805
ff0000ffff00000ff000000ff00000ff00000000000550000058850000899800000550000000000000000000000000000008800000055000500cc00550888805
f000000ff0000000000000000000000f000000000000000000055000000880000000000000000000000000000000000000000000000000005555555555555555
55555555000000005555555555555555555555555555555500000000000066600000666000006660000066606666666600000000000000000000000000000000
5006600500000000500bb00550099005500220055000500505555500000655600006556900065568000655606555555600000000000000000000000000000000
5667766570000000500bb00550099005500220055066600505555500006555600065556900655568006555686500005600000000000000000000000000000000
56788765770000005bbbbbb559999995522222255065000505555500065599600655996006559960065599606500005600000000000000000000000000000000
56708765777000005bbbbbb55999999552222225500050050a0a0a00065599600655996006559960065599606500005600000000000000000000000000000000
5667766577000000500bb0055009900550022005506660050a0a0a00006555600065556900655568006555686500005600000000000000000000000000000000
5006600570000000500bb00550099005500220055065000500000000000655600006556900065568000655606555555600000000000000000000000000000000
55555555000000005555555555555555555555555555555500000000000066600000666000006660000066606666666600000000000000000000000000000000
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
