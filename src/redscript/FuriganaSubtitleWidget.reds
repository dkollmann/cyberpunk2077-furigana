private static native func DebugTextWidget(widget1 :ref<inkText>, widget2 :wref<inkWidget>) -> Void;

private static func Assert(cond :Bool, msg :String) -> Void
{
	if !cond {
		LogChannel(n"DEBUG", "ASSERT: " + msg);
	}
}

private static func Assert(widget :wref<inkWidget>, msg :String) -> Void
{
	if !IsDefined(widget) {
		LogChannel(n"DEBUG", "ASSERT: " + msg);
	}
}

private static func PrintWidgets(widget :wref<inkWidget>, indent :String) -> Void
{
	LogChannel(n"DEBUG", indent + ToString(widget.GetName()) + " : " + ToString(widget.GetClassName()));

	let compound = widget as inkCompoundWidget;

	if IsDefined(compound)
	{
		let count = compound.GetNumChildren();

		let i = 0;
		while i < count
		{
			let w2 = compound.GetWidgetByIndex(i);

			PrintWidgets(w2, indent + " ");

			i += 1;
		}
	}
}

private static func PrintWidgets(widget :inkWidgetRef) -> Void
{
	LogChannel(n"DEBUG", "--------------------");

	let w = inkWidgetRef.Get(widget);

	PrintWidgets(w, "");

	LogChannel(n"DEBUG", "--------------------");
}

public class FuriganaSubtitleWidget
{
	/** This widget is the root of all subtitles being shown. */
	private let subtitlesWidget :ref<inkCompoundWidget>;

	/** The widget the subtitle is supposed to be set on. */
	private let originalWidget: inkTextRef;

	/** This widget is our woot panel we use for our widgets. */
	private let root :ref<inkHorizontalPanel>;
	
	private let furiganaWidgets: array< ref<inkText> >;

	private let furiganaWidgetsHidden: array< ref<inkText> >;

	public func init(ctrl :ref<SubtitleLineLogicController>, orgwidget :inkTextRef) -> ref<FuriganaSubtitleWidget>
	{
		this.root = new inkHorizontalPanel();
		this.root.SetAnchor(inkEAnchor.Fill);
		this.root.SetName(n"furiganaSubtitle");

		this.originalWidget = orgwidget;

		this.subtitlesWidget = ctrl.GetRootWidget() as inkCompoundWidget;
		Assert(this.subtitlesWidget, "Failed to get root widget!!");

		let rootParent = this.subtitlesWidget.GetWidgetByPathName(n"Line/subtitleFlex") as inkCompoundWidget;
		Assert(rootParent, "Failed to get root Line/subtitleFlex!!");
		
		rootParent.AddChildWidget(this.root);

		LogChannel(n"DEBUG", "Added our own root widget...");
		PrintWidgets(this.subtitlesWidget, "");

		return this;
	}

	private func HideAllFuriganaWidgets() -> Void
	{
		this.root.RemoveAllChildren();

		for w in this.furiganaWidgets
		{
			ArrayPush(this.furiganaWidgetsHidden, w);
		}

		ArrayResize(this.furiganaWidgets, 0);  // hopefully this retains the memory
	}

	private func GetFuriganaWidget() -> ref<inkText>
	{
		// use an existing widget
		if ArraySize(this.furiganaWidgetsHidden) > 0
		{
			let w = ArrayPop(this.furiganaWidgetsHidden);

			ArrayPush(this.furiganaWidgets, w);

			return w;
		}

		// create a new widget
		let w = new inkText();

		LogChannel(n"DEBUG", "Create furigana widget: " + ToString(w.GetClassName()));

		w.SetName(n"furiganaTextWidget");
		//w.SetSize(new Vector2(400, 400));
		//w.SetAnchor(inkEAnchor.Fill);
		w.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");  // base\gameplay\gui\fonts\foreign\japanese\smart_font_ui\smart_font_ui.inkfontfamily
		w.SetFontSize(24);
		w.SetFitToContent(true);
		//w.EnableAutoScroll(true);
		//w.SetFitToContent(true);
		//w.SetSizeRule(inkESizeRule.Stretch);

		let w2 = inkTextRef.Get(this.originalWidget);
		DebugTextWidget(w, w2);

		ArrayPush(this.furiganaWidgetsHidden, w);

		return w;
	}

	public func GenerateFuriganaWidgets(text :String, blocks :array<Int16>) -> Void
	{
		// move all widgets to the hidden list
		this.HideAllFuriganaWidgets();

		// add the widgets as needed
		let size = ArraySize(blocks);
		let count = size / 3;

		let wpos = 0.0;
		let wordmargin = 0.0;

		let i = 0;
		while i < size
		{
			let start = Cast<Int32>( blocks[i] );
			let size  = Cast<Int32>( blocks[i + 1] );
			let type  = Cast<Int32>( blocks[i + 2] );

			//LogChannel(n"DEBUG", "  " + ToString(start) + "  " + ToString(size) + "  " + ToString(type));

			let str = StrMid(text, start, size);

			let w = this.GetFuriganaWidget();

			//w.SetTranslation(wpos, 0.0);
			w.SetTextDirect(str);

			this.root.AddChildWidget(w);

			wpos += w.GetWidth() + wordmargin;

			//LogChannel(n"DEBUG", "  POS " + ToString(wpos));

			i += 3;
		}

		LogChannel(n"DEBUG", "Added all the widgets...");
		PrintWidgets(this.subtitlesWidget, "");
	}
}
