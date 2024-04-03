--- STEAMODDED HEADER
--- MOD_NAME: Roulette
--- MOD_ID: Roulette
--- MOD_AUTHOR: [Hellyom]
--- MOD_DESCRIPTION: Adds a roulette so you can loose all your money

----------------------------------------------
------------MOD CODE -------------------------

function randomFloat(lower, greater)
  return lower + math.random()  * (greater - lower);
end


G.BET_SIZE = 0
G.BET_COLOUR = "RED"
G.START_ROUL_SPIN = false
G.ROUL_SPIN = false
G.ROUL_VEL = randomFloat(6, 14) 
G.WHEEL = {"GREEN", "RED", "BLACK", "RED", "BLACK", "RED", "BLACK", "RED", "BLACK", "RED", "BLACK", "RED"}
G.PAYOUTS = {GREEN = 11, BLACK = 2, RED = 1.8}
--rads per section of the wheel
G.RADS_PER_SC = 6.283185 / #G.WHEEL

--Previous radian used for roulette sound
PREV_RADS = 0


function SMODS.INIT.Roulette()
  sendDebugMessage("Loading Roulette mod assets")

  SMODS.Sprite:new("roulette", SMODS.findModByID("Roulette").path, "roulette.png", 199, 199, "asset_atli"):register()
  SMODS.Sprite:new("roul_marker", SMODS.findModByID("Roulette").path, "roul_marker.png", 19, 7, "asset_atli"):register()
end

--OVERWRITTEN FUNCTIONS

G.UIDEF.shopRef = G.UIDEF.shop
function G.UIDEF.shop()
  G.shop_jokers = CardArea(
    G.hand.T.x+0,
    G.hand.T.y+G.ROOM.T.y + 9,
    G.GAME.shop.joker_max*1.02*G.CARD_W,
    1.05*G.CARD_H, 
    {card_limit = G.GAME.shop.joker_max, type = 'shop', highlight_limit = 1})


  G.shop_vouchers = CardArea(
    G.hand.T.x+0,
    G.hand.T.y+G.ROOM.T.y + 9,
    2.1*G.CARD_W,
    1.05*G.CARD_H, 
    {card_limit = 1, type = 'shop', highlight_limit = 1})

  G.shop_booster = CardArea(
    G.hand.T.x+0,
    G.hand.T.y+G.ROOM.T.y + 9,
    2.4*G.CARD_W,
    1.15*G.CARD_H, 
    {card_limit = 2, type = 'shop', highlight_limit = 1, card_w = 1.27*G.CARD_W})

  local shop_sign = AnimatedSprite(0,0, 4.4, 2.2, G.ANIMATION_ATLAS['shop_sign'])
  shop_sign:define_draw_steps({
    {shader = 'dissolve', shadow_height = 0.05},
    {shader = 'dissolve'}
  })
  G.SHOP_SIGN = UIBox{
    definition = 
      {n=G.UIT.ROOT, config = {colour = G.C.DYN_UI.MAIN, emboss = 0.05, align = 'cm', r = 0.1, padding = 0.1}, nodes={
        {n=G.UIT.R, config={align = "cm", padding = 0.1, minw = 4.72, minh = 3.1, colour = G.C.DYN_UI.DARK, r = 0.1}, nodes={
          {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = shop_sign}}
          }},
          {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {localize('ph_improve_run')}, colours = {lighten(G.C.GOLD, 0.3)},shadow = true, rotate = true, float = true, bump = true, scale = 0.5, spacing = 1, pop_in = 1.5, maxw = 4.3})}}
          }},
        }},
      }},
    config = {
      align="cm",
      offset = {x=0,y=-15},
      major = G.HUD:get_UIE_by_ID('row_blind'),
      bond = 'Weak'
    }
  }
  G.E_MANAGER:add_event(Event({
    trigger = 'immediate',
    func = (function()
        G.SHOP_SIGN.alignment.offset.y = 0
        return true
    end)
  }))
  local t = {n=G.UIT.ROOT, config = {align = 'cl', colour = G.C.CLEAR}, nodes={
          UIBox_dyn_container({
              {n=G.UIT.C, config={align = "cm", padding = 0.1, emboss = 0.05, r = 0.1, colour = G.C.DYN_UI.BOSS_MAIN}, nodes={
                  {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
                    {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
                      {n=G.UIT.R,config={id = 'next_round_button', align = "cm", minw = 2.8, minh = 1.0, r=0.15,colour = G.C.RED, one_press = true, button = 'toggle_shop', hover = true,shadow = true}, nodes = {
                        {n=G.UIT.R, config={align = "cm", padding = 0.07, focus_args = {button = 'y', orientation = 'cr'}, func = 'set_button_pip'}, nodes={
                          {n=G.UIT.T, config={text = localize('b_next_round_1') .. " " .. localize('b_next_round_2') , scale = 0.4, colour = G.C.WHITE, shadow = true}},   
                        }},              
                      }},
                      {n=G.UIT.R, config={align = "cm", minw = 2.8, minh = 1.6, r=0.15,colour = G.C.GREEN, button = 'reroll_shop', func = 'can_reroll', hover = true,shadow = true}, nodes = {
                        {n=G.UIT.R, config={align = "cm", padding = 0.07, focus_args = {button = 'x', orientation = 'cr'}, func = 'set_button_pip'}, nodes={
                          {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                            {n=G.UIT.T, config={text = localize('k_reroll'), scale = 0.4, colour = G.C.WHITE, shadow = true}},
                          }},
                          {n=G.UIT.R, config={align = "cm", maxw = 1.3, minw = 1}, nodes={
                            {n=G.UIT.T, config={text = localize('$'), scale = 0.7, colour = G.C.WHITE, shadow = true}},
                            {n=G.UIT.T, config={ref_table = G.GAME.current_round, ref_value = 'reroll_cost', scale = 0.75, colour = G.C.WHITE, shadow = true}},
                          }}
                        }}
                      }},
                      {n=G.UIT.R, config={align = "cm", minw = 2.8, minh = 1, r = 1, colour = G.C.PURPLE, hover = true, shadow = true, button="roulette_button"}, nodes = {
                        {n=G.UIT.T, config={text = "Roulette", scale = 0.5, colour = G.C.WHITE, shadow = true}}
                      }}
                    }},
                    {n=G.UIT.C, config={align = "cm", padding = 0.2, r=0.2, colour = G.C.L_BLACK, emboss = 0.05, minw = 8.2}, nodes={
                        {n=G.UIT.O, config={object = G.shop_jokers}},
                    }},
                  }},
                  {n=G.UIT.R, config={align = "cm", minh = 0.2}, nodes={}},
                  {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
                    {n=G.UIT.C, config={align = "cm", padding = 0.15, r=0.2, colour = G.C.L_BLACK, emboss = 0.05}, nodes={
                      {n=G.UIT.C, config={align = "cm", padding = 0.2, r=0.2, colour = G.C.BLACK, maxh = G.shop_vouchers.T.h+0.4}, nodes={
                        {n=G.UIT.T, config={text = localize{type = 'variable', key = 'ante_x_voucher', vars = {G.GAME.round_resets.ante}}, scale = 0.45, colour = G.C.L_BLACK, vert = true}},
                        {n=G.UIT.O, config={object = G.shop_vouchers}},
                      }},
                    }},
                    {n=G.UIT.C, config={align = "cm", padding = 0.15, r=0.2, colour = G.C.L_BLACK, emboss = 0.05}, nodes={
                      {n=G.UIT.O, config={object = G.shop_booster}},
                    }},
                  }}
              }
            },
            
            }, false)
      }}
  return t

end

Game.updateShopRef = Game.update_shop
function Game:update_shop(dt)
  self:updateShopRef(dt)

  --When spin is pressed
  if G.START_ROUL_SPIN then
    G.ROUL_SPIN = true
    G.START_ROUL_SPIN = false

    G.ROUL_VEL = randomFloat(6, 14) 


    --Retire money
    ease_dollars(-G.BET_SIZE)
  end

  --Roulette is spinning
  if G.ROUL_SPIN then
    local roulette = G.OVERLAY_MENU:get_UIE_by_ID("roulette_object")
    local current_rads = roulette.config.object.T.r 
    
    --Rotate and decelerate
    roulette:rotate(G.ROUL_VEL * dt)
    G.ROUL_VEL = G.ROUL_VEL - (1 * dt)

    --Play sound when passes from one section of the wheel to another
    if (math.floor(((PREV_RADS % 6.283185) % G.RADS_PER_SC) * 10) > 0) and (math.floor(((current_rads % 6.283185) % G.RADS_PER_SC) * 10) == 0) then
      play_sound('button', 0.9 + math.random()*0.1, 0.8)
    end

    PREV_RADS = current_rads
  end  

  --Roulette stops
  if G.ROUL_VEL <= 0.01 and G.ROUL_SPIN then
    local roulette = G.OVERLAY_MENU:get_UIE_by_ID("roulette_object")
    
    local colour_landed = roulette_landing(roulette.config.object.T.r, G.WHEEL)
    
    --If colourLanded is the same as the colour the bet was placed on, its a win
    if colour_landed == G.BET_COLOUR then
      ease_dollars(roulette_payout(G.PAYOUTS, colour_landed, G.BET_SIZE))
    else
      
      --If bet size left from last bet is bigger than wallet, set to current all-in.
      --Should i make a function that manages better BET_SIZE better? Yes. Will I do it? Idk
      if G.BET_SIZE > G.GAME.dollars and G.GAME.dollars >= 0 then G.BET_SIZE = G.GAME.dollars end
      G.FUNCS.update_bet_size_bump_rate()
    end
    
    --STOPS THE ROULETTE
    G.ROUL_SPIN = false
  end
  

end

function Controller:key_press_update(key, dt)
  if self.locks.frame then return end
  if string.sub(key, 1, 2) == 'kp' then key = string.sub(key, 3) end
  if key == 'enter' then key = 'return' end

  if self.text_input_hook then
      if key == "escape" then
          self.text_input_hook = nil
      elseif key == "capslock" then
          self.capslock = not self.capslock
      else
          G.FUNCS.text_input_key{
              e=self.text_input_hook,
              key = key,
              caps = self.held_keys["lshift"] or self.held_keys["rshift"]
          }
      end
      return
  end

  if key == "escape" then
      if G.STATE == G.STATES.SPLASH then 
          G:delete_run()
          G:main_menu()
      else
          if not G.OVERLAY_MENU then 
              G.FUNCS:options()
          elseif not G.OVERLAY_MENU.config.no_esc then
              G.ROUL_SPIN = false
              G.FUNCS:exit_overlay_menu()
          end
      end
  end

  if ((self.locked) and not G.SETTINGS.paused) or (self.locks.frame) or (self.frame_buttonpress) then return end
  self.frame_buttonpress = true    
  self.held_key_times[key] = 0


  if not _RELEASE_MODE then
      if key == 'tab' and not G.debug_tools then
          G.debug_tools = UIBox{
              definition = create_UIBox_debug_tools(),
              config = {align='cr', offset = {x=G.ROOM.T.x + 11,y=0},major = G.ROOM_ATTACH, bond = 'Weak'}
          }
          G.E_MANAGER:add_event(Event({
              blockable = false,
              func = function()
                  G.debug_tools.alignment.offset.x = -4
                  return true
              end
          }))
      end
      if self.hovering.target and self.hovering.target:is(Card) then 
          local _card = self.hovering.target
          if  G.OVERLAY_MENU then 
              if key == "1"  then
                  unlock_card(_card.config.center)
                  _card:set_sprites(_card.config.center)
              end
              if key == "2" then
                  unlock_card(_card.config.center)
                  discover_card(_card.config.center)
                  _card:set_sprites(_card.config.center)
              end
              if key == "3" then
                  if _card.ability.set == 'Joker' and G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
                      add_joker(_card.config.center.key)
                      _card:set_sprites(_card.config.center)
                  end
                  if _card.ability.consumeable and G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
                      add_joker(_card.config.center.key)
                      _card:set_sprites(_card.config.center)
                  end
              end
          end
          if key == 'q' then
              if (_card.ability.set == 'Joker' or _card.playing_card or _card.area) then
                  local _edition = {
                      foil = not _card.edition,
                      holo = _card.edition and _card.edition.foil,
                      polychrome = _card.edition and _card.edition.holo,
                      negative = _card.edition and _card.edition.polychrome,
                  }
                  _card:set_edition(_edition, true, true)
              end
          end
      end
      if key == 'h' then
          G.debug_UI_toggle = not G.debug_UI_toggle
      end
      if key == 'b' then
          G:delete_run()
          G:start_run({})
      end
      if key == 'l' then
          G:delete_run()
          G.SAVED_GAME = get_compressed(G.SETTINGS.profile..'/'..'save.jkr')
          if G.SAVED_GAME ~= nil then G.SAVED_GAME = STR_UNPACK(G.SAVED_GAME) end
          G:start_run({savetext = G.SAVED_GAME})
      end
      if key == 'j' then
          G.debug_splash_size_toggle = not G.debug_splash_size_toggle
          G:delete_run()
          G:main_menu('splash')
      end
      if key == '8' then
          love.mouse.setVisible( not love.mouse.isVisible() )
      end
      if key == '9' then
          G.debug_tooltip_toggle = not G.debug_tooltip_toggle
      end
    if key == "space" then
        live_test()
    end
    if key == 'v' then
      if not G.prof then G.prof = require "engine/profile"; G.prof.start()
      else    G.prof:stop();
          print(G.prof.report()); G.prof = nil end
      end
     if key == "p" then
         G.SETTINGS.perf_mode = not G.SETTINGS.perf_mode
     end
  end
end

---------------------------

function G.FUNCS.roulette_button()
  G.FUNCS.overlay_menu({
    definition = create_roulette_menu(),
    config = {}
  })
end

function G.FUNCS.ease_bet_size_plus_1()
  local num = 1
  if (G.BET_SIZE + num) >= G.GAME.dollars and G.GAME.dollars > 0 then
    G.BET_SIZE = G.GAME.dollars
  elseif G.GAME.dollars > 0 then
    G.BET_SIZE = G.BET_SIZE + num 
  end
  G.FUNCS.update_bet_size_bump_rate()

end

function G.FUNCS.ease_bet_size_plus_10()
  local num = 10
  if (G.BET_SIZE + num) >= G.GAME.dollars and G.GAME.dollars > 0 then
    G.BET_SIZE = G.GAME.dollars
  elseif G.GAME.dollars > 0 then
    G.BET_SIZE = G.BET_SIZE + num 
  end
  G.FUNCS.update_bet_size_bump_rate()

end

function G.FUNCS.ease_bet_size_plus_100()
  local num = 100
  if (G.BET_SIZE + num) >= G.GAME.dollars and G.GAME.dollars > 0 then
    G.BET_SIZE = G.GAME.dollars
  elseif G.GAME.dollars > 0 then
    G.BET_SIZE = G.BET_SIZE + num 
  end
  G.FUNCS.update_bet_size_bump_rate()

end

function G.FUNCS.ease_bet_size_minus_1()
  local num = -1
  if (G.BET_SIZE + num) <= 0 then
    G.BET_SIZE = 0
  else
    G.BET_SIZE = G.BET_SIZE + num 
  end
  G.FUNCS.update_bet_size_bump_rate()

end

function G.FUNCS.ease_bet_size_minus_10()
  local num = -10
  if (G.BET_SIZE + num) <= 0 then
    G.BET_SIZE = 0
  else
    G.BET_SIZE = G.BET_SIZE + num 
  end
  G.FUNCS.update_bet_size_bump_rate()

end

function G.FUNCS.ease_bet_size_minus_100()
  local num = -100
  if (G.BET_SIZE + num) <= 0 then
    G.BET_SIZE = 0
  else
    G.BET_SIZE = G.BET_SIZE + num 
  end
  G.FUNCS.update_bet_size_bump_rate()

end

function G.FUNCS.update_bet_size_bump_rate()
  local bet_size = G.OVERLAY_MENU:get_UIE_by_ID("bet_size")
  if G.GAME.dollars > 5 then
    bet_size.config.object.bump_rate = (G.BET_SIZE / G.GAME.dollars) * 13 + 2
    bet_size.config.object.bump_amount = (G.BET_SIZE / G.GAME.dollars) * 3 + 0.5
  else
    bet_size.config.object.bump_rate = 2
    bet_size.config.object.bump_amount = 0.5
  end
end

function G.FUNCS.update_spin_colour(element)
  local spin_btn = G.OVERLAY_MENU:get_UIE_by_ID("spin_button")
  spin_btn.config.colour = element.config.colour

  G.BET_COLOUR = element.children[1].children[1].config.text
end

function G.FUNCS.start_roul_spin()
  if not G.ROUL_SPIN then
    G.START_ROUL_SPIN = true
  end
end

--Function for Roulette Overlay Menu
function create_roulette_menu()

  local rouletteasset = Sprite(0,0,8.5,8.5, G.ASSET_ATLAS["roulette"], {x=0, y=0})
  local markerasset = Sprite(0,0,0.5,0.5, G.ASSET_ATLAS["roul_marker"], {x=0, y=0})

  local t = {n=G.UIT.ROOT, config = {align = 'cm', minw = 20, minh = 10, padding = 0.15, r = 0.5, colour = G.C.CLEAR}, nodes = {
    {n=G.UIT.R, config={minw = 20, minh = 10, padding = 0.15, colour = G.C.BLACK, r = 0.5}, nodes = {
      {n=G.UIT.R, config={minw = 20, minh = 9, padding = 0.15, r = 0.3, colour = G.C.GREY}, nodes = { --Row containing roulette and functionality
        {n=G.UIT.C, config={align ="cm", maxw = 9, minh = 9}, nodes = {
          {n=G.UIT.R, nodes={
            {n=G.UIT.O, config={id = "roulette_object", object = rouletteasset}},
          }},
          {n=G.UIT.R, config={align = "m"}, nodes={
            {n=G.UIT.O, config={object = markerasset}}
          }}
        }},
        {n=G.UIT.C, config={align = "m",minw = 11, minh = 9, r = 0.3}, nodes = { --Column for functionality
          {n=G.UIT.R, config={minw = 8, minh = 3, padding = 0.16}, nodes = { --Bet size managing 1st row
            {n=G.UIT.C, config={align = "cm",minw = 2.5, minh = 2.84, padding = 0.11, r=0.3}, nodes ={ --Left column containing minus buttons
              {n=G.UIT.R, config={align = "cm", minw = 2.5, minh = 0.83, r=0.3, hover = true, emboss = 0.1, colour = G.C.PURPLE, button = "ease_bet_size_minus_1"}, nodes={
                {n=G.UIT.T, config = {text = "-1", scale = 0.7}}
              }},
              {n=G.UIT.R, config={align = "cm", minw = 2.5, minh = 0.83, r=0.3, hover = true, emboss = 0.1, colour = G.C.PURPLE, button = "ease_bet_size_minus_10"}, nodes={
                {n=G.UIT.T, config = {text = "-10", scale = 0.7}}
              }},
              {n=G.UIT.R, config={align = "cm", minw = 2.5, minh = 0.83, r=0.3, hover = true, emboss = 0.1, colour = G.C.PURPLE, button = "ease_bet_size_minus_100"}, nodes={
                {n=G.UIT.T, config = {text = "-100", scale = 0.7}}
              }}
            }},
            {n=G.UIT.C, config={align ="cm", minw = 2.5, minh = 2.84, r=0.3, colour = G.C.DYN_UI.BOSS_MAIN}, nodes = { --Bordes are made using 2 components, one smaller inside a larger one with different colors
              {n=G.UIT.C, config={align ="cm", minw = 2.4, minh = 2.64, r=0.3, colour = G.C.DYN_UI.BOSS_DARK}, nodes = {
                {n=G.UIT.O, config={id="bet_size", object = DynaText({string = {{ref_table = G, ref_value = "BET_SIZE", prefix = localize('$')}}, colours = {G.C.UI.TEXT_LIGHT}, bump = true, bump_rate = 2, config = {minh = 2.84, maxw = 2.5, scale = 2}})}}
              }}
            }},
            {n=G.UIT.C, config={align = "cm",minw = 2.5, minh = 2.84, padding = 0.11, r=0.3}, nodes ={ --Right column containing plus buttons
            {n=G.UIT.R, config={align = "cm", minw = 2.5, minh = 0.83, r=0.3, hover = true, emboss = 0.1, colour = G.C.GREEN, button = "ease_bet_size_plus_1"}, nodes={
              {n=G.UIT.T, config = {text = "+1", scale = 0.7}}
            }},
            {n=G.UIT.R, config={align = "cm", minw = 2.5, minh = 0.83, r=0.3, hover = true, emboss = 0.1, colour = G.C.GREEN, button = "ease_bet_size_plus_10"}, nodes={
              {n=G.UIT.T, config = {text = "+10", scale = 0.7}}
            }},
            {n=G.UIT.R, config={align = "cm", minw = 2.5, minh = 0.83, r=0.3, hover = true, emboss = 0.1, colour = G.C.GREEN, button = "ease_bet_size_plus_100"}, nodes={
              {n=G.UIT.T, config = {text = "+100", scale = 0.7}}
            }}
          }}
          }},
          {n=G.UIT.R, config={align = "cm", padding = 0.1, minw = 8, minh = 3, colour = G.C.CLEAR}, nodes = {  --2nd row
            {n=G.UIT.C, config={align = "cm", minw = 2.5, minh = 2.8, colour = G.C.RED, hover = true, emboss = 0.1, r = 0.3, button = "update_spin_colour"}, nodes = {
              {n=G.UIT.R, nodes = {
                {n=G.UIT.T, config={text="RED", scale = 1,colour = G.C.UI.TEXT_LIGHT}}
              }},
              {n=G.UIT.R, config = {align = "m"}, nodes = {
                {n=G.UIT.T, config={text="x1.8", scale = 0.4,colour = G.C.UI.TEXT_LIGHT}}
              }}
            }},
            {n=G.UIT.C, config={align = "cm", minw = 2.5, minh = 2.8, colour = G.C.GREEN, hover = true, emboss = 0.1, r = 0.3, button = "update_spin_colour"}, nodes = {
              {n=G.UIT.R, nodes = {
                {n=G.UIT.T, config={text="GREEN", scale = 1,colour = G.C.UI.TEXT_LIGHT}}
              }},
              {n=G.UIT.R, config = {align = "m"}, nodes = {
                {n=G.UIT.T, config={text="x11", scale = 0.4,colour = G.C.UI.TEXT_LIGHT}}
              }}
            }},
            {n=G.UIT.C, config={align = "cm", minw = 2.5, minh = 2.8, colour = G.C.BLACK, hover = true, emboss = 0.1, r = 0.3, button = "update_spin_colour"}, nodes = {
              {n=G.UIT.R, nodes = {
                {n=G.UIT.T, config={text="BLACK", scale = 1,colour = G.C.UI.TEXT_LIGHT}}
              }},
              {n=G.UIT.R, config = {align = "m"}, nodes = {
                {n=G.UIT.T, config={text="x2", scale = 0.4,colour = G.C.UI.TEXT_LIGHT}}
              }}
            }}
          }},
          {n=G.UIT.R, config={align = "cm", minw = 8, minh = 3, padding = 0.2, colour = G.C.CLEAR}, nodes={  --3rd row
            {n=G.UIT.C, config={id = "spin_button", align = "cm", minw = 3, minh = 1.5, colour = G.C.MULT, r = 0.1, hover = true, emboss = 0.1, button = "start_roul_spin"}, nodes = { --Spin button
              {n=G.UIT.T, config = {text = "Spin", scale = 1, colour = G.C.TEXT_LIGHT}}
            }},
            {n=G.UIT.C, config={align = "cm", minw = 3, minh = 1.5, padding = 0.15, colour = G.C.DYN_UI.BOSS_MAIN, r = 0.1}, nodes = { --Money count
              {n=G.UIT.C, config={align = "cm", minw = 2.65, minh = 1.35, colour = G.C.DYN_UI.BOSS_DARK, r = 0.1}, nodes = {
                {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME, ref_value = 'dollars', prefix = localize('$')}}, colours = {G.C.MONEY}, font = G.LANGUAGES['en-us'].font, shadow = true, bump = true, scale = 0.8}), id = 'dollar_text_UI'}}
              }}
            }}
          }}
        }}
      }}
    }},
    {n=G.UIT.R, config={align = "cm", minw = 20, minh = 1, colour = G.C.CLEAR}, nodes = { --Button row
      {n=G.UIT.R, config={align = "cm", padding = 0.15}, nodes = {
        {n=G.UIT.R, config={align = "cm", minw = 2, minh = 1, colour = G.C.GOLD, hover = true, shadow = true, emboss = 0.08, r = 0.3, button="exit_roulette_menu"}, nodes = {
          {n=G.UIT.T, config={text =  "Back", minw = 2, scale = 0.7, minh = 0.9, shadow = true, colour = G.C.UI.TEXT_LIGHT}}
        }}
      }}
    }}
  }}

  return t
end

--Only for UIT.O aka Objects
function Moveable:rotate(rad)
  self.VT.r = self.VT.r + rad 
  self.config.object.VT.r = self.VT.r + rad 
  self.T.r = self.T.r + rad 
  self.config.object.T.r = self.T.r + rad 
end

--sections = {"GREEN","RED","BLACK","RED","BLACK","RED","BLACK","RED","BLACK"... etc}
function roulette_landing(rads, wheel)
  local sections = #wheel
  local real_rads = rads % 6.283185
  local rads_per_section = 6.283185 / sections
  local section_landed = math.floor(real_rads / rads_per_section) + 1

  return wheel[section_landed]
end

function roulette_payout(payouts, landed_on, dollars_bet)
    return dollars_bet * payouts[landed_on]
end


--Almost identical function as "exit_menu_overlay", just adapted to exit correctly roulette menu
G.FUNCS.exit_roulette_menu = function()
  if not G.OVERLAY_MENU then return end
  G.CONTROLLER.locks.frame_set = true
  G.CONTROLLER.locks.frame = true
  G.CONTROLLER:mod_cursor_context_layer(-1000)
  G.OVERLAY_MENU:remove()
  G.OVERLAY_MENU = nil
  G.VIEWING_DECK = nil
  G.SETTINGS.paused = false

  G.ROUL_SPIN = false

  --Save settings to file
  G:save_settings()
end



--smodsinitend
--end
----------------------------------------------
------------MOD CODE END----------------------
