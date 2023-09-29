@replaceMethod(SubtitleLineLogicController)
public func SetLineData(const lineData: script_ref<scnDialogLineData>) -> Void
{
	let characterRecordID: TweakDBID;
	let displayData: scnDialogDisplayString;
	let isValidName: Bool;
	let motherTongueCtrl: ref<inkTextMotherTongueController>;
	let playerPuppet: ref<gamePuppetBase>;
	let speakerName: String;
	let speakerNameDisplayText: String;
	let speakerNameWidgetStateName: CName;

	this.m_lineData = Deref(lineData);

	// determine speaker name
	if IsStringValid(Deref(lineData).speakerName)
	{
		speakerName = Deref(lineData).speakerName;
	}
	else
	{
		speakerName = Deref(lineData).speaker.GetDisplayName();
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

		playerPuppet = Deref(lineData).speaker as gamePuppetBase;
		if playerPuppet != null
		{
			characterRecordID = playerPuppet.GetRecordID();
			speakerNameWidgetStateName = TweakDBInterface.GetCharacterRecord(characterRecordID).CpoClassName();
		}

		inkWidgetRef.SetState(this.m_speakerNameWidget, speakerNameWidgetStateName);
	}

	if Equals(Deref(lineData).type, scnDialogLineType.Radio)
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
		if Equals(Deref(lineData).type, scnDialogLineType.AlwaysCinematicNoSpeaker)
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
			if Equals(Deref(lineData).type, scnDialogLineType.GlobalTVAlwaysVisible)
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

	let kiroshi = scnDialogLineData.HasKiroshiTag(Deref(lineData));
	if kiroshi && !this.IsKiroshiEnabled()
	{
		motherTongueCtrl = inkWidgetRef.GetControllerByType(this.m_motherTongueContainter, n"inkTextMotherTongueController") as inkTextMotherTongueController;
		motherTongueCtrl.SetPreTranslatedText("");
		motherTongueCtrl.SetNativeText(displayData.text, displayData.language);
		motherTongueCtrl.SetTranslatedText("");
		motherTongueCtrl.SetPostTranslatedText("");
		motherTongueCtrl.ApplyTexts();
	}
	else
	{
		inkTextRef.SetVisible(this.m_targetTextWidgetRef, false);

		// show normal lines
		let generator = new FuriganaGenerator().init(FuriganaGeneratorMode.Dialog);
		let fontsize = inkTextRef.GetFontSize(this.m_targetTextWidgetRef);

		let subtitlesWidget = this.GetRootWidget() as inkCompoundWidget;
		Assert(subtitlesWidget, "Failed to get root widget!!");

		let rootParent = subtitlesWidget.GetWidgetByPathName(n"Line/subtitleFlex") as inkCompoundWidget;
		Assert(rootParent, "Failed to get root Line/subtitleFlex!!");

		if kiroshi || scnDialogLineData.HasMothertongueTag(Deref(lineData))
		{
			displayData = scnDialogLineData.GetDisplayText(Deref(lineData));

			generator.GenerateFurigana(rootParent, displayData.translation, displayData.text, this.m_lineData.duration, CRUIDToUint64(Deref(lineData).id), fontsize, false, false, GenerateFuriganaTextType.Default);
		}
		else
		{
			generator.GenerateFurigana(rootParent, this.m_lineData.text, "", this.m_lineData.duration, CRUIDToUint64(Deref(lineData).id), fontsize, false, false, GenerateFuriganaTextType.Default);
		}
	}
}
