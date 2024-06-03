import Foundation
import UIKit

/// FormattedLabel is UILabel what supports formatted text in 2 formats: html tag and custom
///
/// Custom format example: London is <text=\"the\",font=Arial,fontScale=1.1,color=ff0000> <text=\"capital\",fontScale=0.9> of <url=https://www.historic-uk.com/assets/Images/unitedkingdom.png?1390903158>
///
/// supported formatters:
///     text                    - formatted text;
///     color                  - color of text;
///     font                    - name of font;
///     scale                  - related to base font size scale of formatted text;
///     url                      - link of image;
///     image                - image name in application asset;
///     imageAligment  - center | baseline, vertical image aligment;
///     imageScale       - related to formatted text scale;
///     inner                  - flag indicates that text should be upon the image (image or url);
///     fontScale           - the same with scale;
///

open class FormattedLabel: UILabel {

    /// related to font size space between lines
    public var linespacing: Float = 0 {
        didSet {
            guard linespacing != oldValue else { return }
            if notParsedString?.isEmpty == false {
                _update()
            }
        }
    }

    /// indicates that all links should be underlined and touchable
    public var markLinks: Bool = false {
        didSet {

            if markLinks {
                guard gestureRecognizers?.first(where: { $0 is _HyperlinksTapGestureRecognizer }) == nil else {
                    return
                }
                addGestureRecognizer(_HyperlinksTapGestureRecognizer(target: self, action: #selector(hyperlinkTap(gesture:))))
            }else{
                if let g = gestureRecognizers?.first(where: { $0 is _HyperlinksTapGestureRecognizer }) {
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

    open override var textColor: UIColor! {
        didSet {
            guard textColor != oldValue else { return }
            _baseTextColor = textColor
            _update()
        }
    }

    open override var font: UIFont! {
        set {
            guard baseFont != newValue else { return }
            self.baseFont = newValue
            if notParsedString?.isEmpty == false {
                _update()
            }
        }

        get {
            baseFont ?? super.font
        }
    }

    // private

    var _baseTextColor: UIColor?
    var baseFont: UIFont?
    var items: [FormattedLabelAttachment]?
    var notParsedString: String?

    @objc
    private
    func hyperlinkTap(gesture: _HyperlinksTapGestureRecognizer) {
        guard let link = gesture.hyperlink(label: self), let url = URL(string: link) else {
            return
        }
        hyperlinkCallback?(url)
    }

    @objc func _update() {
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

    @objc func buildText() {
        let font: UIFont = baseFont ?? .systemFont(ofSize: 17)
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

    func paragrarhStyle(font: UIFont) -> NSParagraphStyle {
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

class _HyperlinksTapGestureRecognizer: UITapGestureRecognizer {
    func hyperlink(label: UILabel) -> String? {
        guard let attributedText = label.attributedText, attributedText.length > 0 else {
            return nil
        }

        let labelSize = label.bounds.size
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: attributedText)
        let locationOfTouchInLabel = location(in: label)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.size = labelSize

        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                          y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y: locationOfTouchInLabel.y - textContainerOffset.y)

        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer,
                                                            in: textContainer,
                                                            fractionOfDistanceBetweenInsertionPoints: nil)

        let attrPointer = NSRangePointer.allocate(capacity: 1)

        defer {
            attrPointer.deallocate()
        }

        let value = attributedText.attribute(NSAttributedString.Key.underlineStyle,
                                 at: indexOfCharacter,
                                 effectiveRange: attrPointer)

        guard let value = value as? Int,
        value == NSUnderlineStyle.single.rawValue
        else {
            return nil
        }

        return (attributedText.string as NSString).substring(with: attrPointer.pointee)
    }
}
