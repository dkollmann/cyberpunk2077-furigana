public class FuriganaSubtitleWidget
{
	private let root :ref<inkFlex>;
	
	private let furiganaWidgets: array< ref<inkText> >;

	private let furiganaWidgetsHidden: array< ref<inkText> >;

	public func init(ctrl :ref<SubtitleLineLogicController>) -> ref<FuriganaSubtitleWidget>
	{
		this.root = new inkFlex();
		this.root.Reparent( ctrl.GetRootCompoundWidget() );
		return this;
	}

	private func HideAllFuriganaWidgets() -> Void
	{
		for w in this.furiganaWidgets
		{
			w.SetVisible(false);

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
		LogChannel(n"DEBUG", "Create furigana widget");

		let w = new inkText();

		w.SetVisible(false);
		//w.SetSize(new Vector2(400, 400));
		//w.SetAnchor(inkEAnchor.Fill);
		w.SetFitToContent(true);
		w.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");  // base\gameplay\gui\fonts\foreign\japanese\smart_font_ui\smart_font_ui.inkfontfamily
		w.SetFontSize(24);

		w.Reparent(this.root);

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
		let wordmargin = 1.0;

		let i = 0;
		while i < size
		{
			let start = Cast<Int32>( blocks[i] );
			let size  = Cast<Int32>( blocks[i + 1] );
			let type  = Cast<Int32>( blocks[i + 2] );

			LogChannel(n"DEBUG", "  " + ToString(start) + "  " + ToString(size) + "  " + ToString(type));

			let str = StrMid(text, start, size);

			let w = this.GetFuriganaWidget();

			w.SetTranslation(wpos, 0.0);
			w.SetText(str);
			w.SetVisible(true);

			wpos += w.GetWidth() + wordmargin;

			LogChannel(n"DEBUG", "  POS " + ToString(wpos));

			i += 3;
		}
	}
}
