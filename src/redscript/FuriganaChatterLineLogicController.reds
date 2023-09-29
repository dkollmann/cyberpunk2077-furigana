@replaceMethod(ChatterLineLogicController)
public func SetLineData(const lineData: script_ref<scnDialogLineData>) -> Void
{
	let displayData: scnDialogDisplayString;
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
	displayData = scnDialogLineData.GetDisplayText(Deref(lineData));
	this.m_ownerId = lineData.speaker.GetEntityID();

	inkWidgetRef.SetVisible(this.m_TextContainer, true);
	inkWidgetRef.SetVisible(this.m_speachBubble, true);

	let generator = new FuriganaGenerator().init(FuriganaGeneratorMode.Chatter);
	let fontsize = inkTextRef.GetFontSize(this.m_text_normal);
	fontsize = Cast<Int32>( Cast<Float>(fontsize) * generator.settings.chatterTextScale );

	let kiroshi = scnDialogLineData.HasKiroshiTag(Deref(lineData));
	if kiroshi && !this.IsKiroshiEnabled()
	{
		let isWide = StrLen(displayData.translation) >= this.c_ExtraWideTextWidth;
		let motherTongueCtrl = isWide ?  this.m_motherTongueCtrl_Wide : this.m_motherTongueCtrl_Normal;

		inkWidgetRef.SetVisible(this.m_text_normal, !isWide);
		inkWidgetRef.SetVisible(this.m_text_wide, isWide);
		inkWidgetRef.SetVisible(this.m_container_normal, !isWide);
		inkWidgetRef.SetVisible(this.m_container_wide, isWide);

		motherTongueCtrl.SetPreTranslatedText("");
		motherTongueCtrl.SetNativeText(displayData.text, displayData.language);
		motherTongueCtrl.SetTranslatedText("");
		motherTongueCtrl.SetPostTranslatedText("");
		motherTongueCtrl.ApplyTexts();
	}
	else
	{
		inkWidgetRef.SetVisible(this.m_text_normal, false);
		inkWidgetRef.SetVisible(this.m_text_wide,false);
		inkWidgetRef.SetVisible(this.m_container_normal, false);
		inkWidgetRef.SetVisible(this.m_container_wide, false);

		let root = inkWidgetRef.Get(this.m_TextContainer) as inkCompoundWidget;
		Assert(root, "Failed to get m_TextContainer!!");

		if kiroshi || scnDialogLineData.HasMothertongueTag(Deref(lineData))
		{
			generator.GenerateFurigana(root, displayData.translation, displayData.text, lineData.duration, CRUIDToUint64(lineData.id), fontsize, false, false, GenerateFuriganaTextType.Default);
		}
		else
		{
			generator.GenerateFurigana(root, lineData.text, "", lineData.duration, CRUIDToUint64(lineData.id), fontsize, false, false, GenerateFuriganaTextType.Default);
		}

		inkTextRef.SetVisible(this.m_container_normal, false);
		inkTextRef.SetVisible(this.m_container_wide, false);
	}
}
