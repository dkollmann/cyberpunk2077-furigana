/** Generates a list of blocks for the given string.
	The list works as following:
	  n = index % 3
	  n == 0 --> The first byte of the block, inside the string.
	  n == 1 --> The size of the block in bytes, inside the string.
	  n == 2 --> The type of the block. 0 = text, 1 = kanji, 2 = furigana */
private static native func StrSplitFurigana(text: String) -> array<Int16>;

/** Removes all furigana from a given string. */
private static native func StrStripFurigana(text: String) -> String;

/** Determine the last word in the string before "end". */
private static native func StrFindLastWord(text: String, end :Int32) -> Int32;

/** Counts the number of actual utf-8 characters in the string. */
private static native func UnicodeStringLen(text: String) -> Int32;

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

@addMethod(SubtitlesGameController)
protected cb func OnLineSpawned(widget: ref<inkWidget>, userData: ref<IScriptable>) -> Bool
{
	let controller: wref<SubtitleLineLogicController>;
	let newLineEntry: subtitleLineMapEntry;
	let lineSpawnData: ref<LineSpawnData> = userData as LineSpawnData;

	if IsDefined(widget)
	{
		this.SetupLine(widget, lineSpawnData);
		controller = widget.GetController() as SubtitleLineLogicController;
		newLineEntry.id = lineSpawnData.m_lineData.id;
		newLineEntry.widget = widget;
		newLineEntry.owner = lineSpawnData.m_lineData.speaker;
		ArrayPush(this.m_lineMap, newLineEntry);
		this.OnSubCreated(controller);
		controller.subtitlesPanel = this.m_subtitlesPanel;
		controller.SetKiroshiStatus(this.IsKiroshiEnabled(lineSpawnData.m_lineData));
		controller.SetLineData(lineSpawnData.m_lineData);
		controller.ShowBackground(this.m_showBackgroud);
	}

	this.TryRemovePendingHideLines();
}

/** This widget containing all visible subtitle lines. */
@addField(SubtitleLineLogicController)
private let subtitlesPanel :ref<inkVerticalPanel>;

/** This widget is our root panel we use for our widgets. */
@addField(SubtitleLineLogicController)
private let furiganaroot :ref<inkVerticalPanel>;

/** The widgets represent one line of our subtitles. */
@addField(SubtitleLineLogicController)
private let furiganalines :array< ref<inkHorizontalPanel> >;

@addMethod(SubtitleLineLogicController)
private func CreateRootWidget() -> Void
{
	this.furiganaroot = new inkVerticalPanel();
	this.furiganaroot.SetName(n"furiganaSubtitle");
	this.furiganaroot.SetFitToContent(true);
	this.furiganaroot.SetHAlign(inkEHorizontalAlign.Left);
	this.furiganaroot.SetVAlign(inkEVerticalAlign.Top);

	let subtitlesWidget = this.GetRootWidget() as inkCompoundWidget;
	Assert(subtitlesWidget, "Failed to get root widget!!");

	let rootParent = subtitlesWidget.GetWidgetByPathName(n"Line/subtitleFlex") as inkCompoundWidget;
	Assert(rootParent, "Failed to get root Line/subtitleFlex!!");

	this.furiganaroot.Reparent(rootParent);
}

@addMethod(SubtitleLineLogicController)
private func CreateNewLineWidget() -> ref<inkHorizontalPanel>
{
	let newline = new inkHorizontalPanel();
	newline.SetName(n"furiganaSubtitleLine");
	newline.SetFitToContent(true);
	newline.SetHAlign(inkEHorizontalAlign.Left);
	newline.SetVAlign(inkEVerticalAlign.Top);
	newline.Reparent(this.furiganaroot);

	ArrayPush(this.furiganalines, newline);

	return newline;
}

private func AddTextWidget(text :String, parent :ref<inkHorizontalPanel>, fontsize :Int32) -> Void
{
	let w = new inkText();
	w.SetName(n"furiganaTextWidget");
	w.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");
	w.SetTintColor(new Color(Cast<Uint8>(93), Cast<Uint8>(245), Cast<Uint8>(255), Cast<Uint8>(255)));
	w.SetFontSize(fontsize);
	w.SetFitToContent(true);
	w.SetHAlign(inkEHorizontalAlign.Left);
	w.SetVAlign(inkEVerticalAlign.Top);
	w.SetText(text);
	w.Reparent(parent);
}

@addMethod(SubtitleLineLogicController)
private func GenerateFuriganaWidgets(text :String, blocks :array<Int16>, fontsize :Int32) -> Void
{
	// create the root for all our lines
	this.CreateRootWidget();

	// add the widgets as needed
	let size = ArraySize(blocks);
	let count = size / 3;

	// limit length
	let maxlinelength = 60;

	let linewidget = this.CreateNewLineWidget();
	let currcharlen = 0;

	let i = 0;
	while i < size
	{
		let start = Cast<Int32>( blocks[i] );
		let size  = Cast<Int32>( blocks[i + 1] );
		let type  = Cast<Int32>( blocks[i + 2] );

		let str = StrMid(text, start, size);
		let count = UnicodeStringLen(str);

		// limit the length, but only for text
		if type == 0 && currcharlen + count > maxlinelength
		{
			// try to find a word
			let remains = maxlinelength - currcharlen;
			let word = StrFindLastWord(str, remains);

			if word >= 0
			{
				// we found a word to split
				let str1 = StrMid(str, 0, word);

				AddTextWidget(str1, linewidget, fontsize);

				// we need a new root for the next line
				linewidget = this.CreateNewLineWidget();

				// the next line takes the rest
				str = StrMid(str, word);
				currcharlen = 0;
			}
			else
			{
				// no word found to split so simply add the text as usual
			}
		}

		currcharlen += count;

		AddTextWidget(str, linewidget, fontsize);

		i += 3;
	}
}

@addMethod(SubtitleLineLogicController)
private func GenerateFurigana(text :String, fontsize :Int32) -> Bool
{
	let blocks = StrSplitFurigana(text);
	let size = ArraySize(blocks);
	let count = size / 3;

	if count < 1
	{
		return false;
	}

	this.GenerateFuriganaWidgets(text, blocks, fontsize);

	//return StrStripFurigana(text);

	return true;
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

			let fontsize = inkTextRef.GetFontSize(this.m_targetTextWidgetRef);

			if this.GenerateFurigana(this.m_lineData.text, fontsize)
			{
				// has furigana
				inkTextRef.SetVisible(this.m_targetTextWidgetRef, false);
				//inkTextRef.SetText(this.m_targetTextWidgetRef, this.m_lineData.text);
			}
			else
			{
				// no furigana
				inkTextRef.SetText(this.m_targetTextWidgetRef, this.m_lineData.text);
				//this.PlayLibraryAnimation(n"intro");
			}
		}
	}
}
