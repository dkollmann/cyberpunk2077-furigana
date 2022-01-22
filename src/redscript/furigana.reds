/** Generates a list of blocks for the given string.
	The list works as following:
	  n = index % 3
	  n == 0 --> The first character of the block inside the string.
	  n == 1 --> The last character of the block inside the string.
	  n == 2 --> The type of the block. 0 = text, 1 = kanji, 2 = furigana */
private static native func StrSplitFurigana(text: String) -> array<Int16>;

@addMethod(SubtitleLineLogicController)
private func GenerateFurigana(text :String) -> String
{
	let blocks = StrSplitFurigana(text);
	let size = ArraySize(blocks);
	let count = size / 3;

	LogChannel(n"DEBUG", "Furigana: " + ToString(count));

	if count < 1
	{
		return text;
	}

	let outstr = "";

	let i = 0;
	while i < size
	{
		let begin = Cast<Int32>( blocks[i] );
		let end =   Cast<Int32>( blocks[i + 1] );
		let type =  Cast<Int32>( blocks[i + 2] );

		LogChannel(n"DEBUG", "  " + ToString(begin) + "  " + ToString(end) + "  " + ToString(type));

		/*let str =   StrMid(text, begin, end - begin + 1);

		LogChannel(n"DEBUG", str);

		switch type
		{
			case 0:  // text
				outstr += str;
			case 1:  // kanji
				outstr += str;
			case 2:  // furigana
				outstr += ("[" + str + "]");
		}*/

		i += 3;
	}

	//LogChannel(n"DEBUG", "----");

	return outstr;
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
