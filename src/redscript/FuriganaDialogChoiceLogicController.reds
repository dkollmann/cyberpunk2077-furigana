@replaceMethod(DialogChoiceLogicController)
public final func SetText(value: String, isFailed: Bool) -> Void
{
	LogChannel(n"DEBUG", "DIALOG " + value);

	inkTextRef.SetText(this.m_ActiveTextRef, value);
	inkWidgetRef.SetOpacity(this.m_ActiveTextRef, isFailed ? 1.00 : 1.00);
}

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

	let generator = new FuriganaGenerator();

	while i < count
	{
		currentItem = this.m_itemControllers[i];
		currListChoiceData = this.m_data.choices[i];
		tags = GetCaptionTagsFromArray(currListChoiceData.captionParts.parts);
		localizedText = currListChoiceData.localizedName;

		if Equals(tags, "")
		{
			currentItem.SetText(localizedText, ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.Inactive));
		} else
		{
			currentItem.SetText("[" + tags + "] " + localizedText, ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.Inactive));
		}

		currentItem.SetType(currListChoiceData.type);
		currentItem.SetDedicatedInput(currListChoiceData.inputActionName);
		currentItem.SetIsPhoneLockActive(this.m_data.isPhoneLockActive);
		currentItem.SetDimmed(ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.Inactive) || ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.CheckFailed) || !ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.QuestImportant) && ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.AlreadyRead));
		currentItem.SetSelected(this.m_dialogHubData.m_isSelected && this.m_dialogHubData.m_selectedInd == i);
		currentItem.SetData(this.m_dialogHubData.m_currentNum + i, this.m_dialogHubData.m_argTotalCountAcrossHubs, this.m_dialogHubData.m_hasAboveElements, this.m_dialogHubData.m_hasBelowElements);

		if ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.PossessedDialog)
		{
			isPossessed = true;
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