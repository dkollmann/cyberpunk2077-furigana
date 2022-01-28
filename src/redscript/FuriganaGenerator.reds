/** Adds unnecessary spaces after . and , to make subtitles easier to read. */
private static native func StrAddSpaces(text: String) -> String;

enum StrSplitFuriganaIndex
{
    Start = 0,
    Size = 1,
    CharCount = 2,
    Type = 3,
    COUNT = 4
}

enum StrSplitFuriganaType
{
	Text = 0,
	Kanji = 1,
	Furigana = 2,
	Katakana = 3
}

/** Generates a list of blocks for the given string.
	The list works as following:
	  n = index % 4
	  n == 0 --> The first byte of the block, inside the string.
	  n == 1 --> The size of the block in bytes, inside the string.
	  n == 2 --> The number of characters of the block.
	  n == 3 --> The type of the block. 0 = text, 1 = kanji, 2 = furigana, 3 = katakana */
private static native func StrSplitFurigana(text: String, splitKatakana :Bool) -> array<Int16>;

/** Removes all furigana from a given string. */
private static native func StrStripFurigana(text: String) -> String;

/** Determine the last word in the string before "end". */
private static native func StrFindLastWord(text: String, end :Int32) -> Int32;

/** Counts the number of actual utf-8 characters in the string. */
private static native func UnicodeStringLen(text: String) -> Int32;

/** Gets the id from a CRUID and returns it. */
private static native func CRUIDToUint64(id :CRUID) -> Uint64;

/** Open an url in the browser. */
private static native func OpenBrowser(url :String) -> Void;


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

	public let dialogMaxLineLength :Int32;
	public let dialogBackgroundOpacity :Float;

	public let chatterMaxLineLength :Int32;
	public let chatterTextScale :Float;

	public let motherTongueShow :Bool;
	public let motherTongueScale :Float;
	public let motherTongueTransMode :Int32;
	public let motherTongueFadeInTime :Float;

	public let showLineIDs :Bool;
	
	public func Get() -> Void {}
}

enum FuriganaGeneratorMode
{
	Dialog = 0,
	Chatter = 1
}

public class FuriganaGenerator
{
	/** The mode of the generator. */
	public let mode :FuriganaGeneratorMode;

	/** The settings. */
	public let settings :ref<FuriganaSettings>;

	/** The maximum lin length. */
	private let maxLineLength :Int32;

	/** This widget is our root panel we use for our widgets. */
	private let furiganaroot :ref<inkCompoundWidget>;

	/** The widgets represent one line of our subtitles. */
	private let furiganalines :array< ref<inkHorizontalPanel> >;

	public func init(mode :FuriganaGeneratorMode) -> ref<FuriganaGenerator>
	{
		this.mode = mode;
		this.settings = new FuriganaSettings();
		this.settings.Get();

		if Equals(mode, FuriganaGeneratorMode.Dialog) {
			this.maxLineLength = this.settings.dialogMaxLineLength;
		} else {
			this.maxLineLength = this.settings.chatterMaxLineLength;
		}

		return this;
	}

	private func AddFadeInAnimation(widget :ref<inkWidget>, delay :Float, duration :Float) -> Void
	{
		let interp = new inkAnimTransparency();
		interp.SetStartTransparency(0.01);  // higher than zero
		interp.SetEndTransparency(1.0);
		interp.SetStartDelay(delay);
		interp.SetDuration(duration);
		interp.SetType(inkanimInterpolationType.Linear);
		interp.SetMode(inkanimInterpolationMode.EasyIn);

		let anim = new inkAnimDef();
		anim.AddInterpolator(interp);

		widget.PlayAnimation(anim);
	}

	private func AddFadeInAnimation(widget :ref<inkWidget>, currentcount :Int32, length :Int32, totalcount :Int32, totalduration :Float) -> Void
	{
		let f =  totalduration / Cast<Float>(totalcount);
		let delay = Cast<Float>(currentcount) * f;
		let duration = Cast<Float>(length) * f;

		this.AddFadeInAnimation(widget, delay, duration);
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

	private func AddTextWidget(text :String, parent :ref<inkCompoundWidget>, fontsize :Int32, color :Color) -> ref<inkText>
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

		return w;
	}

	private func AddKanjiWidget(kanji :String, parent :ref<inkCompoundWidget>, fontsize :Int32, color :Color) -> ref<inkText>
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

		return wk;
	}

	private func AddKanjiWithFuriganaWidgets(kanji :String, furigana :String, parent :ref<inkCompoundWidget>, fontsize :Int32, furiganascale :Float, color :Color) -> ref<inkVerticalPanel>
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

		return panel;
	}

	private func GenerateFuriganaWidgets(parent :ref<inkCompoundWidget>, japaneseText :String, motherTongueText :String, duration :Float, lineid :Uint64, blocks :array<Int16>, fontsize :Int32, singleline :Bool, checkForExisting :Bool) -> Void
	{
		let IndexStart = EnumInt(StrSplitFuriganaIndex.Start);
		let IndexSize = EnumInt(StrSplitFuriganaIndex.Size);
		let IndexCharCount = EnumInt(StrSplitFuriganaIndex.CharCount);
		let IndexType = EnumInt(StrSplitFuriganaIndex.Type);
		let IndexCOUNT = EnumInt(StrSplitFuriganaIndex.COUNT);

		let TypeText  = EnumInt(StrSplitFuriganaType.Text);
		let TypeKanji = EnumInt(StrSplitFuriganaType.Kanji);
		let TypeFurigana = EnumInt(StrSplitFuriganaType.Furigana);
		let TypeKatakana = EnumInt(StrSplitFuriganaType.Katakana);

		let hasmothertongue = this.settings.motherTongueShow && StrLen(motherTongueText) > 0;

		if hasmothertongue {
			// we do not support mixing these features
			singleline = false;
		}

		let size = ArraySize(blocks);
		let count = size / IndexCOUNT;

		// handle the fade-in
		let fadeinduration = 0.0;
		let totalcharcount = 0;
		if this.settings.motherTongueTransMode == 1 && StrLen(motherTongueText) > 0 {
			// fadein the translated text
			fadeinduration = duration * this.settings.motherTongueFadeInTime;

			let i = 0;
			while i < size
			{
				let type  = Cast<Int32>( blocks[i + IndexType] );

				if type != TypeFurigana
				{
					totalcharcount += Cast<Int32>( blocks[i + IndexCharCount] );
				}

				i += IndexCOUNT;
			}
		}

		// create the root for all our lines
		this.CreateRootWidget(parent, singleline, checkForExisting);

		// add the widgets as needed
		let textcolor = new Color(Cast<Uint8>(93), Cast<Uint8>(245), Cast<Uint8>(255), Cast<Uint8>(255));
		let mothertonguecolor = new Color(Cast<Uint8>(255), Cast<Uint8>(255), Cast<Uint8>(255), Cast<Uint8>(255));
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
			w.SetText(id);
			w.Reparent(this.furiganaroot);
		}

		// add mother tongue text
		if hasmothertongue
		{
			let line = this.CreateNewLineWidget();
			line.SetHAlign(inkEHorizontalAlign.Center);

			let fsize = Cast<Int32>( Cast<Float>(fontsize) * this.settings.motherTongueScale );

			this.AddTextWidget(motherTongueText, line, fsize, mothertonguecolor);
		}

		// limit length
		let maxlinelength = this.maxLineLength;

		let linewidget = singleline ? this.furiganaroot : this.CreateNewLineWidget();

		// generate the widgets
		let currcharlen = 0;
		let currentcharcount = 0;
		let i = 0;
		while i < size
		{
			let start = Cast<Int32>( blocks[i + IndexStart] );
			let size  = Cast<Int32>( blocks[i + IndexSize] );
			let count = Cast<Int32>( blocks[i + IndexCharCount] );
			let type  = Cast<Int32>( blocks[i + IndexType] );

			let str = StrMid(japaneseText, start, size);

			// handle normal text and katakana
			if type == TypeText || type == TypeKatakana
			{
				let clr :Color;
				if type == 0 {
					clr = textcolor;
				} else {
					clr = katakanacolor;
				}

				// limit the length, but not for katakana
				if type == TypeText && !singleline && currcharlen + count > maxlinelength
				{
					// try to find a word
					let remains = maxlinelength - currcharlen;
					let word = StrFindLastWord(str, remains);

					if word >= 0
					{
						// we found a word to split
						let str1 = StrMid(str, 0, word);

						let w = this.AddTextWidget(str1, linewidget, fontsize, clr);
						if fadeinduration > 0.0
						{
							let count1 = UnicodeStringLen(str1);
							this.AddFadeInAnimation(w, currentcharcount, count, totalcharcount, fadeinduration);

							currentcharcount += count1;
						}

						// we need a new root for the next line
						linewidget = this.CreateNewLineWidget();

						// the next line takes the rest
						str = StrMid(str, word);
						currcharlen = 0;

						if fadeinduration > 0.0 {
							count = UnicodeStringLen(str);
						}
					}
					else
					{
						// no word found to split so simply add the text as usual
					}
				}

				let w = this.AddTextWidget(str, linewidget, fontsize, clr);
				if fadeinduration > 0.0
				{
					this.AddFadeInAnimation(w, currentcharcount, count, totalcharcount, fadeinduration);
					currentcharcount += count;
				}
			}
			else
			{
				// handle kanji
				if type == TypeKanji
				{
					i += IndexCOUNT;

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

					let w :ref<inkWidget>;

					if this.settings.showFurigana
					{
						let fstart = Cast<Int32>( blocks[i + IndexStart] );
						let fsize  = Cast<Int32>( blocks[i + IndexSize] );
						//let fcount = Cast<Int32>( blocks[i + IndexCharCount] );
						let ftype  = Cast<Int32>( blocks[i + IndexType] );

						Assert(ftype == TypeFurigana, "Expected furigana type!");

						let furigana = StrMid(japaneseText, fstart, fsize);

						w = this.AddKanjiWithFuriganaWidgets(str, furigana, linewidget, fontsize, this.settings.furiganaScale, clr);
					}
					else
					{
						w = this.AddKanjiWidget(str, linewidget, fontsize, clr);
					}

					if fadeinduration > 0.0
					{
						this.AddFadeInAnimation(w, currentcharcount, count, totalcharcount, fadeinduration);
						currentcharcount += count;
					}
				}
				else
				{
					// we should not encounter "lonely" furigana
					LogChannel(n"DEBUG", "Found furigana not connected with any kanji.");
				}
			}

			currcharlen += count;

			i += IndexCOUNT;
		}
	}

	public func GenerateFurigana(parent :ref<inkCompoundWidget>, japaneseText :String, motherTongueText :String, duration :Float, lineid :Uint64, fontsize :Int32, singleline :Bool, checkForExisting :Bool) -> String
	{
		/*LogChannel(n"DEBUG", "Settings:");
		LogChannel(n"DEBUG", "  enabled: " + ToString(settings.enabled));
		LogChannel(n"DEBUG", "  colorizeKanji: " + ToString(settings.colorizeKanji));
		LogChannel(n"DEBUG", "  colorizeKatakana: " + ToString(settings.colorizeKatakana));
		LogChannel(n"DEBUG", "  addSpaces: " + ToString(settings.addSpaces));*/

		if !this.settings.enabled {
			return StrStripFurigana(japaneseText);
		}

		if this.settings.addSpaces {
			japaneseText = StrAddSpaces(japaneseText);
		}

		let blocks = StrSplitFurigana(japaneseText, this.settings.colorizeKatakana);
		let size = ArraySize(blocks);
		let count = size / EnumInt(StrSplitFuriganaIndex.COUNT);

		if count < 1
		{
			return japaneseText;
		}

		this.GenerateFuriganaWidgets(parent, japaneseText, motherTongueText, duration, lineid, blocks, fontsize, singleline, checkForExisting);

		return "";
	}
}
