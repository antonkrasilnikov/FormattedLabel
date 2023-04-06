import Foundation
import UIKit
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


extension UIView {

    func snapshot(scale: CGFloat = 0, isOpaque: Bool = false, afterScreenUpdates: Bool = true) -> UIImage? {
       UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, scale)
       drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
       let image = UIGraphicsGetImageFromCurrentImageContext()
       UIGraphicsEndImageContext()
       return image
    }
}

extension UIColor {
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

        if let match = regex(attribute: attribute)?.firstMatch(in: string, options: [], range: NSRange(range, in: string)),
           let range = Range(match.range, in: string) {

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

        return nil
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
                       range.lowerBound > lastRange.upperBound {

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

    private var image: UIImage?

    func buildText(baseFont: UIFont, baseTextColor: UIColor) -> NSAttributedString {

        let image: UIImage?

        if let i = self.image {
            image = i
        }else if let name = attributes[.image], let assetImage = UIImage(named: name) {
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

        let font: UIFont
        var fontSize = baseFont.pointSize
        let color: UIColor

        if let scale = floatValue(attribute: .fontScale) ?? floatValue(attribute: .scale) {
            fontSize *= CGFloat(scale)
        }

        if let fontName = attributes[.font], let f = UIFont(name: fontName, size: fontSize) {
            font = f
        }else{
            if fontSize != baseFont.pointSize, let f = UIFont(name: baseFont.fontName, size: fontSize) {
                font = f
            }else{
                font = baseFont
            }
        }

        if let hex = attributes[.color] {
            color = UIColor(hex: hex)
        }else{
            color = baseTextColor
        }

        if boolValue(attribute: .inner) {
            if let image = image {
                buildTextOnImage(image: image, font: font, textColor: color).forEach({ string.append($0) })
            }
        }else{
            buildRawTextAndImage(image: image, font: font, textColor: color).forEach({ string.append($0) })
        }

        return string
    }

    func floatValue(attribute: Attribute) -> Float? {
        if let value = attributes[attribute] {
            if #available(iOS 13.0, *) {
                return Scanner(string: value).scanFloat()
            } else {
                var fv: Float = 0
                Scanner(string: value).scanFloat(&fv)
                return fv
            }
        }
        return nil
    }

    func boolValue(attribute: Attribute) -> Bool {
        if let value = attributes[attribute] {
            if #available(iOS 13.0, *) {
                return Scanner(string: value).scanInt() == 1
            } else {
                var iv: Int = 0
                Scanner(string: value).scanInt(&iv)
                return iv == 1
            }
        }
        return false
    }

    func imageAttachment(image: UIImage, font: UIFont) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = image
        let attachSize = CGSize(width: image.size.width*font.lineHeight/image.size.height, height: font.lineHeight)
        attachment.bounds = .init(x: 0, y: attributes[.imageAligment] == "baseline" ? 0 : (font.ascender - attachSize.height)/2, width: attachSize.width, height: attachSize.height)
        return attachment
    }

    func buildRawTextAndImage(image: UIImage?, font: UIFont, textColor: UIColor) -> [NSAttributedString] {

        var strings: [NSAttributedString] = []

        if let text = attributes[.text] {
            strings.append(NSAttributedString(string: text.replacingPlaceholders(),
                                              attributes: [ NSAttributedString.Key.foregroundColor : textColor,
                                                            NSAttributedString.Key.font : font ]))
        }

        if let image = image {
            strings.append(.init(attachment: imageAttachment(image: image, font: font)))
        }

        return strings
    }

    func buildTextOnImage(image: UIImage, font: UIFont, textColor: UIColor) -> [NSAttributedString] {

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        let imageScale = CGFloat(floatValue(attribute: .imageScale) ?? 1/0.7)
        let frame = CGRect(x: 0, y: 0, width: imageView.bounds.width*1/imageScale, height: imageView.bounds.height)
        let valueLabel = UILabel(frame: frame)
        valueLabel.center = .init(x: imageView.bounds.width/2, y: imageView.bounds.height/2)
        valueLabel.textAlignment = .center
        valueLabel.textColor = textColor
        if let text = attributes[.text] {
            valueLabel.text = text.replacingPlaceholders()
        }
        valueLabel.font = font
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.baselineAdjustment = .alignCenters
        valueLabel.backgroundColor = .clear
        imageView.addSubview(valueLabel)

        if let att_image = imageView.snapshot() {
            return [NSAttributedString(attachment: imageAttachment(image: att_image, font: font))]
        }

        return []
    }
}
