--- STEAMODDED HEADER
--- MOD_NAME: RandomizerDeck
--- MOD_ID: HellyomRandomizerDeck
--- MOD_AUTHOR: [Hellyom]
--- MOD_DESCRIPTION: The Randomizer Deck randomizes itself, jokers, vouchers, planets, costs etc.

----------------------------------------------
------------MOD CODE -------------------------

local Backapply_to_runRef = Back.apply_to_run
function Back.apply_to_run(arg)
	Backapply_to_runRef(arg)

	if arg.effect.config.randomizerHellyom then
		--DECK SUITS AND RANKS
		G.E_MANAGER:add_event(Event({
			func = function()

				local cardsToDelete = math.random(1, 26)

				local ranks = {"2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"}
				local suits = {"H", "C", "D", "S"}

				for i = #G.playing_cards, 1, -1 do

					if i < cardsToDelete then G.playing_cards[i]:remove()

					else 
						local rank = ranks[math.random( #ranks )] 
						local suit = suits[math.random( #suits )]
						
						G.playing_cards[i]:set_base(G.P_CARDS[suit .. "_" .. rank])

					end
				end

				return true
			end
		}))


		--Add random vouchers
		local all_vouchers = {"v_overstock_norm", "v_clearance_sale", "v_hone", "v_reroll_surplus", "v_crystal_ball", "v_telescope", "v_grabber", "v_wasteful", "v_tarot_merchant", "v_planet_merchant", "v_seed_money", "v_blank", "v_magic_trick", "v_hieroglyph", "v_directors_cut", "v_paint_brush"}
		
		G.E_MANAGER:add_event(Event({
			func = function()
				local ranNum = math.random(#all_vouchers);


				G.GAME.used_vouchers[all_vouchers[ranNum]] = true
				G.GAME.starting_voucher_count = (G.GAME.starting_voucher_count or 0) + 1
				Card.apply_to_run(nil, G.P_CENTERS[all_vouchers[ranNum]])

				return true
			end
		}))
	end
end

local new_round_ref = new_round
function new_round()
	new_round_ref()

	if G.GAME.selected_back.name == "Randomizer Deck" then

		G.E_MANAGER:add_event(Event({
			func = function ()

				local hand_change = math.random(-2,2)
				local discard_change = math.random(-2,2)
				sendDebugMessage("hand_change = " .. hand_change)
				sendDebugMessage("round_resets.hands = " .. G.GAME.round_resets.hands)
				ease_hands_played(hand_change)
				ease_discard(discard_change)

				return true

			end
		}))
	end
end

OG_P_CENTERS = G.P_CENTERS
OG_P_TAGS = G.P_TAGS

--Randomize joker, voucher etc values based on seed
Game.start_run_ref = Game.start_run
function Game:start_run(args)
	self:start_run_ref(args)

	if G.GAME.selected_back.name == "Randomizer Deck" then
		
		--Seals
		for k, v in pairs(G.P_TAGS) do
			if v.config and next(v.config) ~= nil then

				v.config = randomizeTable(v.config)

			end
		end

		--Centers
		for k, v in pairs(G.P_CENTERS) do
			if v.set ~= "Back" and (v.config and next(v.config)) ~= nil then

				if v.cost then v.cost = math.random(1, v.cost*2) end

				v.config = randomizeTable(v.config)

			end
		end
		
	else
		G.P_CENTERS = OG_P_CENTERS
		G.P_TAGS = OG_P_TAGS
	end

end

function randomizeTable(table)
	for k, v in pairs(table) do
		if type(v) == "number" then
			table[k] = math.random(1, v*2)
		elseif type(v) == "table" and next(v) ~= nil then
			randomizeTable(v)
		end
	end

	return table
end

local loc_def = {
	["name"]="Randomizer Deck",
	["text"]={
		[1]="Start with a {C:attention}randomized{} deck",
		[2]="and {C:purple}1{} random basic {C:purple}voucher{}.",
		[3]="{C:dark_edition}Other things are also randomized...{}"
	},
}


----------------------------------------------

local randomdeck = SMODS.Deck:new("Randomizer Deck", "randomizerHellyom", {randomizerHellyom = true}, {x = 2, y = 3}, loc_def)
randomdeck:register()

----------------------------------------------
------------MOD CODE END----------------------