/** Generates a list of blocks for the given string.
	The list works as following:
	  n = index % 3
	  n == 0 --> The first byte of the block, inside the string.
	  n == 1 --> The size of the block in bytes, inside the string.
	  n == 2 --> The type of the block. 0 = text, 1 = kanji, 2 = furigana */
private static native func StrSplitFurigana(text: String) -> array<Int16>;

/** Removes all furigana from a given string. */
private static native func StrStripFurigana(text: String) -> String;

@addField(SubtitleLineLogicController)
let furiganaWidgets: array< ref<inkText> >;

@addField(SubtitleLineLogicController)
let furiganaWidgetsHidden: array< ref<inkText> >;

@addMethod(SubtitleLineLogicController)
private func HideAllFuriganaWidgets() -> Void
{
	for w in this.furiganaWidgets
	{
		w.SetVisible(false);

		ArrayPush(this.furiganaWidgetsHidden, w);
	}

	ArrayResize(this.furiganaWidgets, 0);  // hopefully this retains the memory
}

@addMethod(SubtitleLineLogicController)
private func GetFuriganaWidget() -> ref<inkText>
{
	// use an existing widget
	if ArraySize(this.furiganaWidgetsHidden) > 0
	{
		let w = ArrayPop(this.furiganaWidgetsHidden);

		ArrayPush(this.furiganaWidgets, w);

		return w;
	}

	// create a new widget
	LogChannel(n"DEBUG", "Create furigana widget");

	let w = new inkText();

	w.SetVisible(false);
	w.SetSize(new Vector2(400, 400));
	w.SetAnchor(inkEAnchor.Fill);
	w.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily");  // base\gameplay\gui\fonts\foreign\japanese\smart_font_ui\smart_font_ui.inkfontfamily
    w.SetFontStyle(n"Medium");
    w.SetFontSize(24);

	w.Reparent( this.GetRootCompoundWidget() );

	ArrayPush(this.furiganaWidgetsHidden, w);

	return w;
}

@addMethod(SubtitleLineLogicController)
private func GenerateFuriganaWidgets(text :String, blocks :array<Int16>) -> Void
{
	// move all widgets to the hidden list
	this.HideAllFuriganaWidgets();

	// add the widgets as needed
	let size = ArraySize(blocks);
	let count = size / 3;

	let i = 0;
	while i < size
	{
		let start = Cast<Int32>( blocks[i] );
		let size  = Cast<Int32>( blocks[i + 1] );
		let type  = Cast<Int32>( blocks[i + 2] );

		LogChannel(n"DEBUG", "  " + ToString(start) + "  " + ToString(size) + "  " + ToString(type));

		let str = StrMid(text, start, size);

		let w = this.GetFuriganaWidget();

		w.SetText(str);
		w.SetVisible(true);

		i += 3;
	}
}

@addMethod(SubtitleLineLogicController)
private func GenerateFurigana(text :String) -> String
{
	let blocks = StrSplitFurigana(text);
	let size = ArraySize(blocks);
	let count = size / 3;

	if count < 1
	{
		return text;
	}

	this.GenerateFuriganaWidgets(text, blocks);

	return StrStripFurigana(text);
}

@replaceMethod(SubtitleLineLogicController)
public func SetLineData(lineData: scnDialogLineData) -> Void
{
	let characterRecordID: TweakDBID;
	let displayData: scnDialogDisplayString;
	let isValidName: Bool;
	let kiroshiAnimationCtrl: ref<inkTextKiroshiAnimController>;
	let motherTongueCtrl: ref<inkTextMotherTongueController>;
	let playerPuppet: ref<gamePuppetBase>;
	let speakerName: String;
	let speakerNameDisplayText: String;
	let speakerNameWidgetStateName: CName;

	this.m_lineData = lineData;

	// determine speaker name
	if IsStringValid(lineData.speakerName)
	{
		speakerName = lineData.speakerName;
	}
	else
	{
		speakerName = lineData.speaker.GetDisplayName();
	}

	// localize speaker name
	isValidName = IsStringValid(speakerName);
	speakerNameDisplayText = isValidName ? "LocKey#76968" : "";
	if isValidName
	{
		this.m_spekerNameParams.UpdateLocalizedString("NAME", speakerName);
	}

	// handle multiplayer
	if IsMultiplayer()
	{
		speakerNameWidgetStateName = n"Default";

		playerPuppet = lineData.speaker as gamePuppetBase;
		if playerPuppet != null
		{
			characterRecordID = playerPuppet.GetRecordID();
			speakerNameWidgetStateName = TweakDBInterface.GetCharacterRecord(characterRecordID).CpoClassName();
		}

		inkWidgetRef.SetState(this.m_speakerNameWidget, speakerNameWidgetStateName);
	}

	if Equals(lineData.type, scnDialogLineType.Radio)
	{
		// handle radio lines
		this.m_targetTextWidgetRef = this.m_radioSubtitle;
		inkTextRef.SetLocalizedTextScript(this.m_radioSpeaker, speakerNameDisplayText, this.m_spekerNameParams);
		inkWidgetRef.SetVisible(this.m_speakerNameWidget, false);
		inkWidgetRef.SetVisible(this.m_subtitleWidget, false);
		inkWidgetRef.SetVisible(this.m_radioSpeaker, true);
		inkWidgetRef.SetVisible(this.m_radioSubtitle, true);
	}
	else
	{
		if Equals(lineData.type, scnDialogLineType.AlwaysCinematicNoSpeaker)
		{
			// handle no speaker lines
			this.m_targetTextWidgetRef = this.m_radioSubtitle;
			inkWidgetRef.SetVisible(this.m_speakerNameWidget, false);
			inkWidgetRef.SetVisible(this.m_subtitleWidget, false);
			inkWidgetRef.SetVisible(this.m_radioSpeaker, false);
			inkWidgetRef.SetVisible(this.m_radioSubtitle, true);
		}
		else
		{
			if Equals(lineData.type, scnDialogLineType.GlobalTVAlwaysVisible)
			{
				// handle TV lines
				this.m_targetTextWidgetRef = this.m_subtitleWidget;
				inkWidgetRef.SetVisible(this.m_speakerNameWidget, false);
				inkWidgetRef.SetVisible(this.m_subtitleWidget, true);
				inkWidgetRef.SetVisible(this.m_radioSpeaker, false);
				inkWidgetRef.SetVisible(this.m_radioSubtitle, false);
			}
			else
			{
				// handle dialogue
				this.m_targetTextWidgetRef = this.m_subtitleWidget;
				inkTextRef.SetLocalizedTextScript(this.m_speakerNameWidget, speakerNameDisplayText, this.m_spekerNameParams);
				inkWidgetRef.SetVisible(this.m_speakerNameWidget, true);
				inkWidgetRef.SetVisible(this.m_subtitleWidget, true);
				inkWidgetRef.SetVisible(this.m_radioSpeaker, false);
				inkWidgetRef.SetVisible(this.m_radioSubtitle, false);
			}
		}
	}

	// handle Kiroshi implant
	if scnDialogLineData.HasKiroshiTag(lineData)
	{
		displayData = scnDialogLineData.GetDisplayText(lineData);

		if this.IsKiroshiEnabled()
		{
			// this is the tranlated text from the braindance
			kiroshiAnimationCtrl = inkWidgetRef.GetController(this.m_kiroshiAnimationContainer) as inkTextKiroshiAnimController;
			kiroshiAnimationCtrl.SetPreTranslatedText(displayData.preTranslatedText);
			kiroshiAnimationCtrl.SetPostTranslatedText(displayData.postTranslatedText);
			kiroshiAnimationCtrl.SetNativeText(displayData.text, displayData.language);
			kiroshiAnimationCtrl.SetTargetText(displayData.translation);
			this.SetupAnimation(this.m_lineData.duration, kiroshiAnimationCtrl);
			kiroshiAnimationCtrl.PlaySetAnimation();
		}
		else
		{
			// show the text readable for the player
			motherTongueCtrl = inkWidgetRef.GetControllerByType(this.m_motherTongueContainter, n"inkTextMotherTongueController") as inkTextMotherTongueController;
			motherTongueCtrl.SetPreTranslatedText("");
			motherTongueCtrl.SetNativeText(displayData.text, displayData.language);
			motherTongueCtrl.SetTranslatedText("");
			motherTongueCtrl.SetPostTranslatedText("");
			motherTongueCtrl.ApplyTexts();
		}
	}
	else
	{
		// handle mother tongue?
		if scnDialogLineData.HasMothertongueTag(lineData)
		{
			// allows dialogue to be shown which can or cannot be understood by the player
			displayData = scnDialogLineData.GetDisplayText(lineData);
			motherTongueCtrl = inkWidgetRef.GetControllerByType(this.m_motherTongueContainter, n"inkTextMotherTongueController") as inkTextMotherTongueController;
			motherTongueCtrl.SetPreTranslatedText(displayData.preTranslatedText);
			motherTongueCtrl.SetNativeText(displayData.text, displayData.language);
			motherTongueCtrl.SetTranslatedText(displayData.translation);
			motherTongueCtrl.SetPostTranslatedText(displayData.postTranslatedText);
			motherTongueCtrl.ApplyTexts();
		}
		else
		{
			// show normal lines
			LogChannel(n"DEBUG", "SUBTITLE: " + speakerName);

			let txt = this.GenerateFurigana(this.m_lineData.text);

			inkTextRef.SetText(this.m_targetTextWidgetRef, txt);
			this.PlayLibraryAnimation(n"intro");
		}
	}
}
