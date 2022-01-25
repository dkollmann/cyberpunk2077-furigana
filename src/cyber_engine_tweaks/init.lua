registerForEvent("onInit", function()
	local nativeSettings = GetMod("nativeSettings") -- Get a reference to the nativeSettings mod

	if not nativeSettings then -- Make sure the mod is installed
		print("Error: NativeSettings not found! Please get it from https://www.nexusmods.com/cyberpunk2077/mods/3518.")
		return
	end

	-- reference https://github.com/justarandomguyintheinternet/CP77_nativeSettings

	local kanjicolorize = {[1] = "No Colors", [2] = "Same Color", [3] = "Two Colors"}

	nativeSettings.addTab("/furigana", "Furigana") -- Add our mods tab (path, label)

	nativeSettings.addSwitch("/furigana", "Enabled", "Disable the mod to get the original subtitles.", true, true, function(state) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Enabled to ", state)
	end)

	nativeSettings.addSelectorString("/furigana", "Colorize Kanji", "Kanji and their furigana are shown in a different color, so it is easier to distinguish them.", kanjicolorize, 3, 3, function(value) -- path, label, desc, elements, currentValue, defaultValue, callback
		print("Changed Colorize Kanji to ", kanjicolorize[value])
		-- Add in any logic you need in here, such as saving the changed to file / database
	end)

	nativeSettings.addSwitch("/furigana", "Colorize Katakana", "Katakana is shown in a different color, so it is easier to distinguish them.", true, true, function(state) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Colorize Katakana to ", state)
	end)

	nativeSettings.addSwitch("/furigana", "Add Extra Spaces", "Add spaces to the text, like in Roman languages, so it is easier to see the sentence structure.", true, true, function(state) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Add Extra Spaces to ", state)
	end)

	nativeSettings.addButton("/furigana", "Report Incorrect Reading", "When you see incorrect kanji readings, please report them. Opens browser window.", "Report Issue", 45, function() -- Parameters: path, label, desc, buttonText, textSize, callback, optionalIndex
		print("User clicked Report Issue")
		-- Add any logic you need in here, such as calling a function from your mod
	end)

	print("Loaded Cyberpunk 2077 Furigana settings.")
end)
