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
m.version = "1.0"

local gsroot = ".\\BMPES\\GoalSoundtrack"
local soundtracks = {}
local selected_soundtrack_id = 1 -- ID from Selected Soundtrack
local soundtracks_amount = 0

local celebration_activated = false
local score_changed = false
local total_goal_files_loaded_count = 0

local PREV_VALUE_KEY = 0xbd 	--  - key
local NEXT_VALUE_KEY = 0xbb 	--  + key

local function trim(s)
  return s:gsub("^%s*(.-)%s*$", "%1")
end

local function get_common_lib(ctx)
    return ctx.common_lib or _empty
end

local function file_exists(filename)
    local f = io.open(filename)
    if f then
        f:close()
        return true
    end
end

local function file_exists(name)
	local f=io.open(name,"r")
	if f~=nil then 
		io.close(f) 
		return true 
	else 
		return false 
	end
end

local function mysplit (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            str = trim(str)
            table.insert(t, str)
        end
        return t
end

local function load_map_txt(filename)
    log("LOAD SOUND TXT")
    local delim = ","
    local data = assert(io.lines(gsroot .. "\\" .. filename))
    local first_caractere

    for line in data do
		line = trim(string.gsub(line, "^\239\187\191", ""))
        first_caractere = string.sub(line, 1, 1)

        log(line)

        if first_caractere ~= "#" and first_caractere ~= "" then
            soundtracks_amount = soundtracks_amount + 1
            table.insert(soundtracks, mysplit(line, ",")) -- 1=ID, 2=Filename, 3=Name
        end
    end

    -- for i, soundtrack in pairs(soundtracks) do
    --     log(soundtrack[3])
    -- end
end

local function process_matchstats(ctx, filename)
    local stats = match.stats()

    if string.match(filename, "common\\demo\\fixdemo\\goal\\cut_data\\goal_S_owngoal.*")        -- owngoal
        or string.match(filename, "common\\demo\\fixdemo\\timeup\\cut_data\\tu.*")              -- timeup
        or string.match(filename, "common\\demo\\fixdemo\\result\\cut_data\\result.*")          -- HalfTime
        or string.match(filename, "common\\demo\\fixdemo\\change\\cut_data\\change.*") then     -- change player
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

        local soundPath = gsroot .. "\\" .. soundtracks[selected_soundtrack_id][2]
        log(soundPath)        
        if file_exists(soundPath) then
            log("------------------------------------------------------------------------------ Arquivo " .. soundtracks[selected_soundtrack_id][2] .. " encontrado :) ")
            soundtrack = audio.new(soundPath)
            soundtrack:set_volume(0.7) 
            soundtrack:play() 
            soundtrack:when_done(function() 
                soundtrack = nil
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

function m.before_celebration(ctx)
    local stats = match.stats()

    if stats then
        celebration_activated = true
       -- total_goal_files_loaded_count = 0
        log("################################### Antes da cutscene")
    end
end

function m.overlay_on(ctx)
    return string.format("Version: %s | Press [+][-] buttons to change soundtrack: %s", m.version, soundtracks[selected_soundtrack_id][3]) -- Name of Soundtrack
end 

function  m.key_down(ctx, vkey)
    if vkey == NEXT_VALUE_KEY then
        if(selected_soundtrack_id == soundtracks_amount) then
            selected_soundtrack_id = 1
        else
            selected_soundtrack_id = selected_soundtrack_id + 1
        end
    end

    if vkey == PREV_VALUE_KEY then
        if selected_soundtrack_id == 1 then
            selected_soundtrack_id = soundtracks_amount
        else
            selected_soundtrack_id = selected_soundtrack_id - 1
        end
    end
end

function m.teams_selected(ctx, home_team_id, away_team_id)
    celebration_activated = false
    score_changed = false
    total_goal_files_loaded_count = 0
end

function m.data_ready(ctx, filename)
    -- log(filename)

    process_matchstats(ctx, filename)

    if filename == "common\\script\\flow\\Match\\MatchSetupRematch.json" then
		-- log("Rematch detected ... ")
        total_goal_files_loaded_count = 0
        celebration_activated = false
	end
end 

function m.init(ctx)
	if gsroot:sub(1,1)=='.' then
        gsroot = ctx.sider_dir .. gsroot
    end
	math.randomseed(os.time())

	load_map_txt("map_soundtracks.txt")
    log(soundtracks[1][3])

    ctx.register("livecpk_data_ready", m.data_ready)
    ctx.register("set_teams", m.teams_selected)
    ctx.register("trophy_rewrite", m.before_celebration)
    ctx.register("overlay_on", m.overlay_on)
    ctx.register("key_down", m.key_down)
end

return m
