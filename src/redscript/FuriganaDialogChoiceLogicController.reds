
@replaceMethod(DialogChoiceLogicController)
public final func SetText(value: String, isFailed: Bool) -> Void
{
	LogChannel(n"DEBUG", "DIALOG " + value);

	inkTextRef.SetText(this.m_ActiveTextRef, value);
	inkWidgetRef.SetOpacity(this.m_ActiveTextRef, isFailed ? 1.00 : 1.00);
}
