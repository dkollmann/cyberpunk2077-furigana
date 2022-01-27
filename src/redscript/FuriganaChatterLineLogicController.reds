@replaceMethod(ChatterLineLogicController)
public func SetLineData(lineData: scnDialogLineData) -> Void
{
	let animCtrl: wref<inkTextKiroshiAnimController>;
	let displayData: scnDialogDisplayString;
	let isWide: Bool;
	let motherTongueCtrl: wref<inkTextMotherTongueController>;
	let gameObject: wref<GameObject> = lineData.speaker;

	if IsDefined(gameObject) && gameObject.IsDevice()
	{
		this.m_rootWidget.SetAnchorPoint(new Vector2(0.50, 0.00));
		this.m_limitSubtitlesDistance = true;
		this.m_subtitlesMaxDistance = 10.00;
	}
	else
	{
		this.m_rootWidget.SetAnchorPoint(new Vector2(0.50, 1.00));
		this.m_limitSubtitlesDistance = false;
		this.m_subtitlesMaxDistance = 0.00;
	}

	this.m_projection.SetEntity(lineData.speaker);
	displayData = scnDialogLineData.GetDisplayText(lineData);
	isWide = StrLen(displayData.translation) >= this.c_ExtraWideTextWidth;
	this.m_ownerId = lineData.speaker.GetEntityID();

	if isWide
	{
		animCtrl = this.m_kiroshiAnimationCtrl_Wide;
		motherTongueCtrl = this.m_motherTongueCtrl_Wide;
	}
	else
	{
		animCtrl = this.m_kiroshiAnimationCtrl_Normal;
		motherTongueCtrl = this.m_motherTongueCtrl_Normal;
	}

	inkWidgetRef.SetVisible(this.m_text_normal, !isWide);
	inkWidgetRef.SetVisible(this.m_text_wide, isWide);
	inkWidgetRef.SetVisible(this.m_container_normal, !isWide);
	inkWidgetRef.SetVisible(this.m_container_wide, isWide);
	inkWidgetRef.SetVisible(this.m_TextContainer, false);
	inkWidgetRef.SetVisible(this.m_speachBubble, true);

	let generator = new FuriganaGenerator().init(FuriganaGeneratorMode.Chatter);
	let fontsize = inkTextRef.GetFontSize(this.m_text_normal);
	fontsize = Cast<Int32>( Cast<Float>(fontsize) * generator.settings.chatterTextScale );

	if scnDialogLineData.HasKiroshiTag(lineData)
	{
		displayData = scnDialogLineData.GetDisplayText(lineData);
		if this.IsKiroshiEnabled()
		{
			animCtrl.SetPreTranslatedText(displayData.preTranslatedText);
			animCtrl.SetNativeText(displayData.text, displayData.language);
			animCtrl.SetTargetText(displayData.translation);
			animCtrl.SetPostTranslatedText(displayData.postTranslatedText);
			this.SetupAnimation(lineData.duration, animCtrl);
			animCtrl.PlaySetAnimation();
		}
		else
		{
			motherTongueCtrl.SetPreTranslatedText("");
			motherTongueCtrl.SetNativeText(displayData.text, displayData.language);
			motherTongueCtrl.SetTranslatedText("");
			motherTongueCtrl.SetPostTranslatedText("");
			motherTongueCtrl.ApplyTexts();
		}
	}
	else
	{
		if scnDialogLineData.HasMothertongueTag(lineData)
		{
			displayData = scnDialogLineData.GetDisplayText(lineData);
			motherTongueCtrl.SetPreTranslatedText(displayData.preTranslatedText);
			motherTongueCtrl.SetNativeText(displayData.text, displayData.language);
			motherTongueCtrl.SetTranslatedText(displayData.translation);
			motherTongueCtrl.SetPostTranslatedText(displayData.postTranslatedText);
			motherTongueCtrl.ApplyTexts();
		}
		else
		{
			let root = inkWidgetRef.Get(this.m_TextContainer) as inkCompoundWidget;
			Assert(root, "Failed to get m_TextContainer!!");

			generator.GenerateFurigana(root, lineData.text, CRUIDToUint64(lineData.id), fontsize, false, false);

			inkTextRef.SetVisible(this.m_container_normal, false);
			inkTextRef.SetVisible(this.m_container_wide, false);

			//inkTextRef.SetText(this.m_text_normal, lineData.text);
			//inkTextRef.SetText(this.m_text_wide, lineData.text);
		}
	}
}
