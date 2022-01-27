/** Adds unnecessary spaces after . and , to make subtitles easier to read. */
private static native func StrAddSpaces(text: String) -> String;

/** Generates a list of blocks for the given string.
	The list works as following:
	  n = index % 3
	  n == 0 --> The first byte of the block, inside the string.
	  n == 1 --> The size of the block in bytes, inside the string.
	  n == 2 --> The type of the block. 0 = text, 1 = kanji, 2 = furigana, 3 = katakana */
private static native func StrSplitFurigana(text: String, splitKatakana :Bool) -> array<Int16>;

/** Removes all furigana from a given string. */
private static native func StrStripFurigana(text: String) -> String;

/** Determine the last word in the string before "end". */
private static native func StrFindLastWord(text: String, end :Int32) -> Int32;

/** Counts the number of actual utf-8 characters in the string. */
private static native func UnicodeStringLen(text: String) -> Int32;

/** Gets the id from a CRUID and returns it. */
private static native func CRUIDToUint64(id :CRUID) -> Uint64;

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

/** The settings object. Must be in sync with the lua script. */
public class FuriganaSettings
{
  public let enabled: Bool;
  public let colorizeKanji :Int32;
  public let colorizeKatakana :Bool;
  public let addSpaces :Bool;
  public let showFurigana :Bool;
  public let furiganaScale :Float;
  public let maxLineLength :Int32;
  public let showLineIDs :Bool;
  public let dialogBackgroundOpacity :Float;

  public func Get() -> Void {}
}

public class FuriganaGenerator
{
	/** The settings. */
	public let settings :ref<FuriganaSettings>;

	/** This widget is our root panel we use for our widgets. */
	private let furiganaroot :ref<inkCompoundWidget>;

	/** The widgets represent one line of our subtitles. */
	private let furiganalines :array< ref<inkHorizontalPanel> >;

	public func init() -> ref<FuriganaGenerator>
	{
		this.settings = new FuriganaSettings();
		this.settings.Get();

		return this;
	}

	private func CreateRootWidget(parent :ref<inkCompoundWidget>, singleline :Bool, checkForExisting :Bool) -> Void
	{
		if checkForExisting
		{
			let root = parent.GetWidgetByPathName(n"furiganaSubtitle") as inkCompoundWidget;

			if IsDefined(root) {
				root.RemoveAllChildren();

				this.furiganaroot = root;
				return;
			}
		}

		this.furiganaroot = singleline ? new inkHorizontalPanel() : new inkVerticalPanel();
		this.furiganaroot.SetName(n"furiganaSubtitle");
		this.furiganaroot.SetFitToContent(true);
		this.furiganaroot.SetHAlign(inkEHorizontalAlign.Left);
		this.furiganaroot.SetVAlign(inkEVerticalAlign.Top);
		this.furiganaroot.Reparent(parent);
	}

	private func CreateNewLineWidget() -> ref<inkHorizontalPanel>
	{
		let newline = new inkHorizontalPanel();
		newline.SetName(n"furiganaSubtitleLine");
		newline.SetFitToContent(true);
		newline.SetHAlign(inkEHorizontalAlign.Left);
		newline.SetVAlign(inkEVerticalAlign.Bottom);
		newline.SetMargin(0.0, 0.0, 0.0, 10.0);
		newline.Reparent(this.furiganaroot);

		ArrayPush(this.furiganalines, newline);

		return newline;
	}

	private func AddTextWidget(text :String, parent :ref<inkCompoundWidget>, fontsize :Int32, color :Color) -> Void
	{
		let w = new inkText();
		w.SetName(n"furiganaTextWidget");
		w.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");
		w.SetTintColor(color);
		w.SetFontSize(fontsize);
		w.SetFitToContent(true);
		w.SetHAlign(inkEHorizontalAlign.Left);
		w.SetVAlign(inkEVerticalAlign.Bottom);
		w.SetText(text);
		w.Reparent(parent);
	}

	private func AddKanjiWidget(kanji :String, parent :ref<inkCompoundWidget>, fontsize :Int32, color :Color) -> Void
	{
		let wk = new inkText();
		wk.SetName(n"kanjiText");
		wk.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");
		wk.SetTintColor(color);
		wk.SetFontSize(fontsize);
		wk.SetFitToContent(true);
		wk.SetHAlign(inkEHorizontalAlign.Center);
		wk.SetVAlign(inkEVerticalAlign.Bottom);
		wk.SetText(kanji);
		wk.Reparent(parent);
	}

	private func AddKanjiWithFuriganaWidgets(kanji :String, furigana :String, parent :ref<inkCompoundWidget>, fontsize :Int32, furiganascale :Float, color :Color) -> Void
	{
		let furiganasize = Cast<Int32>( Cast<Float>(fontsize) * furiganascale );

		let panel = new inkVerticalPanel();
		panel.SetName(n"furiganaKH");
		panel.SetFitToContent(true);
		panel.SetHAlign(inkEHorizontalAlign.Left);
		panel.SetVAlign(inkEVerticalAlign.Bottom);
		panel.SetMargin(1.0, 0.0, 1.0, 0.0);
		panel.Reparent(parent);

		let wf = new inkText();
		wf.SetName(n"furiganaText");
		wf.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");
		wf.SetTintColor(color);
		wf.SetFontSize(furiganasize);
		wf.SetFitToContent(true);
		wf.SetHAlign(inkEHorizontalAlign.Center);
		wf.SetVAlign(inkEVerticalAlign.Bottom);
		wf.SetText(furigana);
		wf.SetMargin(0.0, 0.0, 0.0, 1.0);
		wf.Reparent(panel);

		this.AddKanjiWidget(kanji, panel, fontsize, color);
	}

	private func GenerateFuriganaWidgets(parent :ref<inkCompoundWidget>, text :String, lineid :Uint64, blocks :array<Int16>, fontsize :Int32, singleline :Bool, checkForExisting :Bool) -> Void
	{
		// create the root for all our lines
		this.CreateRootWidget(parent, singleline, checkForExisting);

		// add the widgets as needed
		let size = ArraySize(blocks);
		let count = size / 3;

		let textcolor = new Color(Cast<Uint8>(93), Cast<Uint8>(245), Cast<Uint8>(255), Cast<Uint8>(255));
		let katakanacolor = new Color(Cast<Uint8>(93), Cast<Uint8>(210), Cast<Uint8>(255), Cast<Uint8>(255));
		let furiganacolor1 = new Color(Cast<Uint8>(214), Cast<Uint8>(180), Cast<Uint8>(133), Cast<Uint8>(255));
		let furiganacolor2 = new Color(Cast<Uint8>(191), Cast<Uint8>(215), Cast<Uint8>(132), Cast<Uint8>(255));
		let furiganaclridx = 0;

		// add debug info
		if this.settings.showLineIDs && lineid > Cast<Uint64>(0)
		{
			let id = ToString(lineid);

			LogChannel(n"DEBUG", "Line: " + id);

			let w = new inkText();
			w.SetName(n"lineid");
			w.SetFontFamily("base\\gameplay\\gui\\fonts\\foreign\\japanese\\mgenplus\\mgenplus.inkfontfamily", n"Medium");
			w.SetFontSize(20);
			w.SetFitToContent(true);
			//w.SetHAlign(inkEHorizontalAlign.Center);
			//w.SetVAlign(inkEVerticalAlign.Bottom);
			w.SetText(id);
			w.Reparent(this.furiganaroot);
		}

		// limit length
		let maxlinelength = this.settings.maxLineLength;

		let linewidget = singleline ? this.furiganaroot : this.CreateNewLineWidget();

		// generate the widgets
		let currcharlen = 0;
		let i = 0;
		while i < size
		{
			let start = Cast<Int32>( blocks[i] );
			let size  = Cast<Int32>( blocks[i + 1] );
			let type  = Cast<Int32>( blocks[i + 2] );

			let str = StrMid(text, start, size);
			let count = UnicodeStringLen(str);

			// handle normal text and katakana
			if type == 0 || type == 3
			{
				let clr :Color;
				if type == 0 {
					clr = textcolor;
				} else {
					clr = katakanacolor;
				}

				// limit the length, but not for katakana
				if type == 0 && !singleline && currcharlen + count > maxlinelength
				{
					// try to find a word
					let remains = maxlinelength - currcharlen;
					let word = StrFindLastWord(str, remains);

					if word >= 0
					{
						// we found a word to split
						let str1 = StrMid(str, 0, word);

						this.AddTextWidget(str1, linewidget, fontsize, clr);

						// we need a new root for the next line
						linewidget = this.CreateNewLineWidget();

						// the next line takes the rest
						str = StrMid(str, word);
						currcharlen = 0;
					}
					else
					{
						// no word found to split so simply add the text as usual
					}
				}

				this.AddTextWidget(str, linewidget, fontsize, clr);
			}
			else
			{
				// handle kanji
				if type == 1
				{
					i += 3;

					let clr :Color;
					if this.settings.colorizeKanji == 0
					{
						clr = textcolor;
					}
					else
					{
						if furiganaclridx == 0 {
							clr = furiganacolor1;
						} else {
							clr = furiganacolor2;
						}

						if this.settings.colorizeKanji == 2
						{
							// switch colors around
							furiganaclridx = (furiganaclridx + 1) % 2;
						}
					}

					if this.settings.showFurigana
					{
						let fstart = Cast<Int32>( blocks[i] );
						let fsize  = Cast<Int32>( blocks[i + 1] );
						let ftype  = Cast<Int32>( blocks[i + 2] );

						Assert(ftype == 2, "Expected furigana type!");

						let furigana = StrMid(text, fstart, fsize);

						this.AddKanjiWithFuriganaWidgets(str, furigana, linewidget, fontsize, this.settings.furiganaScale, clr);
					}
					else
					{
						this.AddKanjiWidget(str, linewidget, fontsize, clr);
					}
				}
				else
				{
					// we should not encounter "lonely" furigana
					LogChannel(n"DEBUG", "Found furigana not connected with any kanji.");
				}
			}

			currcharlen += count;

			i += 3;
		}
	}

	public func GenerateFurigana(parent :ref<inkCompoundWidget>, text :String, lineid :Uint64, fontsize :Int32, singleline :Bool, checkForExisting :Bool) -> String
	{
		/*LogChannel(n"DEBUG", "Settings:");
		LogChannel(n"DEBUG", "  enabled: " + ToString(settings.enabled));
		LogChannel(n"DEBUG", "  colorizeKanji: " + ToString(settings.colorizeKanji));
		LogChannel(n"DEBUG", "  colorizeKatakana: " + ToString(settings.colorizeKatakana));
		LogChannel(n"DEBUG", "  addSpaces: " + ToString(settings.addSpaces));*/

		if !this.settings.enabled {
			return StrStripFurigana(text);
		}

		if this.settings.addSpaces {
			text = StrAddSpaces(text);
		}

		let blocks = StrSplitFurigana(text, this.settings.colorizeKatakana);
		let size = ArraySize(blocks);
		let count = size / 3;

		if count < 1
		{
			return text;
		}

		this.GenerateFuriganaWidgets(parent, text, lineid, blocks, fontsize, singleline, checkForExisting);

		return "";
	}
}
