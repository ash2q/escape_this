pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main

--x is primary weapon
--z+x is movement buff (if have)
--z (hold) is special weapon

--animation counter
--provides for anim. 
--of still entities
acnt=1

scroll_speed=4
map_height=128*2

map_window_y=nil

function contains(t,v)
	for i in all(t) do
		if i==v then
			return true
		end
	end
	return false
end
function sh_copy(t)
	c={}
	for k,v in pairs(t) do
		c[k]=v
	end
	return c
end

item_type={
	x_gun=1,
	z_gun=2,
	boost=3,
	module=4
}

enemies={}
stage_enemies={}
current_mode=nil
prev_mode=nil

in_prompt=false

blink_spec={}

common_chip_range=
		{2,10}
uncommon_chip_range=
		{4,15}
rare_chip_range=
		{10,30}
exotic_chip_range=
		{40,80}
--note: this table is indexed
--for determining rarity chip
--rate for dismantling
chip_range={
	common_chip_range,
	uncommon_chip_range,
	rare_chip_range,
	exotic_chip_range
}



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
		base_cost=50,
		rarity=2
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
harness_mod={}
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
		base_cost=200,
		rarity=3
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
		base_cost=50,
		rarity=2
	}
	harness_mod={
		name="(m) harness",
		desc=
"a set of metal brackets and\n"..
"bolts. used to attach a simple\n"..
"gun for shooting backwards",
		lbl=2,
		do_effect=function()
			y_gun.spec=simple_chain_gun
			sb_enable_y_gun=true
		end,
		undo_effect=function()
			sb_enable_y_gun=false
			y_gun.spec=nil
		end,
		pickup=pickup_module,
		drop=drop_module,
		stype=item_type.module,
		base_cost=40,
		rarity=1
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
	sb_max_health+=100
end
function undo_dev_mode()
	printh("unequipped dev mode")
	sb_currency-=50
	sb_max_health+=100
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
texas_chain_gun={}
x_gun={}
z_gun={}



function init_guns()
	simple_chain_gun={
		lbl=10,
		charge=0,
		--each projectile increases
		--sb_heat by this amount
		heat_rate=10.0,
		cool_rate=1.0,
		dmg=5,
		rate=5,
		shots=1,
		shoot=shoot_chain,
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
		base_cost=40,
		rarity=1,
		splash=0
	}
	sine_gun={
		lbl=63,
		charge=0,
		heat_rate=10.0,
		cool_rate=1.0,
		dmg=7,
		rate=5,
		shots=1,
		shoot=shoot_sine,
		name="(x) sine gun",
		desc=
"a gun with a curved barrel.\n"..
"a bit strange, but good damage",
		stype=item_type.x_gun,
		pickup=function(i)
			sb_health+=20
			sb_max_health+=20
		end,
		drop=function(i)
			sb_max_health-=20
		end,
		base_cost=70,
		rarity=1,
		splash=0
	}
	texas_chain_gun={
		lbl=60,
		charge=0,
		heat_rate=30.0,
		cool_rate=1.0,
		dmg=20,
		rate=10,
		shots=1,
		shoot=shoot_big_chain,
		name="(x) texas chain gun",
		desc=
"a ridiculously large caliber\n"..
"gun. slow fire rate, big damage.\n",
		stype=item_type.x_gun,
		pickup=nop,
		drop=nop,
		base_cost=50,
		rarity=3,
		splash=0
	}
		double_chain_gun={
		lbl=53,
		charge=0,
		heat_rate=10.0,
		cool_rate=1.0,
		dmg=6,
		rate=3,
		shots=1,
		shoot=shoot_chain,
		name="(x) double chain gun",
		desc=
"a double machine gun, shoots\n"..
"fast, warms up even faster\n",
		stype=item_type.x_gun,
		pickup=nop,
		drop=nop,
		base_cost=80,
		rarity=1,
		splash=0
	}
	shotty_gun={
		lbl=61,
		charge=0,
		heat_rate=40.0,
		cool_rate=1.0,
		dmg=5,
		rate=15,
		shots=6,
		shoot=shoot_shotgun,
		name="(x) shotty mcshotgun",
		desc=
"ancient and inaccurate, but\n"..
"useful for spray and pray.",
		stype=item_type.x_gun,
		pickup=nop,
		drop=nop,
		base_cost=80,
		rarity=2,
		splash=0
	}
	--note z guns always have suffix
	--of "_laser" even for non-laser
	--type weapons. they just all
	--charge and fire upon release
	beam_laser={
		lbl=1,
		--when charge==100 is charged
		charge_rate=2,
		--each projectile increases
		--sb_heat by this amount
		heat_rate=1,
		cool_rate=0.5,
		dmg=20,
		cooldown=40,
		
		shoot=shoot_beam,
		name="(z) lazer beam",
		desc=
"a slow yet reliable lazer beam.\n"..
"not much heat sinking on it",
	stype=item_type.z_gun,
		pickup=nop,
		drop=nop,
		base_cost=40,
		rarity=2,
		cooldown=20,
		--how long the laser is active
		shoot_frames=20,
		splash=0
	}

	missle_laser={
		lbl=1,
		--when charge==100 is charged
		charge_rate=2,
		--each projectile increases
		--sb_heat by this amount
		heat_rate=1,
		cool_rate=0.5,
		dmg=50,
		cooldown=40,
		
		shoot=shoot_missle,
		name="(z) missle launcher",
		desc=
"fires a large missle which\n"..
"does splash damage to an area",
	stype=item_type.z_gun,
		pickup=nop,
		drop=nop,
		base_cost=100,
		rarity=2,
		cooldown=20,
		splash=2,
		splash_dmg=40
	}

	
	--x is primary/fast
	x_gun={
		--spec should be const
		spec=nil,
		heat=0.0,
		--multiplier for heat rate
		heat_mul=1.0,
		--bonus damage for heated gun
		heated_dmg_mul=3.0,
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
		--y is used for shooting
		--backwards
	y_gun={
	 --spec should be const
		spec=nil,
		heat=0.0,
		--multiplier for heat rate
		heat_mul=0,
		--bonus damage for heated gun
		heated_dmg_mul=1.0,
		--damage multiplier
		dmg_mul=0.8,
		heated=false,
		--max heat
		--note: heat over 100 is
		--considered overheated
		max_heat=1000,
		--multipler for cool rate
		cool_mod=1.0,
		c=0, --charge counter
		r=0 --rate counter
	}
	--z is secondary/slow
	z_gun={
		--spec should be const
		spec=nil,
		heat=0.0,
		--multiplier for heat rate
		heat_mul=1.0,
		--bonus damage for heated gun
		heated_dmg_mul=3.0,
		--damage multiplier
		dmg_mul=1.0,
		heated=false,
		--max heat
		--note: heat over 100 is
		--considered overheated
		max_heat=200,
		--multipler for cool rate
		cool_mod=1.0,
		c=0, --charge counter
		cooldown=0

	}
end

function x_is_heated()
	return x_gun.heat >= 100
end

--spider bot globals
--animation for player track
sb_anim={20,21,22,23}
--animation when heated
sb_heated_anim={32,33,34,35}
sb_charging_anim=
		{128,129,130,131,132}
--play at half speed
sb_charged_anim=
		{133,133,134,134}
--spiberbot position
sb_x=64
sb_y=70
--if sb moved (for animation)
sb_moved=false

sb_heat=0.0
--note for some reason this must
--be a multiple of sb_gun_overheat
sb_max_heat=200
sb_health=100
--maximum health
sb_max_health=100
--if heated
sb_heated=false
--incoming damage increase for
--being heated
sb_heated_mul=2.0
--rate at which sb cools
sb_cool=1.1
--multiplier for gun heat
sb_gun_heat_mul=1.0
--speed of movement
sb_speed=1.5
--how quick of fire rate
sb_rate_mod=1.0
--while a gun is overheated add
--this amount to sb_heat per fire
sb_gun_overheat=30.0
--invincibility
sb_inv_dur=60
sb_inv_count=0
--how many frames must wait to
--get another charge
sb_boost_timer=60
sb_boost_max_charges=2
sb_boost_charges=1
sb_boost=nil
sb_boost_heat_mul=1.0
sb_currency=0
sb_reward_mul=1.0
sb_dmg_mul=1.0
sb_max_charge=100
--mod globals
sb_expert_mod=false
sb_enable_y_gun=false

extra_lives=0

current_stage=nil

function reset_sb()
	sb_x=60.0
	sb_y=100.0
	sb_health=sb_max_health
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
	init_lab()
	init_loot_pool()
	sb_health=sb_max_health
	reset_sb()
	equip(simple_chain_gun)
	equip(blink_spec)
	equip(dev_mode_mod)
	equip(beam_laser)
	fill_vending()
	--make it so beginning equip
	--sfx do not play
	sfx(-1)
	if dev_shortcut then
		--testing
		--load_pockets()
		current_mode=inv_mode
		--current_mode=stage_mode
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

grid_scroll=1
function stage_mode()
	cls()
	c=acnt%scroll_speed
	if c==0 then
		grid_scroll+=1
		map_window_y-=1
		grid_scroll%=scroll_speed
	end
	--draw grid lines
	--horizontal
	for i=0,(128/8) do
		line(0,grid_scroll+i*8,128,
			grid_scroll+i*8,1)
	end
	--vertical
	i=0
	for i=0,(128/8) do
		line(i*8,8,i*8,128,1)
	end
	
	if acnt%scroll_speed==0 then
		scroll_map_enemies()
	end
	sb_moved=false
	
	player_control()
	gun_control()
	enemy_control()
	boost_control()
	
	--collisions
	move_bullets()
	boost_update()
	
	draw_enemies()
	draw_player()

	
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
		z_gun.heat-=
				z_gun.spec.cool_rate*
				z_gun.cool_mod
		if z_gun.heat<0 then
			z_gun.heat=0
		end
	end
	if sb_heat >= sb_max_heat then
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
	if is_stage_empty() and
		map_window_y<0 then
		fill_vending()
		prompt_msg_fn=function()
			print("stage "..stage_name..
			" complete!\n"..
"❎ to check loot and continue\n"..
"🅾️ to return to map")
			palt(0,false)
			spr(192,96,32,2,2)
			spr(224,96,32+16,2,2)
			palt(0,true)
			end
		goto_prompt(next_stage,
			stage_exit)
		current_mode=prompt_mode
		human_reset=false
	end
end

function is_stage_empty()
	if #enemies==0 then
		return true
	end
	for e in all(enemies) do
		if e.spec!=e_spec_wall then
			return false
		end
	end
	return true
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
		stage=stage_name
		total_time=end_time-begin_time
		print("last stage: "..
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
		palt(0,false)
		spr(192,96,8,2,2)
		spr(224,96,8+16,2,2)
		palt(0,true)
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
		sfx(4)
		inv_line+=1
		if inv_line>#lines then
			inv_line=1
		end
	end
		--up
	if btn(2) and not inv_pressed
		then
		inv_pressed=true
		sfx(4)
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
		sfx(8)
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
	if (not 
			contains(sb_pocket,a)) and
			#sb_pocket<9
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
		sfx(6)
		drop_item(a)
		range=chip_range[a.rarity]
		limit=range[2]-range[1]+1
		reward=flr(rnd(limit))
		reward+=range[1]
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
		sfx(6)
		x_gun.spec=g
	elseif stype==item_type.z_gun then
		sfx(6)
		z_gun.spec=g
	elseif stype==item_type.boost then
		sfx(6)
		sb_boost.spec=g
	elseif stype==item_type.module then
		if not contains(modules,g) then
			sfx(7)
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
		sfx(6)
		z_gun.spec=nil
	elseif stype==item_type.boost then
		sfx(6)
		sb_boost.spec=nil
	elseif stype==item_type.module then
		if contains(modules,g) then
			sfx(7)
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
	--draw z meter
	--if z_gun.spec != nil then
		draw_gun_hud(20,z_gun)
	--end
	--draw x meter
	draw_gun_hud(0,x_gun)
	--draw g meter
	spr(12,83,0)
	health_meter(91,1,sb_health)
	
	print("x"..extra_lives,105,2,7)
	draw_boost_hud()
	
	
	--currency
	rectfill(60,1,60+20,6,0)
	spr(54,60,1)
	print(""..sb_currency,69,2,7)
	
	--stage name
	rectfill(115,1,126,6,0)
	print(stage_name, 116,2,7)
end

function draw_gun_hud(offset,gun)
	--pal(7, health_col[gun.dur])
	palt(0, false)
	lbl=nil
	if gun.spec==nil then
		spr(31,offset,0)
		palt(0, true)
		return
	else
		lbl=gun.spec.lbl
	end
	spr(lbl,offset,0)
	heat_meter(offset+6,1,
		flr(gun.heat),
			flr(gun.max_heat))
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
				if (acnt%4==0 or acnt%2==0)
					 and heat >= 100 then
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

--number of frames the player
--has been in collision
frames_in_col=0
prev_col_enemies={}

function player_control()
	x=sb_x
	y=sb_y
	xv=0
	yv=0
	if btn(0) then
		xv-=sb_speed
	end
	if btn(1) then
		xv+=sb_speed
	end
	if btn(2) then
		yv-=sb_speed
	end
	if btn(3) then
		yv+=sb_speed
	end
	if abs(xv)>0 and abs(yv)>0 then
		xv*=0.707
		yv*=0.707
	end
	sb_x+=xv
	sb_y+=yv
	if sb_y != y or 
			 sb_x != x then
			 sb_moved=true
	else
			sb_moved=false
	end
	clear_col=true
	if current_mode==stage_mode
			and sb_inv_count<=0
	 then
		for e in all(enemies) do
		--to make collisions less
		--terrible, use 10px large
		--spiderbot
			if check_col(
					sb_x,sb_y,10,10,e.x,e.y,8,8)
				then
				clear_col=false
				if not 
						contains(prev_col_enemies,e)
					then
					add(prev_col_enemies,e)
				end
				frames_in_col+=1
				--revert to previous coord
				sb_x=x
				sb_y=y
				if frames_in_col>1 then
					if last_edge_right then
						sb_x-=2
					end
					if last_edge_left then
						sb_x+=2
					end
					if last_edge_top then
						sb_y+=2
					end
					if last_edge_bottom then
						sb_y-=2
					end
				end
			else
			end
		end
	end
	if clear_col then
		prev_col_enemies={}
		frames_in_col=0
	end
		--keep from going out of bound
	if sb_y<4 or
				sb_y>124 then
		sb_y=y
	end
	if sb_x<4 or
				sb_x>124 then
		sb_x=x
	end

end


function gun_control()
	x=sb_x
	y=sb_y
	sb_charging=false
	spec=x_gun.spec
	--do heat
	printh("sb_heat: "..sb_heat)
	if sb_heated then
		sb_charging=false
		return
	end

	if btn(5) and not btn(4) then
		--do rate of fire
		if fire_rate(x_gun) then
			--shoot bullet now
			for i=1,x_gun.spec.shots do
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
				sb_heat=min(sb_heat,sb_max_heat)
			end
		else
			--in between bullets
		end
		if fire_rate(y_gun) then
			--shoot bullet now
			shoot_y_gun=true
			for i=1,y_gun.spec.shots do
				y_gun.spec.shoot()
			end
			shoot_y_gun=false
		end
		
	end --end if btn(x)
	if (btn(4) and not btn(5))
			and z_gun.spec!=nil then
	
		z_gun.heat+=
				(z_gun.spec.heat_rate*
				z_gun.heat_mul)*
			 sb_gun_heat_mul
		
		if z_gun.heat>=100
	 then
			sb_heat+=sb_gun_overheat
			sb_heat=min(sb_heat,sb_max_heat)
		end
		if z_gun.c >= sb_max_charge
	 then
	 	sfx(10,2)
			z_gun.c=sb_max_charge
		else
			sfx(9,2)
			z_gun.c+=z_gun.spec.charge_rate
		end
		sb_charging=true
		
	end
	--released buttons
	if btn()==0 then
		if z_gun.c>=sb_max_charge
		then
			z_gun.c=0
			z_gun.spec.shoot()
			sfx(11,2)
		else
			z_gun.c=0
		end
		sb_charging=false
		
	end
	x_gun.heat=min(x_gun.max_heat,
			x_gun.heat)
	x_gun.r=max(x_gun.r,0)
	--z_gun.r=max(z_gun.r,0)
	if sb_inv_count>0 then
		sb_inv_count-=1
	end
end

function boost_control()
--🅾️ is 4
--❎ is 5
	if sb_heated then
		sb_charging=false
		return
	end
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
				sb_heat=min(sb_heat,sb_max_heat)
				end
			else
				sb_boost_charges=0
			end
	end
end


--this implements rate of fire
function fire_rate(g)
	if g.spec==nil then
		return false
	end
	if g.r>=g.spec.rate then
		g.r=0
	else
		g.r+=sb_rate_mod
	end
	return g.r==0
end
		
--deletes all enemy bullets
function blink_boost(b)
	b.frame_count=3
	sfx(2,-1,0,16)
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
		if sb_charging then
			if z_gun.c>=sb_max_charge then
				anim=sb_charged_anim
			else
				anim=sb_charging_anim
			end
			i=(acnt%#anim)+1
			spr(anim[i], sb_x-4,sb_y-12)
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
		if b.sprite!= nil and
				b.sprite<0 then
			if b.size==1 then
				pset(b.x,b.y,abs(b.sprite))
			else
				rectfill(
					b.x,
					b.y,
					b.x+b.size,
					b.y+b.size,
					abs(b.sprite))
			end
		else --sprite>=0
			if b.beam==true then
				s=b.anim[acnt%#b.anim]
				for y=2,(128/8) do
					t=acnt%#b.anim
					t+=1
					spr(b.anim[t],
						b.x-4,b.y-(y*8),1,1)
				end
				--draw connection to sb
				t=acnt%#b.sprites
				t+=1
				spr(b.sprites[t],
					b.x-4,b.y-8,1,1)
			else
				--convert to float
				sz=flr(b.size*8)
		 	spr(b.sprite,
		 		b.x,b.y,sz,sz)
			end
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
			 if b.exploding!=nil and
			 	not b.exploding 
			  then
			  b.exploding=true
			  --recursive call for splash
			  --damage
			  printh("recursive")
			  check_bullet(b)
			  --draw splash explosions
			 	for x=0-b.splash,b.splash do
			 		for y=-1-b.splash,b.splash do
			 			explode_hit(
								b.x+(x*8),
		 					b.y+(y*8))
		 			end
		 		end
			 	--exit, the missle exploded
			  return
			 end
			 if b.exploding!=nil and
			 		b.exploding 
			 	then
			 	printh("splashing")
			 	apply_splash_dmg(e,b)
			 	del(bullets,b)
			 	sfx(0,-1,0,12)
			 end
			 if b.exploding==nil then
			 	apply_blt_dmg(e,b)
			 	if b.beam then
			 		explode_hit(e.x+4,e.y+4)
			 	else
			 		explode_hit(b.x,b.y)
			 		del(bullets,b)
			 		sfx(0,-1,0,12)
			 	end
			 end
			end
		end
	else
		if b.collision_fn(b,
			sb_x-4, sb_y-4)
		then
			sfx(3,-1,0,16)
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
function apply_blt_dmg(e,b)
	e.health-=b.dmg
	total_damage+=b.dmg
end
function apply_splash_dmg(e,b)
	e.health-=b.splash_dmg
	total_damage+=b.splash_dmg
end

function clean_bullets()
	for b in all(bullets) do
		if b.x<0 or b.y<0 or
					b.x>128 or b.y>128 then
			del(bullets,b)
		elseif b.beam then
			if b.frames<=0 then
				del(bullets,b)
			end
		elseif b.exploded!=nil and
		 	b.exploded
		 then
		 del(bullets,b)
			end
	end
end

function shoot_missle()
	printh("shoot_missle")
	x1=sb_x
	--undo draw centering
	y=sb_y-4
	dmg=get_shot_dmg(z_gun)
	blt=blt_straight(x1,y,dmg)
	blt.size=3
	blt.splash=z_gun.spec.splash
	blt.splash_dmg=
			z_gun.spec.splash_dmg
	blt.speed=2.0
	blt.collision_fn=col_explode
	blt.exploding=false
	if x_is_heated() then
		--make red
		blt.sprite=-8
	end
	add(bullets,blt)
	return blt
end


function shoot_chain()
	x1=sb_x
	--undo draw centering
	y=sb_y-4
	if shoot_y_gun then
		--shoot backwards gun
		y=sb_y+4
		dmg=get_shot_dmg(y_gun)
		blt=blt_straight(x1,y,dmg)
		blt.yend=130
		blt.speed=1.5
	else
		dmg=get_shot_dmg(x_gun)
		blt=blt_straight(x1,y,dmg)
		blt.speed=2.0
		if x_is_heated() then
			--make red
			blt.sprite=-8
		end
	end
	add(bullets,blt)
	return blt
end

function shoot_sine()
	x1=sb_x
	--undo draw centering
	y=sb_y-4
	dmg=get_shot_dmg(x_gun)
	blt=blt_curved(x1,y,dmg)
	blt.speed=2
	if x_is_heated() then
		--make red
		blt.sprite=-8
	end
	add(bullets,blt)
	sfx(1,0,0,6)
	return blt
end


function shoot_big_chain()
	b=shoot_chain()
	b.size=2
	b.speed=1.2
	return b
end


function get_shot_dmg(x)
	dmg=x.spec.dmg
	if x.heat>=100 then
		dmg*=x.heated_dmg_mul
	end
	dmg*=sb_dmg_mul
	dmg=flr(dmg)
	return dmg
end

shoot_alternate=false
function shoot_shotgun()
	spread=20
	x1=sb_x
	--undo draw centering
	y=sb_y-4
	dmg=x_gun.spec.dmg
	blt=blt_line(x1,y,dmg)
	blt.speed=2.0
	if x_is_heated() then
		--make red
		blt.sprite=-8
	end
	blt.yend=0
	if shoot_alternate then
		shoot_alternate=false
		blt.xend+=flr(rnd(spread))
	else
		shoot_alternate=true
		blt.xend-=flr(rnd(spread))
	end
	add(bullets,blt)
	sfx(1,0,0,6)
	return b
end

function blt_straight(x,y,dmg)
	blt={
		beam=false,
		x=x,
		y=y,
		size=1,
		xend=x,
		yend=0,
		dmg=dmg,
		steps=1,
		--note be careful, speed
		--shouldn't be too fast
		speed=1.0,
		friendly=true,
		sprite=-7,
		splash=0,
		step_fn=step_straight,
		collision_fn=col_pixel
	}
	return blt
end

function blt_curved(x,y,dmg)
	blt=blt_straight(x,y,dmg)
	blt.step_fn=step_sine
	return blt
end

function blt_beam(x,y,dmg)
	blt={
		beam=true,
		anim={3,3,4,4},
		x=x,
		y=y,
		xend=x,
		yend=0,
		size=2, --is width
		dmg=dmg,
		steps=1,
		speed=1.0,
		friendly=true,
		sprites={5,5,6,6},
		step_fn=step_beam,
		collision_fn=col_beam,
		frames=10
	}
	return blt
end

function step_beam(b)
	b.frames-=1
end
function col_beam(b,x2,y2,
			w,h)
--b = bullet
--x2,y2 = target sprite to check
--w,h = size of target sprite
	--defaults to 8x8
	w=w or 8
	h=h or 8
	if not check_col(b.x,0,
			b.size,sb_y,x2,y2,w,h)
	 then
		return false
	end
	return true
end



function blt_big_straight(x,y,dmg)
	blt=blt_straight(x,y,dmg)
	blt.size=2
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

function col_pixel(b,x2,y2,
			w,h)
--x1,y1 = pixel bullet
--x2,y2 = target sprite to check
--w,h = size of target sprite
	--defaults to 8x8
	last_col_splash=false
	w=w or 8
	h=h or 8
	if not check_col(b.x,b.y,
			b.size,b.size,x2,y2,w,h)
	 then
		return false
	end
	return true
end

last_col_splash=false
function col_explode(b,x2,y2,
			w,h)
--x1,y1 = pixel bullet
--x2,y2 = target sprite to check
--w,h = size of target sprite
	--defaults to 8x8
	w=w or 8
	h=h or 8
	last_col_splash=false
	if b.exploding then
		c=check_col(
			b.x-(b.splash*8/2),
			b.y-(b.splash*8/2),
			b.splash*8,b.splash*8,
			x2,y2,w,h)
			last_col_splash=c
		return c
	end
	return check_col(b.x,b.y,
			b.size,b.size,
			x2,y2,w,h)
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
	return b	
end

--follows a fixed line 
--toward end position
function step_sine(b)
	if b.xstart==nil then
		b.xstart=b.x
	end
	if b.ystart==nil then
		b.ystart=b.y
	end
	if b.sine_count==nil then
		b.sine_count=5
	end
	if b.tmp==nil then
		b.tmp=false
	end
	xd=b.xstart-b.xend
	yd=b.ystart-b.yend
	
	ang=atan2(xd,yd)
	if b.sine_count<=-5 then
		b.sine_count+=1
		ang+=0.1
		b.tmp=true
	elseif b.sine_count>=5 then
		b.sine_count-=1
		ang-=0.2
		b.tmp=false
	else
		if b.tmp then
			ang+=0.1
			b.sine_count+=1
		else
			ang-=0.1
			b.sine_count-=1
		end
	end
	b.x-=b.speed*cos(ang)
	b.y-=b.speed*sin(ang)	
	return b	
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

function shoot_beam()
	x1=sb_x
	--undo draw centering
	y=sb_y-4
	dmg=get_shot_dmg(z_gun)
	blt=blt_beam(x1,y,dmg)
	add(bullets,blt)
	return blt
end

-->8
--enemies

--enemy that stays still and 
--shoots toward the location
--of the player sprite
e_spec_spitter=nil
e_spec_flier=nil
e_spec_wall=nil
e_spec_curver=nil
--enemy map to sprite colors
--for stage gen purposes
--there can be up to 12 colors
--(bottom 4 reserved)
e_map={}

function init_enemies()
	--for i=1,i=16 d
	--	add(e_map,nil)
	--end
	e_spec_spitter={
		anim={16,16,17,17},
		speed=0,
		blt_speed=1.5,
		gun=chain_gun,
		trace=trace_still,
		update=enemy_update,
		health=20,
		rate=60,
		dmg=30,
		reward=2
	}
	e_map[4]=spawn_spitter
	
	e_spec_curver={
		anim={18,18,19,19},
		speed=0,
		blt_speed=1.2,
		gun=sine_gun,
		trace=trace_still,
		update=enemy_update,
		health=20,
		rate=40,
		dmg=30,
		reward=4
	}
	e_map[14]=spawn_curver
	
	e_spec_flier={
		anim={55,56,57,58},
		speed=0.5,
		blt_speed=1.5,
		gun=chain_gun,
		trace=trace_slide,
		update=enemy_update,
		health=30,
		rate=40,
		dmg=30,
		reward=2
	}
	e_map[10]=spawn_flier
	e_spec_wall={
		anim={59},
		speed=0,
		blt_speed=0,
		gun=chain_gun,
		trace=trace_still,
		update=trace_still,
		health=30,
		rate=40,
		dmg=30,
		reward=1
	}
	e_map[7]=spawn_wall
end

function calc_reward(e)
	r=e.spec.reward
	r*=sb_reward_mul
	return r
end

function clean_enemies()
	for e in all(enemies) do
		if e.health<=0 then
			sb_currency+=calc_reward(e)
			del(enemies,e)
			add_big_explosion(
				e.spec.anim[1],
				e.x-4,e.y-4)
		end
		if (e.x>128 or e.x<0) or
			(e.y>134 or e.y<0) then
			printh("deleted out of bounds enemy")
			del(enemies, e)
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
		health=e_spec_flier.health,
		spec=e_spec_flier,
		flip_x=true,
		flip_y=false,
		moved=false
	}
	add(enemies,e)
	return e
end

function spawn_curver(x,y)
	e={
		x=x,
		y=y,
		rate_mul=1.0,
		dmg_mul=1.5,
		health=e_spec_curver.health,
		spec=e_spec_curver,
		flip_x=true,
		flip_y=false
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
					e.x,e.y,10,10,
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

--default function, usually
--does enough
function enemy_update(e)
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

function scroll_map_enemies()
	for e in all(enemies) do
		e.y+=1
	end
	if map_window_y%8==0 and
			map_window_y>0 then
		for x=1,14 do
			c=sget(x,96+(map_window_y/8))
			
			spawn=e_map[c]
			if spawn!=nil then
				spawn(x*8,4)
			end
		end
	end
end
--populates initial enemies
--before scrolling
function spawn_stage()
	map_window_y=map_height
	for i=0,80 do
		map_window_y-=1
		scroll_map_enemies()
	end
	--for x=1,14 do
	--	for y=1,map_height/8-1 do
	--	end
	--end
end
-->8
--stages and maps

--the lab contains random stages


in_stage=false
loot_pool={}

function init_loot_pool()
	add_loot(simple_chain_gun,
			0.4)
	add_loot(double_chain_gun,
			0.2)
	add_loot(blink_spec,
			0.1)
	add_loot(dev_mode_mod,
			0.1)
	add_loot(radiator_mod,
			0.2)
	add_loot(harness_mod,
			0.2)
	add_loot(texas_chain_gun,
			0.1)
	add_loot(beam_laser,
			0.2)
	add_loot(shotty_gun,
			0.1)
	add_loot(sine_gun,
			0.1)
	add_loot(missle_laser,
		0.1)
end

--bias = vending rarity
--will try to tilt the odds
--to this rarity level
function pick_loot(bias)
	pool=loot_pool
	p={}
	while #p==0 do
		p=pick_rnd_loots(bias,pool)
	end
	while #p!=1 do
		tmp=pick_rnd_loots(bias,p)
		if #tmp!=0 then
			p=tmp
		end
	end
	return p[1]
end

function pick_rnd_loots(bias,
		pool)
	bias_mul=1.5
	np={}	
	for l in all(pool) do
		r=l.r
		if l.i.rarity==bias then
			r*=r
		end
		if r<rnd() then
			add(np,l)
		end
	end
	return np
end

function add_loot(item,rate)
	l={
		i=item,
		r=rate
	}
	add(loot_pool,l)
end
			


stage_name=nil
function init_lab()
end

function lab_gen1()
	
	pool={
		4,4, --spitters
		10, --fliers
		7,7,7, --walls
		14
	}
	o={
		rate=0.02*lab_depth,
		min=20,
		max=50
	}
	gen_stage(o,pool)
end

lab_depth=1
in_lab=false
function enter_lab()
	stage_name="l-"..lab_depth
	in_lab=true
	in_stage=true
	reset_sb()
	current_mode=stage_mode
	reset_sb()
	lab_gen1()
	spawn_stage()
end



--rate=rnd % for enemy spawn
--pool=pool of enemies
--en_mod=enemy mod function
function gen_stage(opt,
		pool)
	--we make a grid of an odd
	--number so that there is more
	--room for collision detect
	--errors
	while true do
		enemies={}
		stage_enemies={}
		for x=1,14 do
			for y=1,(256/8)-2 do
				sset(x,y+96,0)
				if opt.rate>rnd() then
					printh("make enemy")
					--spawn enemy
					i=flr(rnd(#pool))
					i+=1 --1-based offsetting
					c=pool[i]
					sset(x,y+96,c)
				end
			end
		end
		--check min and max
	 --c=e_count_no_walls()
	 --printh(c)
	 --todo: until get a gauge of
	 --enemy counts is fun..
	 return
	 --if c<=opt.max and 
	 --		c>=opt.min then
	 --	return
	 --end
	end
end
function e_count_no_walls()
	c=0
	for e in all(enemies) do
		if e.spec!=e_spec_wall then
			c+=1
		end
	end
	return c
end	

function gen_rnd_walls()
	
end

locations={}
mechanic_loc=nil
lab_loc=nil
vending_loc=nil

function init_locations()
	mechanic_loc={
		launches=enter_mechanic,
		cancel=back_to_map,
		msg_fn=function()
			print("enter shop? (❎ for yes)")
		end
	}
	lab_loc={
		launches=enter_lab,
		cancel=back_to_map,
		msg_fn=function()
		print("enter lab at depth "..
			lab_depth.."?\n"..
			"(❎ for yes)")
		end
	}
	vending_loc={
		launches=enter_vending,
		cancel=back_to_map,
		msg_fn=function()
		print("check latest vending machine?\n"..
			"(❎ for yes)")
		end
	}
	help_loc={
		launches=enter_help,
		cancel=back_to_map,
		msg_fn=function()
		print("check the ancient dead texts?\n"..
			"(❎ for yes)")
		end
	}
	
end

function enter_help()
	prompt_msg=
"the lab is randomly generated.\n"..
"every new level defeated fills\n"..
"the vending machine with new\n"..
"loot. make sure to check it.\n"..
"visit the mechanic for expensive\n"..
"yet always useful upgrades.\n"..
"keep in mind spiderbot is only\n"..
"capable of holding 9 items.\n"..
"dismantle the useless ones.\n"..
"the prefix (in parens) indicates\n"..
"what it is activated by.\n"..
"x=❎gun, z=🅾️gun, b=🅾️❎boost,\n"..
"m=module. equip multiple (m) \n"..
"modules!" 
	prompt_msg_fn=function()
		print(prompt_msg)
	end
	goto_prompt(back_to_map,
			back_to_map)
end



function add_map_loc(x,y,loc)
	add(locations,{
		x=x,
		y=y,
		loc=loc
	})
end

function build_map()
	add_map_loc(7*8,2*8,
		mechanic_loc)
	add_map_loc(12*8,2*8,
		lab_loc)
	add_map_loc(1*8,2*8,
		vending_loc)
	add_map_loc(1*8,9*8,
		help_loc)
end

--last edge colliding on 
--1st set of coordinates
last_edge_top=nil
last_edge_bottom=nil
last_edge_right=nil
last_edge_left=nil
function check_col(x1,y1,w1,h1,
										x2,y2,w2,h2)
	x_col=false
	last_edge_right=
		x1<x2+w2 and x1>x2
	if last_edge_right then
		x_col=true
	end
	last_edge_left=
		x1+w1>x2 and x1<=x2+w2
	if last_edge_left then
		x_col=true
	end
	y_col=false
	last_edge_top=
		y1<=y2+h2 and y1>y2
	if last_edge_top then
		y_col=true
	end
	last_edge_bottom=
		y1+h1>=y2 and y1<y2+h2
	if last_edge_bottom then
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
			prompt_msg_fn=l.loc.msg_fn
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
	in_prompt=false
	lab_depth+=1
	human_reset=false
	in_stage=true
	enter_vending()
end
function stage_exit()
	in_stage=false
	in_lab=false
	lab_depth+=1
	back_to_map()
	
end
function stage_cancel()
	back_to_map()
end

function init_shops()
	mechanic_pocket={
		radiator_mod,
		simple_chain_gun,
		texas_chain_gun,
		harness_mod
	}
	
end

function enter_vending()
	reset_sb()
	human_reset=false
	shop_msg=
"now with 50% more randomness"
	shop_pocket=vending_pocket
	in_prompt=false
	shop_cost_mul=0.2
	shop_line=1
	current_mode=shop_mode
end



function fill_vending()
	vending_pocket={}
	if lab_depth==1 then
		l=pick_loot(1)
		add(vending_pocket,l.i)
	elseif lab_depth<=5 then
		l1=pick_loot(1)
		l2=pick_loot(2)
		add(vending_pocket,l1.i)
		add(vending_pocket,l2.i)
	else
		l1=pick_loot(1)
		l2=pick_loot(2)
		l3=pick_loot(3)
		l4=pick_loot(3)
		add(vending_pocket,l1.i)
		add(vending_pocket,l2.i)
		add(vending_pocket,l3.i)
		add(vending_pocket,l4.i)
	end
end

function enter_mechanic()
	reset_sb()
	human_reset=false
	shop_msg=
"the mechanic bot watches you"
	shop_pocket=mechanic_pocket
	in_prompt=false
	shop_cost_mul=1.0
	shop_line=1
	current_mode=shop_mode
end

mechanic_pocket={}
vending_pocket={}
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
		assert(g != nil)
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
	printh(shop_line)
	item=lines[shop_line].i
	print(item.desc,2,105,7)
	shop_navigate(lines)
	in_shop=false
end

function shop_cost(base)
		cost=base*shop_cost_mul
		return flr(cost)
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
		sfx(4)
	end
		--up
	if btn(2) and not shop_pressed
		then
		shop_pressed=true
		shop_line-=1
		if shop_line<1 then
			shop_line=#lines
		end
		sfx(4)
	end
	--buy
	if btn(5) and not shop_pressed
		then
		shop_pressed=true
		cost=shop_cost(item.base_cost)
		if sb_currency>=cost and
				not contains(sb_pocket,item)
			then
			sb_currency-=cost
			equip(item)
		else
			sfx(5)
		end		
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
		sfx(8)
		shop_pressed=true
		if in_stage then
			enter_lab()
		else
			current_mode=map_mode
		end
			in_prompt=false
		shop_pocket={}
	end
	if btn()==0 then
		shop_pressed=false
	end
end



function print_shop_item(g,x,y,cost,c)
		print("["..cost.."]  ",x,y+2,10)
		print(g.name,x+24,y+2,c)
		spr(g.lbl, x-10,y)
		y+=8
end


__gfx__
000000005555555555555555001c11000011c100001c11000011c100000009000090000090077009555555555555555555555555006666000066660000555500
0000000050000005566000050011c100001c11000011c100001c1100000005000050000080077008500000055606606550000005006006000696696005755750
000000005060c60556666605001c11000011c100001c11000011c100000066600666000050066005500005055067760550666605666006666511115657a66a75
00000000506c0605565666050011c100001c11000011c100001c11000000616776160000576d1675506666055670076550688605600000066518815655690655
000000005060c60550005605001c11000011c100001c11000011c10000006167761600005761d675506500055670076550f33f05600000066518815655609655
0000000050666605506066050011c100001c11000011c100001c110000006660066600005006600550600005506776055ffffff5666006666511115657a66a75
000000005006600550606605001c11000011c100111cc11111cccc1100000000000000008007700850000005560660655f0000f5006006000696696005766750
0000000055555555555555550011c100001c11001c1cc1c11cccccc1000000000000000090077009555555555555555555555555006666000066660000566500
00555500005555000000000000000000000660000006600000066000000660000000000000000000000000000000000000000000000000000000000055555555
05655650055555500000000000000000006666000066660000666600006666000000000000000000000900000000000000000000000000000000000050000005
56666665556666550006660000f666f006c88c6006c88c6006c88c6006c88c600000000000900000009000000000000000000000000000000000000050000005
5560965555690655066333600663336006c33c6006c33c6006c33c6006c33c600009000000090000900909000000000000000000000000000000000050000005
5560965555690655633093366339033606cccc6006cccc6006cccc6006cccc600000000009000090090000900000000000000000000000000000000050000005
566666655566665563309336633903360ffffff00ffffffffffffffffffffff0009009000090090000900900000000000000000000000000000aa00050000005
05666650055665500663336006633360ff0000ffff00000ff000000ff00000ff000000000000000000000000000000000009900000a99a0000a99a0050000005
00566500005665000006660000f666f0f000000ff0000000000000000000000f0000000000000000000000000000000000099000000990000009900055555555
00099000000990000009900000099000000000000000000000055000000880000005000000550005000000000000000000000000000000005555555555555555
0099990000999900009999000099990000000000000550000058850000899800050550505050555000000000000000000008800000055000500cc005500cc005
09a88a9009a88a9009a88a9009a88a90000000000058850005899850089aa98000588500050550500005500000099000008998000055550050c11c0550c00c05
09a33a9009a33a9009a33a9009a33a900008800005899850589aa98589a77a98058aa8500058850500599500009aa900089aa980055aa5505c1711c55c6006c5
09aaaa9009aaaa9009aaaa9009aaaa900008800005899850589aa98589a77a98058aa8500058850000599500009aa900089aa980055aa5505c1111c550800805
0ffffff00ffffffffffffffffffffff0000000000058850005899850089aa98000588500000550000005500000099000008998000055550050c11c0550800805
ff0000ffff00000ff000000ff00000ff00000000000550000058850000899800000550000000000000000000000000000008800000055000500cc00550888805
f000000ff0000000000000000000000f000000000000000000055000000880000000000000000000000000000000000000000000000000005555555555555555
5555555500000000555555555555555555555555555555550000000000006660000066600000666000006660666666665555555555555555001cc10055555555
5006600500000000500bb0055009900550022005500050050555550000065560000655690006556800065560655555565000050550000005001cc10050000005
5667766570000000500bb0055009900550022005506660050555550000655560006555690065556800655568650000565666660550000055001cc10050065005
56788765770000005bbbbbb55999999552222225506500050555550006559960065599600655996006559960650000565666660556666665001cc10056666665
56708765777000005bbbbbb55999999552222225500050050a0a0a0006559960065599600655996006559960650000565445000554450445001cc10056400605
5667766577000000500bb0055009900550022005506660050a0a0a0000655560006555690065556800655568650000565445000554000005001cc10056400005
5006600570000000500bb005500990055002200550650005000000000006556000065569000655680006556065555556544000055400000511cccc1156400005
55555555000000005555555555555555555555555555555500000000000066600000666000006660000066606666666655555555555555551cccccc155555555
55585055050505555777777777777775033333333333333055555555555555555555555555555555555555555555550555555555555555550000000000000000
5650a55898955565577cccccc666666503ccccccccc3333077777777777777775555556555555555556555555555555555555500005555550000000000000000
5659500550a58065577cccccc6555555039cc8ccaac3333077777777777777775555666655555555555545554555605555555006660555550000000000000000
56059a8a9505a5655777777776666655039cc88caac3333077000066611611775555666655555555555555555555555555550066660055550000000000000000
5660a50005050a65577cc77cc6565655035555555553333077000006111161775556664666555555554550545455555555500660066005550000000000000000
5666666666666665577cc77cc656567503ccccccccc3333077000066661116775556044446665555555555555055455555006660000600550000000000000000
566655aaa5576665577cc77cc766667503c8ccccccc3663077000060616111775566444404466655555054555555505555066666600660550000000000000000
5666555a55576665577777777656567503c8c9ceecc3663077000066611611775660444444406655555555555055565555066666660060550000000000000000
5667a55a55a776655777777776565675033333333333663077000006111161775661446111446655554555555455555555066666660060550000000000000000
5667aaaaaaa77665577cc77cc7756775037337337333333077000066611116775611666610611665555555555555445555066666600660550000000000000000
5667a55555a77665577cc77cc776577507373373373333307706c060661111776414466666661465555555554555555055066660000660550000000000000000
5677777777777765577cc77cc775677507337373733333307706606661611177651466aaaa661465555505555555555555066660066660550000000000000000
567777666677776557777666667777750333333333333330770060061116117761146aa6a6a66446555550556555545555066666666660550000000000000000
6677776bb677776657777655567777750333555555553330770060666111617766466aa666a66646564555055545555555066666666660550000000000000000
6777776bb67777765777765556777775060000000000006077446460611116776666aaaa6aaa6666550554555555545555066660066660550000000000000000
6777776bb6777776577776555677777506000000000000607744646661111177666aaaaa6aaaa666555555555555555555066660066660550000000000000000
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
00000000000000000000000000000000000000000000000000000000555555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000500000050000000000000000000000000000000000000000000000000000000000000000
00000c00000000000000000000000000000000000000000000000000506666050000000000000000000000000000000000000000000000000000000000000000
0c0c0c0000000c00000c00000000000000c0c0000000000000000000506888050000000000000000000000000000000000000000000000000000000000000000
000000c000cc00000c00c000000ccc000000c0c0000cc00000000000566666050000000000000000000000000000000000000000000000000000000000000000
00c0c000000000c000c000c00cc00c000c0c0000000cc000000cc000564500050000000000000000000000000000000000000000000000000000000000000000
0c000c000c000c000c00c0000000c0000000c00000cccc00000cc000564000050000000000000000000000000000000000000000000000000000000000000000
000c000000c00c00000c00000cc0c0c000c000c000cccc00000cc000555555550000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
4a4b4a4b4a4b4a4b4a4b4a4a4a4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b4a4b4a4b4a4b4b5a5b4a4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5b44454b5b5a5b46475b5a5b42435a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a54555b4a4a4b56574a4a4b52534b4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5a5b5a5b5a5a5b5a5b5a5a5b5a5a5b5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4b4a4b4a4b4a4b4a4b4a4b4a4b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b4a4b5b4a4b5a5b5a4a4b5b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5b5a5b5a4a4b5a5b4a4b4a5a5b4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b4a5a5b4a4b4a4b4a4b4a4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5b4c4d5a5b4b5a5b5a5b5a5b5a5b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b5c5d5b5a5b4a4b4a4b4a4a4b4b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5b5a5b4b4a4b5a5b5a5b4a5a5b4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b5b5a5b4a4b4a4b5a5b5a5b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5b5a5b4b4a4b4a4b4a4b4a4b4a4b4a4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4a4b5b5a5b5a5b5a5b5a5b5a5b5a5b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000e6500e6500e65038670396703a6703b6703c650146500f6500f6500f6300d62011600116000f6000e600006000060000600006000060000600006000060000600006000060000600006000060000600
000200001365013650064702f670194501547011460104000f400246003860037600366003c600316003a600236001a6000d60010600126001360013600136001360021600216002060020600206002060020600
000100001c7501c7501c7501c7501c7501c7501c7501c7501c7501c750243502f35030350313503b3503b3503b350303502375022750227502275021750217502175021750217502175021750217502075020750
000100000c6500c6500c6500c6500b6500b6500a6500a6500a650096500d650136503a3703b4703a4703a4703a3703a35014650176702367021650206501e6501c6501a6501765013650116500f6500d6500d650
000200001e3501e3501e3501e3001e30000300043001a300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001f4501f4501f4501f4501f4500b4500b4500b4500b4500b4500b4500b4500b4500b4500c4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000031650316502f6502d650246501c65014650106500d6501560015600156001560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000a3500a3500a3500a3500a3501a3501a3501a3501a3501a35014350143501435014350143501435014350000000000000000000000000000000000000000000000000000000000000000000000000000
000300001c650176501065000600166000460014650186501b6501c6001c6001c6001c6001d600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000608010707007070070700705007050070500705007070080000a0000a0000a00009000080000900009000090000a0000900000000000000000000000000000000000000000000000000000000000000000000
00010f0015050170501a0501e05022050250502705028050260502505023050200501c05019050160501600015000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000e7500e7500e7500e7500e7500e7500e7500e7502375023750237502375023750237502375023750237500a7500975006750037500275000000000000000000000000000000000000000000000000000
