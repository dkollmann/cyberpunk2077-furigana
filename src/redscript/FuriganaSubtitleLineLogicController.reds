/** Adds unnecessary spaces after . and , to make subtitles easier to read. */
private static native func StrAddSpaces(text: String) -> String;

/** Generates a list of blocks for the given string.
	The list works as following:
	  n = index % 3
	  n == 0 --> The first byte of the block, inside the string.
	  n == 1 --> The size of the block in bytes, inside the string.
	  n == 2 --> The type of the block. 0 = text, 1 = kanji, 2 = furigana, 3 = katakana */
private static native func StrSplitFurigana(text: String, splitKatakana :Bool) -> array<Int16>;

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

/** The settings object. Must be in sync with the lua script. */
public class FuriganaSettings
{
  public let enabled: Bool;
  public let colorizeKanji :Int32;
  public let colorizeKatakana :Bool;
  public let addSpaces :Bool;

  public func Get() -> Void {}
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
	newline.SetVAlign(inkEVerticalAlign.Bottom);
	newline.Reparent(this.furiganaroot);

	ArrayPush(this.furiganalines, newline);

	return newline;
}

private func AddTextWidget(text :String, parent :ref<inkHorizontalPanel>, fontsize :Int32, color :Color) -> Void
{
	let w = new inkText();
	w.SetName(n"furiganaTextWidget");
	w.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");
	w.SetTintColor(color);
	w.SetFontSize(fontsize);
	w.SetFitToContent(true);
	w.SetHAlign(inkEHorizontalAlign.Left);
	w.SetVAlign(inkEVerticalAlign.Bottom);
	w.SetText(text);
	w.SetMargin(0.0, 0.0, 0.0, 10.0);
	w.SetVerticalAlignment(textVerticalAlignment.Bottom);
	w.Reparent(parent);
}

private func AddKanjiWithFuriganaWidgets(kanji :String, furigana :String, parent :ref<inkHorizontalPanel>, fontsize :Int32, color :Color) -> Void
{
	let furiganasize = Cast<Int32>( Cast<Float>(fontsize) * 0.6 );

	let panel = new inkVerticalPanel();
	panel.SetName(n"furiganaKH");
	panel.SetFitToContent(true);
	panel.SetHAlign(inkEHorizontalAlign.Left);
	panel.SetVAlign(inkEVerticalAlign.Bottom);
	panel.SetMargin(1.0, 0.0, 1.0, 0.0);
	panel.Reparent(parent);

	let wf = new inkText();
	wf.SetName(n"furiganaText");
	wf.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");
	wf.SetTintColor(color);
	wf.SetFontSize(furiganasize);
	wf.SetFitToContent(true);
	wf.SetHAlign(inkEHorizontalAlign.Center);
	wf.SetVAlign(inkEVerticalAlign.Bottom);
	wf.SetText(furigana);
	wf.Reparent(panel);

	let wk = new inkText();
	wk.SetName(n"kanjiText");
	wk.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");
	wk.SetTintColor(color);
	wk.SetFontSize(fontsize);
	wk.SetFitToContent(true);
	wk.SetHAlign(inkEHorizontalAlign.Center);
	wk.SetVAlign(inkEVerticalAlign.Bottom);
	wk.SetText(kanji);
	wk.Reparent(panel);
}

@addMethod(SubtitleLineLogicController)
private func GenerateFuriganaWidgets(text :String, blocks :array<Int16>, fontsize :Int32, settings :ref<FuriganaSettings>) -> Void
{
	// create the root for all our lines
	this.CreateRootWidget();

	// add the widgets as needed
	let size = ArraySize(blocks);
	let count = size / 3;

	let textcolor = new Color(Cast<Uint8>(93), Cast<Uint8>(245), Cast<Uint8>(255), Cast<Uint8>(255));
	let katakanacolor = new Color(Cast<Uint8>(93), Cast<Uint8>(210), Cast<Uint8>(255), Cast<Uint8>(255));
	let furiganacolor1 = new Color(Cast<Uint8>(214), Cast<Uint8>(180), Cast<Uint8>(133), Cast<Uint8>(255));
	let furiganacolor2 = new Color(Cast<Uint8>(191), Cast<Uint8>(215), Cast<Uint8>(132), Cast<Uint8>(255));
	let furiganaclridx = 0;

	// limit length
	let maxlinelength = 50;

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

		// handle normal text and katakana
		if type == 0 || type == 3
		{
			let clr :Color;
			if type == 0 {
				clr = textcolor;
			} else {
				clr = katakanacolor;
			}

			// limit the length, but not for katakana
			if type == 0 && currcharlen + count > maxlinelength
			{
				// try to find a word
				let remains = maxlinelength - currcharlen;
				let word = StrFindLastWord(str, remains);

				if word >= 0
				{
					// we found a word to split
					let str1 = StrMid(str, 0, word);

					AddTextWidget(str1, linewidget, fontsize, clr);

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

			AddTextWidget(str, linewidget, fontsize, clr);
		}
		else
		{
			// handle kanji
			if type == 1
			{
				i += 3;

				let fstart = Cast<Int32>( blocks[i] );
				let fsize  = Cast<Int32>( blocks[i + 1] );
				let ftype  = Cast<Int32>( blocks[i + 2] );

				Assert(ftype == 2, "Expected furigana type!");

				let furigana = StrMid(text, fstart, fsize);

				let clr :Color;
				if settings.colorizeKanji == 0
				{
					clr = textcolor;
				}
				else
				{
					if furiganaclridx == 0 {
						clr = furiganacolor1;
					} else {
						clr = furiganacolor2;
					}

					if settings.colorizeKanji == 2
					{
						// switch colors around
						furiganaclridx = (furiganaclridx + 1) % 2;
					}
				}

				AddKanjiWithFuriganaWidgets(str, furigana, linewidget, fontsize, clr);
			}
			else
			{
				// we should not encounter "lonely" furigana
				LogChannel(n"DEBUG", "Found furigana not connected with any kanji.");
			}
		}

		currcharlen += count;

		i += 3;
	}
}

@addMethod(SubtitleLineLogicController)
private func GenerateFurigana(text :String, fontsize :Int32) -> String
{
	// get settings
	let settings = new FuriganaSettings();
	settings.Get();

	/*LogChannel(n"DEBUG", "Settings:");
	LogChannel(n"DEBUG", "  enabled: " + ToString(settings.enabled));
	LogChannel(n"DEBUG", "  colorizeKanji: " + ToString(settings.colorizeKanji));
	LogChannel(n"DEBUG", "  colorizeKatakana: " + ToString(settings.colorizeKatakana));
	LogChannel(n"DEBUG", "  addSpaces: " + ToString(settings.addSpaces));*/

	if !settings.enabled {
		return StrStripFurigana(text);
	}

	if settings.addSpaces {
		text = StrAddSpaces(text);
	}

	let blocks = StrSplitFurigana(text, settings.colorizeKatakana);
	let size = ArraySize(blocks);
	let count = size / 3;

	if count < 1
	{
		return text;
	}

	this.GenerateFuriganaWidgets(text, blocks, fontsize, settings);

	return "";
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
			let text = this.GenerateFurigana(this.m_lineData.text, fontsize);

			if StrLen(text) < 1
			{
				// has furigana
				inkTextRef.SetVisible(this.m_targetTextWidgetRef, false);
				//inkTextRef.SetText(this.m_targetTextWidgetRef, this.m_lineData.text);
			}
			else
			{
				// no furigana
				inkTextRef.SetText(this.m_targetTextWidgetRef, text);
				//this.PlayLibraryAnimation(n"intro");
			}
		}
	}
}
