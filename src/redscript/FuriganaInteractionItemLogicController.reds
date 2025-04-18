@replaceMethod(interactionItemLogicController)
private final func SetLabel(data: script_ref<InteractionChoiceData>, isItemBroken : Bool) -> Void
{
	let action: ref<DeviceAction>;
	let deviceAction: ref<ScriptableDeviceAction>;
	let textParams: ref<inkTextParams>;
	let locText: String = GetLocalizedText( ( ( isItemBroken ) ? ( "LocKey#6887" ) : ( data.localizedName ) ) );
	let captionTags: String = GetCaptionTagsFromArray(Deref(data).captionParts.parts);

	if NotEquals(captionTags, "")
	{
		locText = captionTags + " " + locText;
	}

	if ArraySize(Deref(data).data) > 0
	{
		action = FromVariant<ref<DeviceAction>>(Deref(data).data[0]);
		deviceAction = action as ScriptableDeviceAction;
	}

	let rootParent = this.m_RootWidget.GetWidgetByPathName(n"text_holder") as inkCompoundWidget;
	Assert(rootParent, "Failed to get root text_holder!!");

	let generator = new FuriganaGenerator().init(FuriganaGeneratorMode.Interaction);

	let inactive = IsDefined(deviceAction) && deviceAction.IsInactive() && NotEquals(deviceAction.GetInactiveReason(), "");
	
	if StrOnlyLatin(locText)
	{
		// clear any previously generated furigana
		generator.GetRootWidget(rootParent, true);
		
		if inactive
		{
			textParams = new inkTextParams();
			textParams.AddString("ACTION", locText);
			textParams.AddLocalizedString("ADDITIONALINFO", deviceAction.GetInactiveReason());
			inkTextRef.SetLocalizedTextScript(this.m_label, "LocKey#42173", textParams);
			inkTextRef.SetLocalizedTextScript(this.m_labelFail, "LocKey#42173", textParams);
		}
		else
		{
			inkTextRef.SetText(this.m_label, locText);
			inkTextRef.SetText(this.m_labelFail, locText);
		}

		inkTextRef.SetVisible(this.m_label, true);
		inkTextRef.SetVisible(this.m_labelFail, true);

		return;
	}

	if inactive
	{
		locText += " (" + deviceAction.GetInactiveReason() + ")";
	}
	
	// generate furigana
	let fontsize = inkTextRef.GetFontSize(this.m_label);

	generator.GenerateFurigana(rootParent, locText, "", 0.0, Cast<Uint64>(0), fontsize, true, true, GenerateFuriganaTextType.Default);

	/*generator.furiganaroot.SetHAlign(inkEHorizontalAlign.Center);
	generator.furiganaroot.SetMargin(150.0, 0.0, 0.0, 0.0);

	// adjust fail size
	let failSize = rootParent.GetWidgetByPathName(n"Fail_panel/Canvas_fail_flex/inputLabel");
	Assert(failSize, "Failed to get root text_holder/Fail_panel/Canvas_fail_flex/inputLabel!!");

	failSize.SetFitToContent(false);
	failSize.SetWidth(400);*/

	inkTextRef.SetVisible(this.m_label, false);
	inkTextRef.SetVisible(this.m_labelFail, false);
}

@replaceMethod(interactionItemLogicController)
public final func SetData(data: script_ref<InteractionChoiceData>, opt skillCheck: UIInteractionSkillCheck, opt isItemBroken : Bool) -> Void
{
	let iconID: TweakDBID;
	let skillReqParams: ref<inkTextParams>;
	let keyData: inkInputKeyData = new inkInputKeyData();

	inkInputKeyData.SetInputKey(keyData, Deref(data).rawInputKey);
	this.m_inputDisplayController.SetInputAction(Deref(data).inputAction);
	inkWidgetRef.SetVisible(this.m_skillCheck, skillCheck.isValid);

	if skillCheck.isValid
	{
		skillReqParams = new inkTextParams();
		if Equals(skillCheck.skillCheck, EDeviceChallengeSkill.Hacking)
		{
			iconID = t"ChoiceIcons.HackingIcon";
			skillReqParams.AddLocalizedString("NAME", "LocKey#22278");
		}
		else
		{
			if Equals(skillCheck.skillCheck, EDeviceChallengeSkill.Engineering)
			{
				iconID = t"ChoiceIcons.EngineeringIcon";
				skillReqParams.AddLocalizedString("NAME", "LocKey#22276");
			}
			else
			{
				iconID = t"ChoiceIcons.AthleticsIcon";
				skillReqParams.AddLocalizedString("NAME", "LocKey#22271");
			}
		}

		if skillCheck.isPassed
		{
			skillReqParams.AddNumber("REQUIRED_SKILL", skillCheck.requiredSkill);
			inkTextRef.SetLocalizedTextScript(this.m_skillCheckText, "LocKey#49423", skillReqParams);
		}
		else
		{
			skillReqParams.AddNumber("PLAYER_SKILL", skillCheck.playerSkill);
			skillReqParams.AddNumber("REQUIRED_SKILL", skillCheck.requiredSkill);
			inkTextRef.SetLocalizedTextScript(this.m_skillCheckText, "LocKey#49421", skillReqParams);
		}

		this.SetTexture(this.m_skillCheckIcon, iconID);

		//inkWidgetRef.SetVisible(this.m_label, skillCheck.isPassed);
		//inkWidgetRef.SetVisible(this.m_labelFail, !skillCheck.isPassed);
		inkWidgetRef.SetVisible(this.m_SkillCheckPassBG, skillCheck.isPassed);
		inkWidgetRef.SetVisible(this.m_SkillCheckFailBG, !skillCheck.isPassed);
		inkWidgetRef.SetVisible(this.m_skillCheckNormalReqs, skillCheck.isPassed || !skillCheck.hasAdditionalRequirements);
		inkWidgetRef.SetVisible(this.m_additionalReqsNeeded, !skillCheck.isPassed && skillCheck.hasAdditionalRequirements);
	}

	this.SetLabel(data, isItemBroken);

	if ArraySize(Deref(data).captionParts.parts) > 0
	{
		this.EmptyCaptionParts();
		this.SetCaptionParts(Deref(data).captionParts.parts);
	}
	else
	{
		this.EmptyCaptionParts();
	}

	if ChoiceTypeWrapper.IsType(Deref(data).type, gameinteractionsChoiceType.Illegal)
	{
		inkWidgetRef.SetVisible(this.m_QHIllegalIndicator, true);

		if ArraySize(Deref(data).captionParts.parts) == 0 
		{
			inkWidgetRef.SetVisible(this.m_SCIllegalIndicator, false);
		}
	}
	else
	{
		inkWidgetRef.SetVisible(this.m_QHIllegalIndicator, false);
		inkWidgetRef.SetVisible(this.m_SCIllegalIndicator, false);
	}

	if ChoiceTypeWrapper.IsType(Deref(data).type, gameinteractionsChoiceType.Inactive) || ChoiceTypeWrapper.IsType(Deref(data).type, gameinteractionsChoiceType.CheckFailed)
	{
		this.m_RootWidget.SetState(n"Inactive");

		inkWidgetRef.SetVisible(this.m_SkillCheckPassBG, false);
		inkWidgetRef.SetVisible(this.m_SkillCheckFailBG, true);
		//inkWidgetRef.SetVisible(this.m_label, false);
		//inkWidgetRef.SetVisible(this.m_labelFail, true);
	}
	else
	{
		this.m_RootWidget.SetState(n"Active");
		
		inkWidgetRef.SetVisible(this.m_SkillCheckPassBG, true);
		inkWidgetRef.SetVisible(this.m_SkillCheckFailBG, false);
		//inkWidgetRef.SetVisible(this.m_label, true);
		//inkWidgetRef.SetVisible(this.m_labelFail, false);
	}

	if ChoiceTypeWrapper.IsType(Deref(data).type, gameinteractionsChoiceType.Selected) && !this.m_isSelected
	{
		this.PlayAnim(n"Select");
	}
}
