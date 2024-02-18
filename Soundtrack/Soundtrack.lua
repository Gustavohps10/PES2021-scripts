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

local soundtracks = {}
local selected_soundtrack_id = 1 -- ID from Selected Soundtrack
local playing_soundtrack_id      -- ID of the currently playing soundtrack
local soundtracks_amount = 0
local volume = 70
local soundtrack_audio
local overlay_text = "YVmVyc2lvbjogJXMgCiAgICBQcmVzcyBbOV1bMF0gYnV0dG9ucyB0byBjaGFuZ2Ugc291bmR0cmFjawogICAgUHJlc3MgWytdWy1dIGJ1dHRvbnMgdG8gaW5jcmVhc2UvZGVjcmVhc2Ugdm9sdW1lCiAgICBQcmVzcyBbOF0gICAgYnV0dG9uIHRvIHBsYXkvcGF1c2Ugc291bmR0cmFjawoKICAgIFNvdW5kdHJhY2s6ICVzCiAgICBWb2x1bWU6ICVzCiAgICAlcwogICAg"
local playing_text = ""
local settings
local uuid
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local started_in_time

local celebration_activated = false
local score_changed = false
local total_goal_files_loaded_count = 0
local total_chant_files_loaded_count = 0
local ball_file_loaded = false

local PREV_SOUNDTRACK_KEY = 0x39	--  9 key
local NEXT_SOUNDTRACK_KEY = 0x30  	--  0 key 
local INCREASE_VOLUME_KEY = 0xbb    --  + key  
local DECREASE_VOLUME_KEY = 0xbd    --  - key  
local PLAY_PAUSE_KEY = 0x38         --  8 key

local function dec(str)
    str = str:sub(2)
    str = string.gsub(str, '[^'..b..'=]', '')
    return (str:gsub('.', function(x)
      if (x == '=') then return '' end
      local r,f='',(b:find(x)-1)
      for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
      return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
      if (#x ~= 8) then return '' end
      local c=0
      for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
      return string.char(c)
    end))
end

local gsroot = dec("qLlxcU291bmR0cmFjaw==")

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

-- .ini file
local function load_ini(filename)
    local t = {}
	local data = assert(io.lines(gsroot .. "\\" .. filename))
	log(filename .. " found in " .. gsroot)

	for line in data do
		local name, value = string.match(line, "^([%w_]+)%s*=%s*([-%w%d.]+)")
		if name and value then
			value = tonumber(value) or value
			t[name] = value
			log(string.format("Using setting: %s = %s", name, value))
		end
	end
	return t
end

local function save_ini(filename)
    local f = io.open(gsroot .. "\\" .. filename, "wt")
    f:write(string.format(dec("nIyBTb3VuZHRyYWNrIHNldHRpbmdzLiBHZW5lcmF0ZWQgYnkgU291bmR0cmFjay5sdWFcbg==")))
    f:write("\n")
    f:write(dec("ic2VsZWN0ZWRfc291bmR0cmFja19pZCA9IA==") .. selected_soundtrack_id)
    f:write("\n")
    f:write(dec("wdm9sdW1lID0g") .. volume/100)
    f:write("\n")
    f:close()
end
-- end .ini file

local function play_soundtrack()
    local soundPath = gsroot .. dec("wXFxhdWRpb3NcXA==") .. soundtracks[selected_soundtrack_id][2]
    log("----- Soundtrack Path: " .. soundPath)        
    if file_exists(soundPath) then
        log("------------------------------------------------------------------------------ Arquivo " .. soundtracks[selected_soundtrack_id][2] .. " encontrado :) ")
        soundtrack_audio = audio.new(soundPath)
        soundtrack_audio:set_volume(volume/100) 
        soundtrack_audio:play()
        started_in_time = os.time(os.date("!*t"))
        playing_soundtrack_id = selected_soundtrack_id
        playing_text = string.format(dec("eLS0+IOKWtu+4jyBQbGF5aW5nIC0gJXMgLSAlcyA8LS0="), soundtracks[playing_soundtrack_id][2],soundtracks[playing_soundtrack_id][3]) 
        soundtrack_audio:when_done(function()
            soundtrack_audio = nil
            celebration_activated = false
            total_goal_files_loaded_count = 0
            total_chant_files_loaded_count = 0
            ball_file_loaded = false
            score_changed = false
            playing_text = "" 
            log("Trilha encerrada")
        end)
    else
        log("---------------------------------------------------------------------- Arquivo não existe :( ")
    end
end

local function process_matchstats(ctx, filename)
    local stats = match.stats()

    if string.match(filename, dec("AY29tbW9uXGRlbW9cZml4ZGVtb1xnb2FsXGN1dF9kYXRhXGdvYWxfU19vd25nb2FsLio="))         -- owngoal
        or string.match(filename, dec("WY29tbW9uXGRlbW9cZml4ZGVtb1x0aW1ldXBcY3V0X2RhdGFcdHUuKg=="))                 -- timeup
        or string.match(filename, dec("GY29tbW9uXGRlbW9cZml4ZGVtb1xyZXN1bHRcY3V0X2RhdGFccmVzdWx0Lio="))             -- HalfTime
        or string.match(filename, dec("GY29tbW9uXGRlbW9cZml4ZGVtb1xjaGFuZ2VcY3V0X2RhdGFcY2hhbmdlLio=")) then        -- change player
        celebration_activated = false 
    end
                                                              
    if stats and celebration_activated then
                                -- "goal\\cut_data\\goal"   
        if string.match(filename, dec("YRm94QW5pbVxGaXhEZW1vXEFuaW1hdGlvbnNcZG1sX2dvYWxfY2VsZWJyYXRlLio=")) then
            total_goal_files_loaded_count = total_goal_files_loaded_count + 1
            log("Quantidade de arquivo de GOL carregados: ".. total_goal_files_loaded_count)

            if total_goal_files_loaded_count == 1 then
                score_changed = true
            end
        end
    end

    if score_changed == true then

        play_soundtrack()
       
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

local opts = { image_height = 120, image_hmargin = 20, image_vmargin = 20 }
function m.overlay_on(ctx)
    local sname = soundtracks[selected_soundtrack_id][3]
    local text = string.format(dec(overlay_text), m.version, sname, volume .. "%", playing_text)
    local image = gsroot.. dec("wXFxsb2dvc1xc") .. sname .. dec("sLnBuZw==")
    return text, image, opts
end 

function m.hide(ctx)
    save_ini(dec("gY29uZmlnLmluaQ=="))
end

function  m.key_down(ctx, vkey)
    -- Change Soundtrack
    if vkey == NEXT_SOUNDTRACK_KEY then
        if(selected_soundtrack_id == soundtracks_amount) then
            selected_soundtrack_id = 1
        else
            selected_soundtrack_id = selected_soundtrack_id + 1
        end
    end

    if vkey == PREV_SOUNDTRACK_KEY then
        if selected_soundtrack_id == 1 then
            selected_soundtrack_id = soundtracks_amount
        else
            selected_soundtrack_id = selected_soundtrack_id - 1
        end
    end

    -- Volume
    if vkey == INCREASE_VOLUME_KEY then
        if volume + 10 <= 100 then
            volume = volume + 10

            if soundtrack_audio then
                soundtrack_audio:set_volume(volume/100)
            end
        end
    end

    if vkey == DECREASE_VOLUME_KEY then
        if volume - 10 >= 0 then
            volume = volume - 10

            if soundtrack_audio then
                soundtrack_audio:set_volume(volume/100)
            end
        end
    end

    -- Play Soundtrack
    if vkey == PLAY_PAUSE_KEY then
        if(soundtrack_audio) then
            playing_text = string.format(dec("jLS0+IOKPue+4jyBTdG9wcGluZyAtICVzIC0gJXMgPC0t"), soundtracks[playing_soundtrack_id][2], soundtracks[playing_soundtrack_id][3]) 
            soundtrack_audio:fade_to(0, 1) 
            soundtrack_audio:finish()
        else
            play_soundtrack()
        end
    end
end

function m.teams_selected(ctx, home_team_id, away_team_id)
    celebration_activated = false
    score_changed = false
    total_goal_files_loaded_count = 0
end

function m.data_ready(ctx, filename)
    log(filename)

    process_matchstats(ctx, filename)

    if filename == dec("GY29tbW9uXHNjcmlwdFxmbG93XE1hdGNoXE1hdGNoU2V0dXBSZW1hdGNoLmpzb24=") then
		-- log("Rematch detected ... ")
        total_goal_files_loaded_count = 0
        celebration_activated = false
	end

    -- stop audio when skipping
    if string.match(filename, dec("YQXNzZXRcbW9kZWxcYmFsbFxiYWxsJWQrXCNXaW5cYmFsbCUuZnBr")) and soundtrack_audio then
            ball_file_loaded = true
    end

    if soundtrack_audio and ball_file_loaded then

        if string.match(filename, dec("FY29tbW9uXHNvdW5kXG1hdGNoXGF3YlxDaGFudFxDSEFOVC4q")) then
            total_chant_files_loaded_count = total_chant_files_loaded_count + 1
            log("Total CHANT Files: "..total_chant_files_loaded_count)
        end

        if os.time(os.date("!*t")) >= started_in_time + 8 then -- wait 8 seconds
            if total_chant_files_loaded_count >= 30 
                or string.match(filename, dec("aY29tbW9uXHNvdW5kXG1hdGNoXGF3Ylxhbm5vdW5jZVwuKg=="))
                or string.match(filename, dec("Yb2Zmc2lkZQ=="))
            then
                soundtrack_audio:fade_to(0, 2)
                soundtrack_audio:finish()
                soundtrack_audio = nil
                log("Soundtrack ending....")
            end
        end

        if string.match(filename, dec("NY29tbW9uXGRlbW9cZml4ZGVtb1xnb2FsXGN1dF9kYXRhXGdvYWxfY2VsZWJyYXRlLio=")) then
            soundtrack_audio:fade_to(0, 1)
            soundtrack_audio:finish()
            soundtrack_audio = nil
            log("Soundtrack ending....")
        end
    end
end 

function m.init(ctx)
	if gsroot:sub(1,1)=='.' then
        gsroot = ctx.sider_dir .. gsroot
    end
	math.randomseed(os.time())

    settings = load_ini(dec("qY29uZmlnLmluaQ=="))
	load_map_txt(dec("abWFwX3NvdW5kdHJhY2tzLnR4dA==")) 

    selected_soundtrack_id = settings[dec("Ac2VsZWN0ZWRfc291bmR0cmFja19pZA==")]
    volume = settings[dec("rdm9sdW1l")] * 100

    ctx.register(dec("xbGl2ZWNwa19kYXRhX3JlYWR5"), m.data_ready)
    ctx.register(dec("2c2V0X3RlYW1z"), m.teams_selected)
    ctx.register(dec("ydHJvcGh5X3Jld3JpdGU="), m.before_celebration)
    ctx.register(dec("7b3ZlcmxheV9vbg=="), m.overlay_on)
    ctx.register(dec("8aGlkZQ=="), m.hide)
    ctx.register(dec("Ya2V5X2Rvd24="), m.key_down)
end

return m
