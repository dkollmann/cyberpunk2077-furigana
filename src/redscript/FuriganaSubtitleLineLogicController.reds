/** Generates a list of blocks for the given string.
	The list works as following:
	  n = index % 3
	  n == 0 --> The first byte of the block, inside the string.
	  n == 1 --> The size of the block in bytes, inside the string.
	  n == 2 --> The type of the block. 0 = text, 1 = kanji, 2 = furigana */
private static native func StrSplitFurigana(text: String) -> array<Int16>;

/** Removes all furigana from a given string. */
private static native func StrStripFurigana(text: String) -> String;

private static func Assert(cond :Bool, msg :String) -> Void
{
	if !cond {
		LogChannel(n"DEBUG", "ASSERT: " + msg);
	}
}

private static func Assert(widget :wref<inkWidget>, msg :String) -> Void
{
	if !IsDefined(widget) {
		LogChannel(n"DEBUG", "ASSERT: " + msg);
	}
}

private static func PrintWidgets(widget :wref<inkWidget>, indent :String) -> Void
{
	LogChannel(n"DEBUG", indent + ToString(widget.GetName()) + " : " + ToString(widget.GetClassName()));

	let compound = widget as inkCompoundWidget;

	if IsDefined(compound)
	{
		let count = compound.GetNumChildren();

		let i = 0;
		while i < count
		{
			let w2 = compound.GetWidgetByIndex(i);

			PrintWidgets(w2, indent + " ");

			i += 1;
		}
	}
}

private static func PrintWidgets(widget :inkWidgetRef) -> Void
{
	LogChannel(n"DEBUG", "--------------------");

	let w = inkWidgetRef.Get(widget);

	PrintWidgets(w, "");

	LogChannel(n"DEBUG", "--------------------");
}

@replaceMethod(SubtitlesGameController)
protected func CreateLine(lineSpawnData: ref<LineSpawnData>) -> Void
{
	this.AsyncSpawnFromLocal(this.m_subtitlesPanel, n"Line", this, n"OnLineSpawned", lineSpawnData);
}

/** This widget is our woot panel we use for our widgets. */
@addField(SubtitleLineLogicController)
private let furiganaroot :ref<inkHorizontalPanel>;

@addMethod(SubtitleLineLogicController)
private func CreateContainer() -> Void
{
	this.furiganaroot = new inkHorizontalPanel();
	this.furiganaroot.SetFitToContent(true);
	this.furiganaroot.SetName(n"furiganaSubtitle");

	let subtitlesWidget = this.GetRootWidget() as inkCompoundWidget;
	Assert(subtitlesWidget, "Failed to get root widget!!");

	let rootParent = subtitlesWidget.GetWidgetByPathName(n"Line/subtitleFlex") as inkCompoundWidget;
	Assert(rootParent, "Failed to get root Line/subtitleFlex!!");

	//let www = this.subtitlesWidget.GetWidgetByPathName(n"Line/subtitleFlex/subtitle") as inkText;
	//Assert(www, "Failed to get root Line/subtitleFlex/subtitle!!");
	//www.SetTintColor(new Color(Cast<Uint8>(0), Cast<Uint8>(255), Cast<Uint8>(0), Cast<Uint8>(255)));

	this.furiganaroot.Reparent(rootParent, 2);

	//LogChannel(n"DEBUG", "Added our own root widget...");
	//PrintWidgets(this.subtitlesWidget, "");
}

@addMethod(SubtitleLineLogicController)
private func GetFuriganaWidget() -> ref<inkText>
{
	// create a new widget
	let w = new inkText();

	w.SetName(n"furiganaTextWidget");
	//w.SetSize(new Vector2(400, 400));
	//w.SetAnchor(inkEAnchor.Fill);
	w.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");  // base\gameplay\gui\fonts\foreign\japanese\smart_font_ui\smart_font_ui.inkfontfamily
	w.SetFontSize(48);
	w.SetFitToContent(true);
	//w.EnableAutoScroll(true);
	//w.SetFitToContent(true);
	//w.SetSizeRule(inkESizeRule.Stretch);

	return w;
}

@addMethod(SubtitleLineLogicController)
private func GenerateFuriganaWidgets(text :String, blocks :array<Int16>) -> Void
{
	// create the container for our widgets
	this.CreateContainer();

	// add the widgets as needed
	let size = ArraySize(blocks);
	let count = size / 3;

	let i = 0;
	while i < size
	{
		let start = Cast<Int32>( blocks[i] );
		let size  = Cast<Int32>( blocks[i + 1] );
		let type  = Cast<Int32>( blocks[i + 2] );

		//LogChannel(n"DEBUG", "  " + ToString(start) + "  " + ToString(size) + "  " + ToString(type));

		let str = StrMid(text, start, size);

		let w = this.GetFuriganaWidget();

		w.SetTextDirect(str);

		w.Reparent(this.furiganaroot);

		i += 3;
	}

	//LogChannel(n"DEBUG", "Added all the widgets...");
	//PrintWidgets(this.subtitlesWidget, "");
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
			//LogChannel(n"DEBUG", "SUBTITLE: " + speakerName + " on " + ToString(inkTextRef.GetName(this.m_targetTextWidgetRef)) + " : " + ToString(inkTextRef.Get(this.m_targetTextWidgetRef).GetClassName()));

			let txt = this.GenerateFurigana(this.m_lineData.text);

			inkTextRef.SetText(this.m_targetTextWidgetRef, txt);
			//this.PlayLibraryAnimation(n"intro");
		}
	}
}
