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

local rootSoundPath = "BMPES\\TrilhaGol\\"
local soundtrackFilename = "soundtrack.mp3"

local score_changed = false
local total_goal_files_loaded_count = 0
local audio_files_loaded_count = 0

local last_clock_minutes_on_score = 0
local last_seconds_on_score = 0

function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

function m.teams_selected(ctx, home_team_id, away_team_id)
    total_goal_files_loaded_count = 0
    audio_files_loaded_count = 0
    last_clock_minutes_on_score = 0
    last_seconds_on_score = 0
end

local function process_matchstats(ctx, filename)
    local stats = match.stats()

    if string.match(filename, "sound\\awb\\20_MAIN.awb") then
        audio_files_loaded_count = audio_files_loaded_count + 1
        log("Quantidade de arquivos de audio 20_MAIN carregados: " .. audio_files_loaded_count)
    end

    -- goal\\cut_data\\goal
    if audio_files_loaded_count > 17 and string.match(filename, "FoxAnim\\FixDemo\\Animations\\dml_goal_celebrate.*") then   
        total_goal_files_loaded_count = total_goal_files_loaded_count + 1
        log("Quantidade de arquivo de GOL carregados: ".. total_goal_files_loaded_count)

        if total_goal_files_loaded_count == 1 then

            if last_clock_minutes_on_score == 0 then
                score_changed = true
            elseif stats.clock_minutes * 60 + stats.clock_seconds > last_seconds_on_score + 30 then
                score_changed = true
            else
                total_goal_files_loaded_count = 0
            end
        end
    end

    if score_changed == true then
        if stats then
            last_clock_minutes_on_score = stats.clock_minutes
            last_seconds_on_score = last_clock_minutes_on_score * 60 + stats.clock_seconds

            log("Minutos quando tocou a trilha: " .. last_clock_minutes_on_score)
            log("Segundos quando tocou a trilha: " .. last_seconds_on_score)
        end

        soundPath = ctx.sider_dir .. rootSoundPath .. soundtrackFilename
        
        if file_exists(soundPath) then
            log("------------------------------------------------------------------------------ Arquivo " .. soundtrackFilename .. " encontrado :) ")
            playerNameSound = audio.new(soundPath)
            playerNameSound:set_volume(0.7) 
            playerNameSound:play() 
            playerNameSound:when_done(function() 
                playerNameSound = nil
                total_goal_files_loaded_count = 0
                log("Trilha encerrada")
            end)
        else
            log("---------------------------------------------------------------------- Arquivo não existe :( ")
        end
       
        score_changed = false
    end  

end

function m.data_ready(ctx, filename)
    log(filename)
    process_matchstats(ctx, filename)

    if filename == "common\\script\\flow\\Match\\MatchSetupRematch.json" then
		-- log("Rematch detected ... ")
        audio_files_loaded_count = 0
        total_goal_files_loaded_count = 0
        last_clock_minutes_on_score = 0 
        last_seconds_on_score = 0
	end

    if filename == "common\\script\\flow\\Match\\MatchPostHalfTime.json" then
        last_clock_minutes_on_score = 45
        last_seconds_on_score = last_clock_minutes_on_score * 60
    end
end 

function m.init(ctx) 
    ctx.register("livecpk_data_ready", m.data_ready)
    ctx.register("set_teams", m.teams_selected)
    base = memory.get_process_info().base 
end 

return m