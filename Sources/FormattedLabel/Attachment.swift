import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import UrlImageView

let _LeftAngleBracket = "|langbr|"
let _RightAngleBracket = "|rangbr|"

extension String {
    func replacingPlaceholders() -> String {
        replacingOccurrences(of: _LeftAngleBracket, with: "<").replacingOccurrences(of: _RightAngleBracket, with: ">")
    }
    func setupPlaceholders() -> String {
        replacingOccurrences(of: "\\<", with: _LeftAngleBracket).replacingOccurrences(of: "\\>", with: _RightAngleBracket)
    }
}

extension SystemView {
    func snapshot() -> SystemImage? {
#if os(iOS)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
#elseif os(macOS)
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        cacheDisplay(in: bounds, to: rep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        return image
#endif
    }
}

#if os(macOS)
extension NSFont {
    var lineHeight: CGFloat {
        get { self.ascender + abs(self.descender) + self.leading }
        set { }
    }
}
extension NSView {
    var center: CGPoint {
        get { .init(x: frame.midX, y: frame.midY) }
        set {
            let w = frame.size.width
            let h = frame.size.height
            frame = .init(x: newValue.x - w/2, y: newValue.y - h/2, width: w, height: h)
        }
    }
}
#endif

extension SystemColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.charactersToBeSkipped = CharacterSet.alphanumerics.inverted

        var rgbValue:UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/255.0
        let green = CGFloat((rgbValue & 0x00FF00) >>  8)/255.0
        let blue = CGFloat((rgbValue & 0x0000FF) >>  0)/255.0

        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}

class FormatterParser: NSObject {

    class func regex(attribute: Attribute) -> NSRegularExpression? {
        switch attribute {
        case .text:
            return try? NSRegularExpression(pattern: "\(attribute.rawValue)=\".*\"", options: [])
        default:
            return try? NSRegularExpression(pattern: "\(attribute.rawValue)=.+?(\\s|>|,|\\s\">|\"\\/|\" )", options: [])
        }
    }

    class func value(attribute: Attribute, in string: String, range: Range<String.Index>) -> String? {
        guard let match = regex(attribute: attribute)?.firstMatch(in: string, options: [], range: NSRange(range, in: string)),
              let range = Range(match.range, in: string) else {
            return nil
        }
        let valueRange = string.index(range.lowerBound, offsetBy: attribute.rawValue.count + 1)..<string.index(before: range.upperBound)
        var value = String(string[valueRange])

        switch attribute {
        case .text:
            value = String(value.dropFirst())
        default:
            break
        }
        return value
    }

    class func parse(originString: String, match: NSTextCheckingResult) -> FormattedLabelAttachment? {
        guard let range = Range(match.range, in: originString) else {
            return nil
        }
        let tagString = String(originString[originString.index(range.lowerBound, offsetBy: 1)..<range.upperBound])
        let tagRange = tagString.startIndex..<tagString.endIndex
        var attributes: [Attribute:String] = [:]
        for attribute in Attribute.allCases {
            if let data = value(attribute: attribute, in: tagString, range: tagRange) {
                attributes[attribute] = data
            }
        }
        return .init(attributes: attributes, range: range)
    }

    class func parse(originString: String) -> [FormattedLabelAttachment] {
        var items: [FormattedLabelAttachment] = []
        let text = originString.setupPlaceholders()
        if let regex = try? NSRegularExpression(pattern: "<[^>]*>", options: []) {
            let nsrange = NSRange(text.startIndex..<text.endIndex,
                                  in: text)
            regex.enumerateMatches(in: text, options: [], range: nsrange) { (result, _, stop) in
                guard let match = result, let range = Range(match.range, in: text) else { return }
                if let textItem = parse(originString: text, match: match) {
                    if let lastRange = items.last?.range,
                       range.lowerBound >= lastRange.upperBound {
                        let itemRange = lastRange.upperBound..<range.lowerBound
                        let item = FormattedLabelAttachment(attributes: [.text : String(text[itemRange])],
                                        range: itemRange)
                        items.append(item)
                    }else if range.lowerBound > text.startIndex {
                        let itemRange = text.startIndex..<range.lowerBound
                        let item = FormattedLabelAttachment(attributes: [.text : String(text[itemRange])],
                                        range: itemRange)
                        items.append(item)
                    }
                    items.append(textItem)
                }
            }
        }
        guard !items.isEmpty else {
            return [FormattedLabelAttachment(attributes: [.text : text],
                            range: text.startIndex..<text.endIndex)]
        }
        if let textItem = items.last,
           text.endIndex > textItem.range.upperBound {

            let itemRange = textItem.range.upperBound..<text.endIndex
            let item = FormattedLabelAttachment(attributes: [.text : String(text[itemRange])],
                            range: itemRange)
            items.append(item)
        }
        return items
    }
}

enum Attribute: String, CaseIterable {
    case text
    case color
    case font
    case scale
    case url
    case image
    case imageAligment
    case imageScale
    case inner
    case fontScale
    case underline
}

enum ImageAligment: String {
    case center
    case baseline
    case capitalCenter
}

enum UnderlineStyle: String {
    case single
    case thick
    case double
    case patternDot
    case patternDash
    case patternDashDot
    case patternDashDotDot
    case byWord
}

protocol FormattedLabelAttachmentDelegate: AnyObject {
    func attachmentDidLoad(_ attachment: FormattedLabelAttachment)
}

class FormattedLabelAttachment {
    let attributes: [Attribute:String]
    let range: Range<String.Index>
    weak var delegate: FormattedLabelAttachmentDelegate?

    init(attributes: [Attribute:String] = [:],
         range: Range<String.Index>) {
        self.attributes = attributes
        self.range = range
    }

    private var image: SystemImage?

    private struct TextStyle {
        let font: SystemFont
        let textColor: SystemColor
        let underlineStyle: NSUnderlineStyle?

        var attributes: [NSAttributedString.Key:Any] {
            var attributes: [NSAttributedString.Key:Any] = [:]
            attributes[.font] = font
            attributes[.foregroundColor] = textColor
            if let style = underlineStyle {
                attributes[.underlineStyle] = style.rawValue
            }
            return attributes
        }
    }

    func buildText(baseFont: SystemFont, baseTextColor: SystemColor) -> NSAttributedString {
        let image: SystemImage?
        if let i = self.image {
            image = i
        }else if let name = attributes[.image], let assetImage = SystemImage(named: name) {
            image = assetImage
        }else if let url = attributes[.url] {
            if let loadedImage = ImageLoader.loadedImage(url: url) {
                image = loadedImage
            }else{
                image = nil
                ImageLoader.load(urls: [url]) { [weak self] loadedMap in
                    guard let self = self else { return }
                    if let image = loadedMap[url] {
                        self.image = image
                        self.delegate?.attachmentDidLoad(self)
                    }
                }
            }
        }else{
            image = nil
        }
        let string = NSMutableAttributedString()
        let font: SystemFont
        var fontSize = baseFont.pointSize
        let color: SystemColor
        let underlineStyle: NSUnderlineStyle?

        if let scale = floatValue(attribute: .fontScale) ?? floatValue(attribute: .scale) {
            fontSize *= CGFloat(scale)
        }

        if let fontName = attributes[.font], let f = SystemFont(name: fontName, size: fontSize) {
            font = f
        }else{
            if fontSize != baseFont.pointSize, let f = SystemFont(name: baseFont.fontName, size: fontSize) {
                font = f
            }else{
                font = baseFont
            }
        }

        if let hex = attributes[.color] {
            color = SystemColor(hex: hex)
        }else{
            color = baseTextColor
        }

        if let underline = attributes[.underline], let style = UnderlineStyle(rawValue: underline) {
            switch style {
            case .single:
                underlineStyle = .single
            case .thick:
                underlineStyle = .thick
            case .double:
                underlineStyle = .double
            case .patternDot:
                underlineStyle = .patternDot
            case .patternDash:
                underlineStyle = .patternDash
            case .patternDashDot:
                underlineStyle = .patternDashDot
            case .patternDashDotDot:
                underlineStyle = .patternDashDotDot
            case .byWord:
                underlineStyle = .byWord
            }
        }else{
            underlineStyle = nil
        }

        if boolValue(attribute: .inner) {
            if let image = image {
                buildTextOnImage(image: image, font: font, textColor: color).forEach({ string.append($0) })
            }
        }else{
            buildRawTextAndImage(image: image, style: .init(font: font, textColor: color, underlineStyle: underlineStyle)).forEach({ string.append($0) })
        }
        return string
    }

    private func floatValue(attribute: Attribute) -> Float? {
        guard let value = attributes[attribute] else { return nil }
        if #available(iOS 13.0, macOS 10.15, *) {
            return Scanner(string: value).scanFloat()
        } else {
            var fv: Float = 0
            Scanner(string: value).scanFloat(&fv)
            return fv
        }
    }

    private func boolValue(attribute: Attribute) -> Bool {
        guard let value = attributes[attribute] else { return false }
        if #available(iOS 13.0, macOS 10.15, *) {
            return Scanner(string: value).scanInt() == 1
        } else {
            var iv: Int = 0
            Scanner(string: value).scanInt(&iv)
            return iv == 1
        }
    }

    private func imageAttachment(image: SystemImage, font: SystemFont) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = image
        let attachSize = CGSize(width: image.size.width*font.lineHeight/image.size.height, height: font.lineHeight)
        switch attributes[.imageAligment] {
        case ImageAligment.baseline.rawValue:
            attachment.bounds = .init(x: 0, y: 0, width: attachSize.width, height: attachSize.height)
        case ImageAligment.capitalCenter.rawValue:
            attachment.bounds = .init(x: 0, y: (font.capHeight - attachSize.height)/2, width: attachSize.width, height: attachSize.height)
        default:
            attachment.bounds = .init(x: 0, y: (font.xHeight - attachSize.height)/2, width: attachSize.width, height: attachSize.height)
        }
        return attachment
    }

    private func buildRawTextAndImage(image: SystemImage?, style: TextStyle) -> [NSAttributedString] {
        var strings: [NSAttributedString] = []
        if let text = attributes[.text] {
            strings.append(NSAttributedString(string: text.replacingPlaceholders(),
                                              attributes: style.attributes))
        }
        if let image = image {
            strings.append(.init(attachment: imageAttachment(image: image, font: style.font)))
        }
        return strings
    }

    private func buildTextOnImage(image: SystemImage, font: SystemFont, textColor: SystemColor) -> [NSAttributedString] {
        let imageView = SystemImageView(image: image)
#if os(iOS)
        imageView.contentMode = .scaleAspectFit
#endif
        let imageScale = CGFloat(floatValue(attribute: .imageScale) ?? 1/0.7)
        let frame = CGRect(x: 0, y: 0, width: imageView.bounds.width*1/imageScale, height: imageView.bounds.height)
        let valueLabel = SystemLabel(frame: frame)
        valueLabel.center = .init(x: imageView.bounds.width/2, y: imageView.bounds.height/2)
        valueLabel.textAlignment = .center
        valueLabel.textColor = textColor
        if let text = attributes[.text] {
            valueLabel.text = text.replacingPlaceholders()
        }
        valueLabel.font = font
#if os(iOS)
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.baselineAdjustment = .alignCenters
#endif
        valueLabel.backgroundColor = .clear
        imageView.addSubview(valueLabel)

        if let att_image = imageView.snapshot() {
            return [NSAttributedString(attachment: imageAttachment(image: att_image, font: font))]
        }
        return []
    }
}
