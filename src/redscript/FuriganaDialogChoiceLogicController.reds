@addField(DialogChoiceLogicController)
public let backgroundOpacity :Float;

@replaceMethod(DialogChoiceLogicController)
public final func SetDimmed(value: Bool) -> Void
{
	let opacity: Float = value ? 0.40 : 1.00;
	inkWidgetRef.SetOpacity(this.m_ActiveTextRef, opacity);
	inkWidgetRef.SetOpacity(this.m_InActiveTextRef, opacity);
	this.m_SelectedBg.SetOpacity(opacity * this.backgroundOpacity);
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

	let fontsize = -1;
	let generator = new FuriganaGenerator().init(FuriganaGeneratorMode.Dialog);

	//PrintWidgets(this.m_mainVert, "");

	while i < count
	{
		currentItem = this.m_itemControllers[i];
		currListChoiceData = this.m_data.choices[i];
		tags = GetCaptionTagsFromArray(currListChoiceData.captionParts.parts);
		localizedText = currListChoiceData.localizedName;

		if StrLen(tags) > 0 {
			localizedText = ("[" + tags + "] ") + localizedText;
		}

		if fontsize < 0 {
			fontsize = inkTextRef.GetFontSize(currentItem.m_ActiveTextRef);
		}

		let textflex = inkWidgetRef.Get(currentItem.m_TextFlexRef) as inkCompoundWidget;
		Assert(textflex, "Failed to get m_TextFlexRef!!");

		let rootParent = textflex.GetWidgetByPathName(n"active_text_wrapper") as inkCompoundWidget;
		Assert(rootParent, "Failed to get root active_text_wrapper!!");

		// generate furigana
		generator.GenerateFurigana(rootParent, localizedText, Cast<Uint64>(0), fontsize,  true, true);

		// make background transparent so the furigana remains readable
		currentItem.backgroundOpacity = generator.settings.dialogBackgroundOpacity;

		inkTextRef.SetVisible(currentItem.m_ActiveTextRef, false);

		/*if Equals(tags, "")
		{
			currentItem.SetText(localizedText, ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.Inactive));
		} else
		{
			currentItem.SetText("[" + tags + "] " + localizedText, ChoiceTypeWrapper.IsType(currListChoiceData.type, gameinteractionsChoiceType.Inactive));
		}*/

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
