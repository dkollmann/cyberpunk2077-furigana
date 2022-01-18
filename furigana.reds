@replaceMethod(SubtitleLineLogicController)
public func SetLineData(lineData: scnDialogLineData) -> Void {
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
	if IsStringValid(lineData.speakerName) {
		speakerName = lineData.speakerName;
	} else {
		speakerName = lineData.speaker.GetDisplayName();
	};
	isValidName = IsStringValid(speakerName);
	speakerNameDisplayText = isValidName ? "LocKey#76968" : "";
	if isValidName {
	  this.m_spekerNameParams.UpdateLocalizedString("NAME", speakerName);
	};
	if IsMultiplayer() {
		speakerNameWidgetStateName = n"Default";
		playerPuppet = lineData.speaker as gamePuppetBase;
		if playerPuppet != null {
			characterRecordID = playerPuppet.GetRecordID();
			speakerNameWidgetStateName = TweakDBInterface.GetCharacterRecord(characterRecordID).CpoClassName();
		};
		inkWidgetRef.SetState(this.m_speakerNameWidget, speakerNameWidgetStateName);
	};
	if Equals(lineData.type, scnDialogLineType.Radio) {
		this.m_targetTextWidgetRef = this.m_radioSubtitle;
		inkTextRef.SetLocalizedTextScript(this.m_radioSpeaker, speakerNameDisplayText, this.m_spekerNameParams);
		inkWidgetRef.SetVisible(this.m_speakerNameWidget, false);
		inkWidgetRef.SetVisible(this.m_subtitleWidget, false);
		inkWidgetRef.SetVisible(this.m_radioSpeaker, true);
		inkWidgetRef.SetVisible(this.m_radioSubtitle, true);
	} else {
		if Equals(lineData.type, scnDialogLineType.AlwaysCinematicNoSpeaker) {
			this.m_targetTextWidgetRef = this.m_radioSubtitle;
			inkWidgetRef.SetVisible(this.m_speakerNameWidget, false);
			inkWidgetRef.SetVisible(this.m_subtitleWidget, false);
			inkWidgetRef.SetVisible(this.m_radioSpeaker, false);
			inkWidgetRef.SetVisible(this.m_radioSubtitle, true);
		} else {
			if Equals(lineData.type, scnDialogLineType.GlobalTVAlwaysVisible) {
				this.m_targetTextWidgetRef = this.m_subtitleWidget;
				inkWidgetRef.SetVisible(this.m_speakerNameWidget, false);
				inkWidgetRef.SetVisible(this.m_subtitleWidget, true);
				inkWidgetRef.SetVisible(this.m_radioSpeaker, false);
				inkWidgetRef.SetVisible(this.m_radioSubtitle, false);
			} else {
				this.m_targetTextWidgetRef = this.m_subtitleWidget;
				inkTextRef.SetLocalizedTextScript(this.m_speakerNameWidget, speakerNameDisplayText, this.m_spekerNameParams);
				inkWidgetRef.SetVisible(this.m_speakerNameWidget, true);
				inkWidgetRef.SetVisible(this.m_subtitleWidget, true);
				inkWidgetRef.SetVisible(this.m_radioSpeaker, false);
				inkWidgetRef.SetVisible(this.m_radioSubtitle, false);
			};
		  };
	};
	if scnDialogLineData.HasKiroshiTag(lineData) {
		displayData = scnDialogLineData.GetDisplayText(lineData);
		if this.IsKiroshiEnabled() {
			kiroshiAnimationCtrl = inkWidgetRef.GetController(this.m_kiroshiAnimationContainer) as inkTextKiroshiAnimController;
			kiroshiAnimationCtrl.SetPreTranslatedText(displayData.preTranslatedText);
			kiroshiAnimationCtrl.SetPostTranslatedText(displayData.postTranslatedText);
			kiroshiAnimationCtrl.SetNativeText(displayData.text, displayData.language);
			kiroshiAnimationCtrl.SetTargetText(displayData.translation);
			this.SetupAnimation(this.m_lineData.duration, kiroshiAnimationCtrl);
			kiroshiAnimationCtrl.PlaySetAnimation();
		} else {
			motherTongueCtrl = inkWidgetRef.GetControllerByType(this.m_motherTongueContainter, n"inkTextMotherTongueController") as inkTextMotherTongueController;
			motherTongueCtrl.SetPreTranslatedText("");
			motherTongueCtrl.SetNativeText(displayData.text, displayData.language);
			motherTongueCtrl.SetTranslatedText("");
			motherTongueCtrl.SetPostTranslatedText("");
			motherTongueCtrl.ApplyTexts();
		};
	} else {
		if scnDialogLineData.HasMothertongueTag(lineData) {
			displayData = scnDialogLineData.GetDisplayText(lineData);
			motherTongueCtrl = inkWidgetRef.GetControllerByType(this.m_motherTongueContainter, n"inkTextMotherTongueController") as inkTextMotherTongueController;
			motherTongueCtrl.SetPreTranslatedText(displayData.preTranslatedText);
			motherTongueCtrl.SetNativeText(displayData.text, displayData.language);
			motherTongueCtrl.SetTranslatedText(displayData.translation);
			motherTongueCtrl.SetPostTranslatedText(displayData.postTranslatedText);
			motherTongueCtrl.ApplyTexts();
		} else {
			inkTextRef.SetText(this.m_targetTextWidgetRef, this.m_lineData.text);
			this.PlayLibraryAnimation(n"intro");
		};
	};
}
