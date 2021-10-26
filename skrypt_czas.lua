--author: Radosław Schwichtenberg 
obs           = obslua
source_name   = ""
total_seconds = 0
cur_seconds   = 0
last_text     = ""
stop_text     = ""
next_scene	  = ""
activated     = false

-- Funkcja zwracajaca lancuch znakow
function set_time_text()
	local seconds       = math.floor(cur_seconds % 60)
	local total_minutes = math.floor(cur_seconds / 60)
	local minutes       = math.floor(total_minutes % 60)
	local total_hours   = math.floor(total_minutes / 60)
	
	local text          = string.format("%02d:%02d:%02d", total_hours, minutes, seconds)

-- Aktualizowanie lancucha znakow
	if text ~= last_text then
		local source = obs.obs_get_source_by_name(source_name)
		if source ~= nil then
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", text)
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
		end
	end
-- Przypisanie wartosci czasu do zmiennej globalnej(last_text)
	last_text = text
end


-- Funkcja, ktora liczy i obsluguje koniec odliczania
function timer_callback()
	cur_seconds = cur_seconds - 1
	if cur_seconds < 0 then
		obs.remove_current_callback()
		cur_seconds = 0
	end

	set_time_text()
end

-- Funkcja aktywujaca albo dezaktywujaca liczenie
function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		cur_seconds = total_seconds
		set_time_text()
		obs.timer_add(timer_callback, 1000)
	else
		obs.timer_remove(timer_callback)
	end
end

-- Funkcja laczaca skrypt z komponentem
function activate_signal(cd, activating)
-- rzutowanie parametry wskaźnika na obiekt
	local source = obs.calldata_source(cd, "source") 
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end

-- Funkcja obslugujaca wlaczenie
function source_activated(cd)
	activate_signal(cd, true)
end
-- Funkcja obslugujaca wylaczenie
function source_deactivated(cd)
	activate_signal(cd, false)
end

-- Funkcja resetujaca
function reset()
	activate(false)
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local active = obs.obs_source_active(source)
		obs.obs_source_release(source)
		activate(active)
	end
end

----------------------------------------------------------

-- Funkcja obslugujaca ilosc czasu ktory chcemy ustawic
function script_properties()
	local props = obs.obs_properties_create()
	local p = obs.obs_properties_add_list(props, "source", "Timer Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)

-- Pola tekstowe
	obs.obs_properties_add_int(props, "days", "Days", 0, 366, 1)
	obs.obs_properties_add_int(props, "hours", "Hours", 0, 23, 1)
	obs.obs_properties_add_int(props, "minutes", "Minutes", 0, 59, 1)
	obs.obs_properties_add_int(props, "seconds", "Seconds", 0, 59, 1)

	
	return props
end

-- Funkcja zwracajaca opis
function script_description()
	return "Witam, praca dyplomowa"
end

-- Funkcja reagujaca na zmiany -> wprowadzajaca zmiany
function script_update(settings)
	activate(false)

	total_seconds = (obs.obs_data_get_int(settings, "days")*24*60*60) + (obs.obs_data_get_int(settings, "hours")*60*60) + (obs.obs_data_get_int(settings, "minutes")*60) + obs.obs_data_get_int(settings, "seconds")
	source_name = "Zrodlo_1"
	stop_text = obs.obs_data_get_string(settings, "stop_text")
	next_scene = obs.obs_data_get_string(settings, "next_scene")

	reset(true)
end

-- Funkcja zerujaca
function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "days", 0)
	obs.obs_data_set_default_int(settings, "hours", 0)
	obs.obs_data_set_default_int(settings, "minutes", 0)
	obs.obs_data_set_default_int(settings, "seconds", 0)
	obs.obs_data_set_default_string(settings, "stop_text", "")
	obs.obs_data_set_default_string(settings, "next_scene", "-----")
end

-- Funkcja zapamietujaca ilosc wprowadzonego czasu
function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

-- Funkcja ladujaca skrypt
function script_load()
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

	hotkey_id = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Reset Timer", reset)
end
