-- QuestConfig: MISIONES DIARIAS. Cada día tocan 3 misiones distintas (las mismas todo el día para ti).
-- Al completar las 3 hay un cofre extra.
local QuestConfig = {}

QuestConfig.PerDay = 3

-- Kind = qué cuenta: KOs · Damage (% hecho) · Matches · Wins · Specials · Ults · Obby · Roulette
QuestConfig.Pool = {
	{ Id = "KO5", Kind = "KOs", Goal = 5, Text = "Get 5 KOs", Reward = { Coins = 300, XP = 100 } },
	{ Id = "KO12", Kind = "KOs", Goal = 12, Text = "Get 12 KOs", Reward = { Coins = 700, XP = 200 } },
	{ Id = "DMG300", Kind = "Damage", Goal = 300, Text = "Deal 300% damage", Reward = { Coins = 250, XP = 100 } },
	{ Id = "DMG800", Kind = "Damage", Goal = 800, Text = "Deal 800% damage", Reward = { Coins = 600, XP = 200 } },
	{ Id = "PLAY3", Kind = "Matches", Goal = 3, Text = "Play 3 matches", Reward = { Coins = 400, XP = 150 } },
	{ Id = "WIN1", Kind = "Wins", Goal = 1, Text = "Win 1 match", Reward = { Coins = 500, Gems = 5 } },
	{ Id = "WIN3", Kind = "Wins", Goal = 3, Text = "Win 3 matches", Reward = { Coins = 900, Gems = 10 } },
	{ Id = "SPEC25", Kind = "Specials", Goal = 25, Text = "Use 25 special techniques", Reward = { Coins = 250, XP = 120 } },
	{ Id = "ULT2", Kind = "Ults", Goal = 2, Text = "Use your ULT 2 times", Reward = { Coins = 450, XP = 150 } },
	{ Id = "OBBY1", Kind = "Obby", Goal = 1, Text = "Complete the Cursed Ascent obby", Reward = { Coins = 300, XP = 150 } },
	{ Id = "SPIN1", Kind = "Roulette", Goal = 1, Text = "Spin the Cursed Roulette", Reward = { Coins = 150 } },
}

QuestConfig.AllDoneBonus = { Coins = 500, Gems = 15 }

function QuestConfig.Get(id: string)
	for _, q in QuestConfig.Pool do
		if q.Id == id then
			return q
		end
	end
	return nil
end

-- Las misiones del día de un jugador (siempre las mismas para ese día; nunca dos del mismo tipo)
function QuestConfig.ForDay(day: number, userId: number): { string }
	local rng = Random.new(day * 7919 + userId % 100000)
	local pool = table.clone(QuestConfig.Pool)
	local chosen, kinds = {}, {}
	while #chosen < QuestConfig.PerDay and #pool > 0 do
		local q = table.remove(pool, rng:NextInteger(1, #pool))
		if not kinds[q.Kind] then
			kinds[q.Kind] = true
			table.insert(chosen, q.Id)
		end
	end
	return chosen
end

return QuestConfig
