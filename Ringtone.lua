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

local rootSoundPath = "BMPES\\Ringtone\\"
local total_cut_data_files_loaded_count = 0

function file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end

function m.data_ready(ctx, filename)
    local stats = match.stats()

    if filename == "\\bra\\sound\\awb\\20_MAIN.awb" then 
        total_cut_data_files_loaded_count = 0
    end

    if stats and string.match(filename, "common\\demo\\fixdemo\\change\\cut_data\\change.*") then
        total_cut_data_files_loaded_count = total_cut_data_files_loaded_count + 1

        if total_cut_data_files_loaded_count == 1 then
            soundPath = ctx.sider_dir .. rootSoundPath .. ctx.home_team .. ".mp3"
            if file_exists(soundPath) then
                log("------------------------------------------------------------------------------ Arquivo " ..  ctx.home_team .. ".mp3 encontrado :)")
                ringtone = audio.new(soundPath)
                ringtone:set_volume(0.7) 
                ringtone:play() 
                ringtone:when_done(function() 
                    ringtone = nil 
                end)
            else
                log("---------------------------------------------------------------------- Arquivo " ..  ctx.home_team .. ".mp3 não existe :(")
            end
        end 
    end
end 

function m.init(ctx) 
    ctx.register("livecpk_data_ready", m.data_ready)
    base = memory.get_process_info().base 
end 

return m