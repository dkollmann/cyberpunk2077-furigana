print("Loading Cyperunk 2077 Furigana settings")

registerForEvent("onInit", function()

	-- creare ui
	local nativeSettings = GetMod("nativeSettings") -- Get a reference to the nativeSettings mod

	if not nativeSettings then -- Make sure the mod is installed
		print("Error: NativeSettings not found! Please get it from https://www.nexusmods.com/cyberpunk2077/mods/3518.")
		return
	end

	-- some local properties
	local settingsFilename = "settings.json"

	local kanjicolorize = { [1] = "No Colors", [2] = "Same Color", [3] = "Two Colors" }

	-- create default settings
	local stateDefaults = {
		enabled = true,
		colorizeKanji = 3,
		colorizeKatakana = true,
		addSpaces = false,
		showFurigana = true,
		furiganaScale = 60,
		maxLineLength = 50
	}

	-- load settings
	state = nativeSettings.loadSettingsFile(io.open(settingsFilename, "r"), stateDefaults)
	
	-- make settings retrievable
	Observe('FuriganaSettings', 'Get', function(self)
		self.enabled = state.enabled
		self.colorizeKanji = state.colorizeKanji - 1
		self.colorizeKatakana = state.colorizeKatakana
		self.addSpaces = state.addSpaces
		self.showFurigana = state.showFurigana
		self.furiganaScale = state.furiganaScale / 100.0
		self.maxLineLength = state.maxLineLength
	end)

	-- reference https://github.com/justarandomguyintheinternet/CP77_nativeSettings

	nativeSettings.addTab("/furigana", "Furigana", function() -- Add our mods tab (path, label)
		nativeSettings.saveSettingsFile(io.open(settingsFilename, "w"), state)
	end)

	nativeSettings.addSwitch("/furigana", "Enabled", "Disable the mod to get the original subtitles.", state.enabled, stateDefaults.enabled, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Enabled to ", value)
		state.enabled = value
	end)

	nativeSettings.addSwitch("/furigana", "Show Furigana", "Add furigana to the kanji.", state.showFurigana, stateDefaults.showFurigana, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Show Furigana to ", value)
		state.showFurigana = value
	end)

	nativeSettings.addRangeFloat("/furigana", "Furigana Size", "The size of the furigana characters compared to the kanji ones.", 10, 100, 1, "%.0f%%", state.furiganaScale, stateDefaults.furiganaScale, function(value) -- path, label, desc, min, max, step, format, currentValue, defaultValue, callback, optionalIndex
		print("Changed Furigana Size to ", value)
		state.furiganaScale = value
	end)

	nativeSettings.addSelectorString("/furigana", "Colorize Kanji", "Kanji and their furigana are shown in a different color, so it is easier to distinguish them.", kanjicolorize, state.colorizeKanji, stateDefaults.colorizeKanji, function(value) -- path, label, desc, elements, currentValue, defaultValue, callback
		print("Changed Colorize Kanji to ", kanjicolorize[value])
		state.colorizeKanji = value
	end)

	nativeSettings.addSwitch("/furigana", "Colorize Katakana", "Katakana is shown in a different color, so it is easier to distinguish them.", state.colorizeKatakana, stateDefaults.colorizeKatakana, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Colorize Katakana to ", value)
		state.colorizeKatakana = value
	end)

	nativeSettings.addSwitch("/furigana", "Add Extra Spaces", "Add spaces to the text, like in Roman languages, so it is easier to see the sentence structure.", state.addSpaces, stateDefaults.addSpaces, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Add Extra Spaces to ", value)
		state.addSpaces = value
	end)

	nativeSettings.addRangeInt("/furigana", "Max Line Length", "The maximum number of characters per line.", 10, 100, 1, state.maxLineLength, stateDefaults.maxLineLength, function(value) -- path, label, desc, min, max, step, currentValue, defaultValue, callback, optionalIndex
		print("ChangedMax Line Length to ", value)
		state.maxLineLength = value
	end)


	nativeSettings.addButton("/furigana", "Report Incorrect Reading", "When you see incorrect kanji readings, please report them. Opens browser window.", "Report Issue", 45, function() -- Parameters: path, label, desc, buttonText, textSize, callback, optionalIndex
		print("User clicked Report Issue")
	end)
end)
