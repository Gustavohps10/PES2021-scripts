/* By Gustavohps10. All rights reserved 2024
                                                                               (  )   (   )  )
                                                                                ) (   )  (  (
                                                                                ( )  (    ) )  
                                                                                 _____________
 _                             _                   _               _  ___       <_____________> ___
| |__  _   _    __ _ _   _ ___| |_ __ ___   _____ | |__  _ __  ___/ |/ _ \      |             |/ _ \
| '_ \| | | |  / _` | | | / __| __/ _` \ \ / / _ \| '_ \| '_ \/ __| | | | |     |               | | |
| |_) | |_| | | (_| | |_| \__ \ || (_| |\ V / (_) | | | | |_) \__ \ | |_| |     |               |_| |
|_.__/ \__, |  \__, |\__,_|___/\__\__,_| \_/ \___/|_| |_| .__/|___/_|\___/   ___|             |\___/
       |___/   |___/                                    |_|                 /    \___________/    \
                                                                            \_____________________/
                                                                                                             
*/

local m = {}

local rootSoundPath = "BMPES\\Comentarios\\PlayerName\\"

local curr_home_score = 0
local curr_away_score = 0
local who_scored
local score_changed = false

function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

function m.teams_selected(ctx, home_team_id, away_team_id)
	curr_home_score = 0
	curr_away_score = 0
end

local function process_matchstats(ctx, filename)
	local stats = match.stats()

    if stats then
		if stats.home_score > curr_home_score then 
			curr_home_score = curr_home_score + 1
			who_scored = "home team"
			score_changed = true
		elseif stats.away_score > curr_away_score then
			curr_away_score = curr_away_score + 1
			who_scored = "away team"
			score_changed = true
		else
			score_changed = false
		end
    end

    if score_changed == true then

        -- locates the currently controlled player
        --offsets = [base + 0x037F0AC8, 0x18, 0xC8, 0xF0, 0xC0, 0x538, 0x28, 0x1C4]
        addr1 = memory.unpack("u64", memory.read(base + 0x037F0AC8, 4))
        addr2 = addr1 + 0x18                                            
        addr3 = memory.unpack("u64", memory.read(addr2, 4))
        addr4 = addr3 + 0xC8
        addr5 = memory.unpack("u64", memory.read(addr4, 4))
        addr6 = addr5 + 0xF0
        addr7 = memory.unpack("u64", memory.read(addr6, 4))
        addr8 = addr7 + 0xC0
        addr9 = memory.unpack("u64", memory.read(addr8, 4))
        addr10 = addr9 + 0x538
        addr11 = memory.unpack("u64", memory.read(addr10, 4))
        addr12 = addr11 + 0x28
        addr13 = memory.unpack("u64", memory.read(addr12, 4))
        addr14 = addr13 + 0x1C4
        playerId  = memory.unpack("u32", memory.read(addr14, 4))
        
        log("------------------------------------------------------------------------------ Goal from: " .. who_scored)
        log("------------------------------------------------------------------------------ Goal from player: " .. playerId)

        soundPath = ctx.sider_dir .. rootSoundPath .. playerId .. ".mp3"
        if file_exists(soundPath) then
            log("------------------------------------------------------------------------------ Arquivo " .. playerId .. ".mp3 encontrado :)")
            playerNameSound = audio.new(soundPath)
            playerNameSound:set_volume(1) 
            playerNameSound:play() 
            playerNameSound:when_done(function() 
                playerNameSound = nil 
            end)
        else
            log("---------------------------------------------------------------------- Arquivo " .. playerId .. ".mp3 não existe :(")
        end

    end
end

function m.data_ready(ctx, filename)
    process_matchstats(ctx, filename)

    if filename == "common\\script\\flow\\Match\\MatchSetupRematch.json" then
		-- log("Rematch detected ... ")
		curr_home_score = 0
		curr_away_score = 0
	end
end 

function m.init(ctx) 
    ctx.register("livecpk_data_ready", m.data_ready)
    ctx.register("set_teams", m.teams_selected)
    base = memory.get_process_info().base 
end 

return m