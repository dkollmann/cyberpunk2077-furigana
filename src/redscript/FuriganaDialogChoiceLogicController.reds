@replaceMethod(DialogHubLogicController)
private final func UpdateDialogHubData() -> Void
{
	let currListChoiceData: ListChoiceData;
	let currentItem: wref<DialogChoiceLogicController>;
	let localizedText: String;
	let tags: String;
	let timedDuration: Float;
	let timedProgress: Float;
	let isPossessed: Bool = false;
	let isTimed: Bool = false;
	let count: Int32 = ArraySize(this.m_data.choices);
	let i: Int32 = 0;

	let fontsize = -1;
	let generator = new FuriganaGenerator().init(FuriganaGeneratorMode.Dialog);

	while i < count
	{
		currentItem = this.m_itemControllers[i];
		currListChoiceData = this.m_data.choices[i];
		tags = GetCaptionTagsFromArray(currListChoiceData.captionParts.parts);
		localizedText = currListChoiceData.localizedName;

		if Equals(tags, "") && StrBeginsWith(localizedText, "[")
		{
			if StrSplitFirst(localizedText, "]", tags, localizedText)
			{
				tags = StrFrontToUpper(StrAfterFirst(tags, "["));
				if StrBeginsWith(localizedText, " ")
				{
					localizedText = StrAfterFirst(localizedText, " ");
				}
			}
		}

		if fontsize < 0 {
			fontsize = inkTextRef.GetFontSize(currentItem.m_ActiveTextRef);
		}

		let textflex = inkWidgetRef.Get(currentItem.m_TextFlexRef) as inkCompoundWidget;
		Assert(textflex, "Failed to get m_TextFlexRef!!");

		let rootParent = textflex.GetWidgetByPathName(n"active_text_wrapper") as inkCompoundWidget;
		Assert(rootParent, "Failed to get root active_text_wrapper!!");

		let selected = this.m_dialogHubData.m_isSelected && this.m_dialogHubData.m_selectedInd == i;
		let dimmed = ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.Inactive) || ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.CheckFailed) || !ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.QuestImportant) && ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.AlreadyRead);

		let textType = GenerateFuriganaTextType.Default;
		if selected {
			textType = GenerateFuriganaTextType.Selected;
		} else {
			if dimmed {
				textType = GenerateFuriganaTextType.Dimmed;
			}
		}

		// generate furigana
		generator.GenerateFurigana(rootParent, localizedText, "", 0.0, Cast<Uint64>(0), fontsize, true, true, textType);

		let hasTags = NotEquals(tags, "");

		inkTextRef.SetText(currentItem.m_tagTextRef, tags);
		inkWidgetRef.SetVisible(currentItem.m_tagTextRef, hasTags);
		inkWidgetRef.SetVisible(currentItem.m_tagSeparator, hasTags);
		inkTextRef.SetVisible(currentItem.m_ActiveTextRef, false);

		currentItem.SetType(currListChoiceData.type);
		currentItem.SetDedicatedInput(currListChoiceData.inputActionName);
		currentItem.SetIsPhoneLockActive(this.m_data.isPhoneLockActive);
		currentItem.SetDimmed(dimmed);
		currentItem.SetSelected(selected);
		currentItem.SetData(this.m_dialogHubData.m_currentNum + i, this.m_dialogHubData.m_argTotalCountAcrossHubs, this.m_dialogHubData.m_hasAboveElements, this.m_dialogHubData.m_hasBelowElements);
		currentItem.SetVisible(true);

		if ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.PossessedDialog)
		{
			isPossessed = true;
		}

		if ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.Glowline)
		{
			currentItem.SetGlowline();
		}

		if IsDefined(currListChoiceData.timeProvider)
		{
			isTimed = !this.m_dialogHubData.m_hasAboveElements;
			timedProgress = currListChoiceData.timeProvider.GetCurrentProgress();
			timedDuration = currListChoiceData.timeProvider.GetDuration();
		}

		if IsDefined(this.m_data.timeProvider)
		{
			isTimed = !this.m_dialogHubData.m_hasAboveElements;
			timedProgress = this.m_data.timeProvider.GetCurrentProgress();
			timedDuration = this.m_data.timeProvider.GetDuration();
		}

		currentItem.SetCaptionParts(currListChoiceData.captionParts.parts);
		currentItem.UpdateView();
		currentItem.AnimateSelection();

		if !this.m_dialogHubData.m_isSelected
		{
			currentItem.SetSelected(false);
		}

		i += 1;
	}

	this.SetupTimeBar(isTimed, timedDuration, timedProgress);
	this.m_rootWidget.SetOpacity(1.00);
	this.SetupTitle(this.m_data.title, this.m_dialogHubData.m_isSelected, isPossessed);
	this.m_isSelected = this.m_dialogHubData.m_isSelected;
	this.m_lastSelectedIdx = this.m_dialogHubData.m_selectedInd;
}
