print("Loading Cyperunk 2077 Furigana settings")

registerForEvent("onInit", function()
	local kanjicolorize = { [1] = "No Colors", [2] = "Same Color", [3] = "Two Colors" }

	-- create default settings
	local stateDefaults = {
		enabled = true,
		colorizeKanji = 3,
		colorizeKatakana = true,
		addSpaces = false
	}
	-- copy the defaults to a new settings objects
	local state = {}
	for k,v in pairs(stateDefaults) do
		state[k] = v
	end
	
	-- init session
	local GameSession = require('GameSession')

	if GameSession then
		GameSession.StoreInDir('sessions') -- Set directory to store session data
		GameSession.Persist(state) -- Link the data that should be watched and persisted
	else
		print("Error: GameSession not found! Furigana settings will not be saved!")
	end

	Observe('FuriganaSettings', 'PersistState', function(self)
		state.enabled = self.prop
	end)

	Observe('FuriganaSettings', 'LoadPersistedState', function(self)
		self.prop = state.enabled
	end)

	-- creare ui
	local nativeSettings = GetMod("nativeSettings") -- Get a reference to the nativeSettings mod

	if not nativeSettings then -- Make sure the mod is installed
		print("Error: NativeSettings not found! Please get it from https://www.nexusmods.com/cyberpunk2077/mods/3518.")
		return
	end

	-- reference https://github.com/justarandomguyintheinternet/CP77_nativeSettings

	nativeSettings.addTab("/furigana", "Furigana") -- Add our mods tab (path, label)

	nativeSettings.addSwitch("/furigana", "Enabled", "Disable the mod to get the original subtitles.", state.enabled, stateDefaults.enabled, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Enabled to ", value)
	end)

	nativeSettings.addSelectorString("/furigana", "Colorize Kanji", "Kanji and their furigana are shown in a different color, so it is easier to distinguish them.", kanjicolorize, state.colorizeKanji, stateDefaults.colorizeKanji, function(value) -- path, label, desc, elements, currentValue, defaultValue, callback
		print("Changed Colorize Kanji to ", kanjicolorize[value])
		-- Add in any logic you need in here, such as saving the changed to file / database
	end)

	nativeSettings.addSwitch("/furigana", "Colorize Katakana", "Katakana is shown in a different color, so it is easier to distinguish them.", state.colorizeKatakana, stateDefaults.colorizeKatakana, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Colorize Katakana to ", value)
	end)

	nativeSettings.addSwitch("/furigana", "Add Extra Spaces", "Add spaces to the text, like in Roman languages, so it is easier to see the sentence structure.", state.addSpaces, stateDefaults.addSpaces, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Add Extra Spaces to ", value)
	end)

	nativeSettings.addButton("/furigana", "Report Incorrect Reading", "When you see incorrect kanji readings, please report them. Opens browser window.", "Report Issue", 45, function() -- Parameters: path, label, desc, buttonText, textSize, callback, optionalIndex
		print("User clicked Report Issue")
		-- Add any logic you need in here, such as calling a function from your mod
	end)
end)
