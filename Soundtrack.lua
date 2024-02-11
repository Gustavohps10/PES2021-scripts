--[[ By Gustavohps10. All rights reserved 2024
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
                                                                                                             
]]--

local m = {}

local rootSoundPath = "BMPES\\GoalSoundtrack\\"
local soundtrackFilename = "soundtrack.mp3"

local celebration_activated = false
local score_changed = false
local total_goal_files_loaded_count = 0

function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

function m.teams_selected(ctx, home_team_id, away_team_id)
    celebration_activated = false
    score_changed = false
    total_goal_files_loaded_count = 0
end

function m.before_celebration(ctx)
    local stats = match.stats()

    if stats then
        celebration_activated = true
       -- total_goal_files_loaded_count = 0
        log("################################### Antes da cutscene")
    end
end

local function process_matchstats(ctx, filename)
    local stats = match.stats()

    if string.match(filename, "common\\demo\\fixdemo\\goal\\cut_data\\goal_S_owngoal.*")        -- owngoal
        or string.match(filename, "common\\demo\\fixdemo\\timeup\\cut_data\\tu.*")              -- timeup
        or string.match(filename, "common\\demo\\fixdemo\\result\\cut_data\\result.*") then     -- HalfTime
        celebration_activated = false 
    end
                                                              
    if stats and celebration_activated then
                                -- "goal\\cut_data\\goal"   
        if string.match(filename, "FoxAnim\\FixDemo\\Animations\\dml_goal_celebrate.*") then
            total_goal_files_loaded_count = total_goal_files_loaded_count + 1
            log("Quantidade de arquivo de GOL carregados: ".. total_goal_files_loaded_count)

            if total_goal_files_loaded_count == 1 then
                score_changed = true
            end
        end
    end

    if score_changed == true then

        soundPath = ctx.sider_dir .. rootSoundPath .. soundtrackFilename
        
        if file_exists(soundPath) then
            log("------------------------------------------------------------------------------ Arquivo " .. soundtrackFilename .. ".mp3 encontrado :) ")
            playerNameSound = audio.new(soundPath)
            playerNameSound:set_volume(0.7) 
            playerNameSound:play() 
            playerNameSound:when_done(function() 
                playerNameSound = nil
                celebration_activated = false
                total_goal_files_loaded_count = 0
                score_changed = false
                log("Trilha encerrada")
            end)
        else
            log("---------------------------------------------------------------------- Arquivo não existe :( ")
        end
       
        celebration_activated = false
        score_changed = false
    end
end

function m.data_ready(ctx, filename)
    log(filename)
    process_matchstats(ctx, filename)

    if filename == "common\\script\\flow\\Match\\MatchSetupRematch.json" then
		-- log("Rematch detected ... ")
        total_goal_files_loaded_count = 0
        celebration_activated = false
	end
end 

function m.init(ctx) 
    ctx.register("livecpk_data_ready", m.data_ready)
    ctx.register("set_teams", m.teams_selected)
    ctx.register("trophy_rewrite", m.before_celebration)
    base = memory.get_process_info().base 
end 

return m