-- taken from https://stackoverflow.com/questions/2353211/hsl-to-rgb-color-conversion
function hue2rgb(p, q, t)
	if t < 0 then t = t + 1 end
	if t > 1 then t = t - 1 end
	if t < 1/6 then return p + (q - p) * 6 * t end
	if t < 1/2 then return q end
	if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
	return p
end

function hslToRgb(h, s, l)
    local r, g, b

    if s == 0 then
        r = l -- achromatic
		g = l
		b = l
    else
		local q
		if l < 0.5 then
			q = l * (1 + s)
		else
			q = l + s - l * s
		end

        local p = 2 * l - q

        r = hue2rgb(p, q, h + 1/3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1/3)
	end

    return { r=math.floor(r * 255 + 0.5), g=math.floor(g * 255 + 0.5), b=math.floor(b * 255 + 0.5) }
end

registerForEvent("onInit", function()

	-- creare ui
	local nativeSettings = GetMod("nativeSettings") -- Get a reference to the nativeSettings mod

	if not nativeSettings then -- Make sure the mod is installed
		print("Error: NativeSettings not found! Please get it from https://www.nexusmods.com/cyberpunk2077/mods/3518.")
		return
	end

	-- some local properties
	local settingsFilename = "settings.json"

	local kanjicolorize = { [1] = "No Colors", [2] = "Same Color", [3] = "Change Colors (per word)", [4] = "Change Colors (per line)" }
	local mothertonguetransmode = { [1] = "Show Instant", [2] = "Fade In"}

	-- create default settings
	local stateDefaults = {
		colorizeKanji = 4,
		colorizeKatakana = true,
		addSpaces = false,
		showFurigana = true,
		furiganaScale = 60,

		dialogMaxLineLength = 40,
		dialogBackgroundOpacity = 15,

		chatterMaxLineLength = 40,
		chatterTextScale = 150,

		motherTongueShow = true,
		motherTongueScale = 80,
		motherTongueTransMode = 2,
		motherTongueFadeInTime = 20,

		colorTextHue = 184,
		colorTextSat = 100,

		colorMotherTongueLight = 100,

		colorKatakanaHue = 197,
		colorKatakanaSat = 100,

		colorKanjiHue1 = 35,
		colorKanjiHue2 = 77,
		colorKanjiSat = 50,

		showLineIDs = false
	}

	-- load settings
	state = nativeSettings.loadSettingsFile(io.open(settingsFilename, "r"), stateDefaults)
	
	-- make settings retrievable
	Observe('FuriganaSettings', 'Get', function(self)
		self.colorizeKanji = state.colorizeKanji - 1
		self.colorizeKatakana = state.colorizeKatakana
		self.addSpaces = state.addSpaces
		self.showFurigana = state.showFurigana
		self.furiganaScale = state.furiganaScale / 100.0

		self.dialogMaxLineLength = state.dialogMaxLineLength
		self.dialogBackgroundOpacity = state.dialogBackgroundOpacity / 100.0

		self.chatterMaxLineLength = state.chatterMaxLineLength
		self.chatterTextScale = state.chatterTextScale / 100.0

		self.motherTongueShow = state.motherTongueShow
		self.motherTongueScale = state.motherTongueScale / 100.0
		self.motherTongueTransMode = state.motherTongueTransMode - 1
		self.motherTongueFadeInTime = state.motherTongueFadeInTime / 100.0

		self.colorTextHue = state.colorTextHue / 360.0
		self.colorTextSat = state.colorTextSat / 100.0

		self.colorMotherTongueLight = state.colorMotherTongueLight / 100.0

		self.colorKatakanaHue = state.colorKatakanaHue / 360.0
		self.colorKatakanaSat = state.colorKatakanaSat / 100.0

		self.colorKanjiHue1 = state.colorKanjiHue1 / 360.0
		self.colorKanjiHue2 = state.colorKanjiHue2 / 360.0
		self.colorKanjiSat = state.colorKanjiSat / 100.0

		self.showLineIDs = state.showLineIDs
	end)

	-- ui helper functions
	UpdateTextPreviewPathName = Game.StringToName("wrapper/wrapper/previewText")
	function UpdateTextPreview(create)
		if create then
			local widget = nativeSettings.settingsMainController:GetRootCompoundWidget():GetWidgetByPathName(Game.StringToName("wrapper/wrapper"))

			GenerateSettingsPreview(widget, true)
		else
			local widget = nativeSettings.settingsMainController:GetRootCompoundWidget():GetWidgetByPathName(UpdateTextPreviewPathName)

			GenerateSettingsPreview(widget, false)
		end
	end

	function RemoveTextPreview()
		local widget = nativeSettings.settingsMainController:GetRootCompoundWidget():GetWidgetByPathName(Game.StringToName("wrapper/wrapper"))

		widget:RemoveChildByName(Game.StringToName("previewText"))
		widget:RemoveChildByName(Game.StringToName("previewTextHint"))
	end
	
	function UpdateColorSlider(slider, hue, sat, light)
		local clr = hslToRgb(hue / 360.0, sat / 100.0, light / 100.0);
	
		slider.controller.sliderWidget:SetTintColor(clr.r, clr.g, clr.b, 255)
		slider.controller.LabelText:SetTintColor(clr.r, clr.g, clr.b, 255)
		slider.controller.ValueText:SetTintColor(clr.r, clr.g, clr.b, 255)
	
		UpdateTextPreview(false)
	end

	-- reference https://github.com/justarandomguyintheinternet/CP77_nativeSettings

	nativeSettings.addTab("/furigana", "Furigana", function() -- Add our mods tab (path, label)
		nativeSettings.saveSettingsFile(io.open(settingsFilename, "w"), state)

		RemoveTextPreview()
	end)

	nativeSettings.addSubcategory("/furigana/general", "General")
	nativeSettings.addSubcategory("/furigana/colors", "Text Colors")
	nativeSettings.addSubcategory("/furigana/dialog", "Dialogues")
	nativeSettings.addSubcategory("/furigana/chatter", "Chatter")
	nativeSettings.addSubcategory("/furigana/mothertongue", "Foreign Speech (Haitian Creole)")
	nativeSettings.addSubcategory("/furigana/debug", "Debug Options")

	------------------------------ TEXT PREVIEW ------------------------------
	FuriganaPreview = nativeSettings.addCustom("/furigana", function(widget, options)
		UpdateTextPreview(true)
	end)

	------------------------------ GENERAL ------------------------------
	nativeSettings.addSwitch("/furigana/general", "Show Furigana*", "Add furigana to the kanji.", state.showFurigana, stateDefaults.showFurigana, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Show Furigana to ", value)
		state.showFurigana = value
		UpdateTextPreview()
	end)

	nativeSettings.addRangeFloat("/furigana/general", "Furigana Size*", "The size of the furigana characters compared to the kanji ones.", 10, 100, 1, "%.0f%%", state.furiganaScale, stateDefaults.furiganaScale, function(value) -- path, label, desc, min, max, step, format, currentValue, defaultValue, callback, optionalIndex
		print("Changed Furigana Size to ", value)
		state.furiganaScale = value
		UpdateTextPreview()
	end)

	nativeSettings.addSelectorString("/furigana/general", "Colorize Kanji*", "Kanji and their furigana are shown in a different color, so it is easier to distinguish them.", kanjicolorize, state.colorizeKanji, stateDefaults.colorizeKanji, function(value) -- path, label, desc, elements, currentValue, defaultValue, callback
		print("Changed Colorize Kanji to ", kanjicolorize[value])
		state.colorizeKanji = value
		UpdateTextPreview()
	end)

	nativeSettings.addSwitch("/furigana/general", "Colorize Katakana*", "Katakana is shown in a different color, so it is easier to distinguish them.", state.colorizeKatakana, stateDefaults.colorizeKatakana, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Colorize Katakana to ", value)
		state.colorizeKatakana = value
		UpdateTextPreview()
	end)

	nativeSettings.addSwitch("/furigana/general", "Add Extra Spaces*", "Add spaces to the text, like in Roman languages, so it is easier to see the sentence structure.", state.addSpaces, stateDefaults.addSpaces, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Add Extra Spaces to ", value)
		state.addSpaces = value
		UpdateTextPreview()
	end)

	------------------------------ COLORS ------------------------------
	ColorTextHueSlider = nativeSettings.addRangeInt("/furigana/colors", "Normal Text Color", "The color of the normal text.", 0, 360, 1, state.colorTextHue, stateDefaults.colorTextHue, function(value) -- path, label, desc, min, max, step, currentValue, defaultValue, callback, optionalIndex
		print("Changed Normal Text Color to ", value)
		state.colorTextHue = value

		UpdateColorSlider(ColorTextHueSlider, state.colorTextHue, state.colorTextSat, 68)
	end)

	ColorTextHueSlider = nativeSettings.addRangeInt("/furigana/colors", "Normal Text Saturation", "The saturation of the normal text.", 0, 100, 1, state.colorTextSat, stateDefaults.colorTextSat, function(value) -- path, label, desc, min, max, step, currentValue, defaultValue, callback, optionalIndex
		print("Changed Normal Text Saturation to ", value)
		state.colorTextSat = value

		UpdateColorSlider(ColorTextHueSlider, state.colorTextHue, state.colorTextSat, 68)
	end)

	------------------------------ DIALOG ------------------------------
	nativeSettings.addRangeInt("/furigana/dialog", "Max Line Length", "The maximum number of characters per line in dialogues.", 10, 100, 1, state.dialogMaxLineLength, stateDefaults.dialogMaxLineLength, function(value) -- path, label, desc, min, max, step, currentValue, defaultValue, callback, optionalIndex
		print("Changed Dialog Max Line Length to ", value)
		state.dialogdialogMaxLineLength = value
	end)

	nativeSettings.addRangeFloat("/furigana/dialog", "Background Opacity", "Making the background more transparent when selecting dialog options keeps the kanji more readable.", 10, 100, 1, "%.0f%%", state.dialogBackgroundOpacity, stateDefaults.dialogBackgroundOpacity, function(value) -- path, label, desc, min, max, step, format, currentValue, defaultValue, callback, optionalIndex
		print("Changed Dialog Background Opacity to ", value)
		state.dialogBackgroundOpacity = value
	end)

	------------------------------ CHATTER ------------------------------
	nativeSettings.addRangeInt("/furigana/chatter", "Max Line Length", "The maximum number of characters per line.", 10, 100, 1, state.chatterMaxLineLength, stateDefaults.chatterMaxLineLength, function(value) -- path, label, desc, min, max, step, currentValue, defaultValue, callback, optionalIndex
		print("Changed Chatter Max Line Length to ", value)
		state.chatterMaxLineLength = value
	end)

	nativeSettings.addRangeFloat("/furigana/chatter", "Chatter Text Size", "Increase the size of chatter text in the world so it is easier to read.", 100, 300, 1, "%.0f%%", state.chatterTextScale, stateDefaults.chatterTextScale, function(value) -- path, label, desc, min, max, step, format, currentValue, defaultValue, callback, optionalIndex
		print("Changed Chatter Text Size to ", value)
		state.chatterTextScale = value
	end)

	------------------------------ MOTHER TONGUE ------------------------------
	nativeSettings.addSwitch("/furigana/mothertongue", "Show Untranslated Text*", "Show a subtitle for the untranslated speech.", state.motherTongueShow, stateDefaults.motherTongueShow, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Show Untranslated Text to ", value)
		state.motherTongueShow = value
		UpdateTextPreview()
	end)

	nativeSettings.addRangeFloat("/furigana/mothertongue", "Untranslated Text Size*", "The size of the untranslated text, when shown.", 10, 200, 1, "%.0f%%", state.motherTongueScale, stateDefaults.motherTongueScale, function(value) -- path, label, desc, min, max, step, format, currentValue, defaultValue, callback, optionalIndex
		print("Changed Untranslated Text Size to ", value)
		state.motherTongueScale = value
		UpdateTextPreview()
	end)

	nativeSettings.addSelectorString("/furigana/mothertongue", "Translated Text Mode", "Select how translated text will be shown.", mothertonguetransmode, state.motherTongueTransMode, stateDefaults.motherTongueTransMode, function(value) -- path, label, desc, elements, currentValue, defaultValue, callback
		print("Changed Translated Text Mode to ", mothertonguetransmode[value])
		state.colormotherTongueTransModezeKanji = value
	end)

	nativeSettings.addRangeFloat("/furigana/mothertongue", "Translated Text Fade-in Time", "The time the translated text needs to fade-in, relative to the duration of the untranslated line.", 10, 100, 1, "%.0f%%", state.motherTongueFadeInTime, stateDefaults.motherTongueFadeInTime, function(value) -- path, label, desc, min, max, step, format, currentValue, defaultValue, callback, optionalIndex
		print("Changed Translated Text Fade-in Time to ", value)
		state.motherTongueFadeInTime = value
	end)

	------------------------------ DEBUG ------------------------------
	nativeSettings.addSwitch("/furigana/debug", "Show Line IDs", "Shows the ID of the individual lines. This is needed to report issues.", state.showLineIDs, stateDefaults.showLineIDs, function(value) -- path, label, desc, currentValue, defaultValue, callback
		print("Changed Show Line IDs to ", value)
		state.showLineIDs = value
	end)

	nativeSettings.addButton("/furigana/debug", "Report Incorrect Reading", "When you see incorrect kanji readings, please report them. Opens browser window.", "Report Issue", 45, function() -- Parameters: path, label, desc, buttonText, textSize, callback, optionalIndex
		print("User clicked Report Issue")

		OpenBrowser("http://www.google.com");
	end)
end)
