import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// FormattedLabel is UILabel/NSTextField what supports formatted text in 2 formats: html tag and custom
///
/// Custom format example: London is <text=\"the\",font=Arial,fontScale=1.1,color=ff0000> <text=\"capital\",fontScale=0.9> of <url=https://www.historic-uk.com/assets/Images/unitedkingdom.png>
///
/// supported formatters:
///     text                    - formatted text;
///     color                  - color of text;
///     font                    - name of font;
///     scale                  - related to base font size scale of formatted text;
///     url                      - link of image;
///     image                - image name in application asset;
///     imageAligment  - center | baseline | capitalCenter, vertical image aligment;
///     imageScale       - related to formatted text scale;
///     inner                  - flag indicates that text should be upon the image (image or url);
///     fontScale           - the same with scale;
///

open class FormattedLabel: SystemLabel {

    // MARK: public interface

    /// related to font size space between lines
    public var linespacing: CGFloat = 0 {
        didSet {
            guard linespacing != oldValue, notParsedString?.isEmpty == false else { return }
            _update()
        }
    }

    /// indicates that all links should be underlined and touchable
    public var markLinks: Bool = false {
        didSet {
            if markLinks {
                guard getGestureRecognizers().first(where: { $0 is _HyperlinksTapGestureRecognizer }) == nil else { return }
                addGestureRecognizer(_HyperlinksTapGestureRecognizer(target: self, action: #selector(hyperlinkTap(gesture:))))
            }else{
                if let g = getGestureRecognizers().first(where: { $0 is _HyperlinksTapGestureRecognizer }) {
                    removeGestureRecognizer(g)
                }
            }
            buildText()
        }
    }

    /// called when any link is tapped
    public var hyperlinkCallback: ((URL) -> Void)?

    open override var text: String? {
        set {
            guard newValue != notParsedString else { return }
            notParsedString = newValue
            _update()
        }
        get { notParsedString }
    }

    open override var textColor: SystemColor! {
        didSet {
            guard textColor != oldValue else { return }
            _baseTextColor = textColor
            _update()
        }
    }

    open override var font: SystemFont! {
        set {
            guard baseFont != newValue else { return }
            self.baseFont = newValue
            if notParsedString?.isEmpty == false {
                _update()
            }
        }
        get { baseFont ?? super.font }
    }

    public func modify(update bunch: () -> Void) {
        isBunchUpdating = true
        bunch()
        isBunchUpdating = false
        _update()
    }

    // MARK: private

    private var _baseTextColor: SystemColor?
    private var baseFont: SystemFont?
    private var items: [FormattedLabelAttachment]?
    private var notParsedString: String?
    private var isBunchUpdating = false

    @objc
    private
    func hyperlinkTap(gesture: _HyperlinksTapGestureRecognizer) {
        guard let link = gesture.hyperlink(label: self), let url = URL(string: link) else { return }
        hyperlinkCallback?(url)
    }

    @objc
    private
    func _update() {
        guard !isBunchUpdating else { return }
        if let notParsedString = notParsedString {
            self.items = HtmlTagParser.isTagged(text: notParsedString) ?
            HtmlTagParser.parse(originString: notParsedString) :
            FormatterParser.parse(originString: notParsedString)
        }else{
            items = []
        }
        items?.forEach({ $0.delegate = self })
        buildText()
    }

    @objc
    private
    func buildText() {
        guard !isBunchUpdating else { return }
        let font: SystemFont = baseFont ?? .systemFont(ofSize: 17)
        let colorOfText = _baseTextColor ?? textColor ?? .white
        let string  = NSMutableAttributedString()
        items?.forEach { string.append($0.buildText(baseFont: font, baseTextColor: colorOfText)) }
        string.addAttribute(.paragraphStyle, value: paragrarhStyle(font: font), range: .init(location: 0, length: string.length))
        if markLinks, let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let labelText = string.string
            let matches = detector.matches(in: labelText, range: .init(location: 0, length: labelText.count))
            matches.forEach { match in
                string.addAttributes([.underlineStyle : NSUnderlineStyle.single.rawValue], range: match.range)
            }
        }
        attributedText = string
        sizeToFit()
    }

    private
    func paragrarhStyle(font: SystemFont) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = textAlignment
        if linespacing != 0 {
            style.lineSpacing = CGFloat(linespacing)*font.pointSize/2
            style.paragraphSpacing = CGFloat(linespacing)*font.pointSize/2
        }
        return style
    }
}

extension FormattedLabel: FormattedLabelAttachmentDelegate {
    func attachmentDidLoad(_ attachment: FormattedLabelAttachment) {
        buildText()
    }
}
