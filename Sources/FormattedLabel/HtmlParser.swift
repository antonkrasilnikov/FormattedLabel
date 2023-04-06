import Foundation

class HtmlTagParser: NSObject {

    enum HtmlAttribute: String, CaseIterable {
        case color
        case font
        case scale
        case url
    }

    enum Tag: String, CaseIterable {
        case text
        case font
        case image
    }

    class Item {

        let tag: (Tag,String)
        let attributes: [HtmlAttribute:String]
        let range: Range<String.Index>

        init(tag: (Tag,String),
             attributes: [HtmlAttribute:String] = [:],
             range: Range<String.Index>) {
            self.tag = tag
            self.attributes = attributes
            self.range = range
        }

        var attachment: FormattedLabelAttachment {

            var attributes: [Attribute:String] = [:]

            switch tag.0 {
            case .font, .text:
                attributes[.text] = tag.1.replacingOccurrences(of: ">", with: "\\>").replacingOccurrences(of: "<", with: "\\<")
            case .image:
                attributes[.url] = tag.1.replacingOccurrences(of: "\"", with: "")
            }

            for (attribute,value) in self.attributes {

                if attribute == .url && tag.0 == .image {
                    continue
                }

                switch attribute {
                case .color:
                    attributes[.color] = value
                case .font:
                    attributes[.font] = value.replacingOccurrences(of: "\"", with: "")
                case .scale:
                    attributes[.fontScale] = value.replacingOccurrences(of: "\"", with: "")
                default:
                    break
                }
            }


            return .init(attributes: attributes, range: range)
        }

        var value: String {

            var valuedString = "<"

            switch tag.0 {
            case .font, .text:
                let text = tag.1.replacingOccurrences(of: ">", with: "\\>").replacingOccurrences(of: "<", with: "\\<")
                valuedString += "text=\"\(text)\""
            case .image:
                valuedString += "url=\(tag.1.replacingOccurrences(of: "\"", with: ""))"
            }

            for (attribute,value) in attributes {

                if attribute == .url && tag.0 == .image {
                    continue
                }

                if valuedString.count > 1 {
                    valuedString += ","
                }

                switch attribute {
                case .color:
                    valuedString += "color=\(value)"
                case .font:
                    valuedString += "font=\(value.replacingOccurrences(of: "\"", with: ""))"
                case .scale:
                    if let scale = Float(value.replacingOccurrences(of: "\"", with: "")) {
                        valuedString += "fontScale=\(scale)"
                    }else{
                        valuedString += "fontScale=1"
                    }

                default:
                    break
                }
            }

            return valuedString + ">"
        }
    }

    class func regex(attribute: HtmlAttribute) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: "\(attribute.rawValue)=.+?(\\s|>|\\s\">|\"\\/|\" )", options: [])
    }

    class func value(attribute: HtmlAttribute, in string: String, range: Range<String.Index>) -> String? {

        if let match = regex(attribute: attribute)?.firstMatch(in: string, options: [], range: NSRange(range, in: string)),
           let range = Range(match.range, in: string) {

            let valueRange = string.index(range.lowerBound, offsetBy: attribute.rawValue.count + 1)..<string.index(before: range.upperBound)

            return String(string[valueRange])
        }

        return nil
    }

    class func parse(tag: Tag, originString: String, match: NSTextCheckingResult) -> Item? {

        guard let range = Range(match.range, in: originString) else {
            return nil
        }

        let tagString = String(originString[originString.index(range.lowerBound, offsetBy: tag.rawValue.count + 1)..<range.upperBound])
        let tagRange = tagString.startIndex..<tagString.endIndex
        let restRange = range.upperBound..<originString.endIndex

        let obj: String
        let itemRange: Range<String.Index>

        switch tag {
        case .image:
            if let url = value(attribute: .url, in: tagString, range: tagRange) {
                obj = url
                itemRange = range
            }else{
                return nil
            }
        default:
            if let endRegex = try? NSRegularExpression(pattern: "</\(tag.rawValue)>", options: []),
               let textMatch = endRegex.firstMatch(in: originString, options: [], range: NSRange(restRange, in: originString)),
               let textRange = Range(textMatch.range, in: originString) {

                obj = String(originString[range.upperBound..<textRange.lowerBound])
                itemRange = range.lowerBound..<textRange.upperBound
            }else{
                return nil
            }
        }

        var attributes: [HtmlAttribute:String] = [:]

        for attribute in HtmlAttribute.allCases {
            if let data = value(attribute: attribute, in: tagString, range: tagRange) {
                attributes[attribute] = data
            }
        }

        return .init(tag: (tag,obj), attributes: attributes, range: itemRange)

    }

    class func tag(matchString: String) -> Tag? {

        for tag in Tag.allCases {
            if matchString.hasPrefix("<\(tag.rawValue)") {
                return tag
            }
        }
        return nil
    }

    class func parse(originString: String) -> [FormattedLabelAttachment] {

        var textItems: [Item] = []

        if let regex = try? NSRegularExpression(pattern: "<[^>]*>", options: [])
           {

            let nsrange = NSRange(originString.startIndex..<originString.endIndex,
                                  in: originString)

            regex.enumerateMatches(in: originString, options: [], range: nsrange) { (result, _, stop) in
                guard let match = result, let range = Range(match.range, in: originString) else { return }

                let matchString = String(originString[range])

                if let tag = tag(matchString: matchString),
                   let textItem = parse(tag: tag, originString: originString, match: match) {

                    if let lastRange = textItems.last?.range,
                       range.lowerBound > lastRange.upperBound {

                        let itemRange = lastRange.upperBound..<range.lowerBound
                        let item = Item(tag: (.text,
                                              String(originString[itemRange])),
                                        range: itemRange)
                        textItems.append(item)

                    }else if range.lowerBound > originString.startIndex {
                        let itemRange = originString.startIndex..<range.lowerBound
                        let item = Item(tag: (.text,
                                              String(originString[itemRange])),
                                        range: itemRange)
                        textItems.append(item)
                    }

                    textItems.append(textItem)
                }

            }
        }

        guard !textItems.isEmpty else {
            return [FormattedLabelAttachment(attributes: [.text : originString],
                                             range: originString.startIndex..<originString.endIndex)]
        }

        if let textItem = textItems.last,
           originString.endIndex > textItem.range.upperBound {

            let itemRange = textItem.range.upperBound..<originString.endIndex
            let item = Item(tag: (.text,String(originString[itemRange])),
                            range: itemRange)
            textItems.append(item)
        }

        return textItems.compactMap({ $0.attachment })
    }

    class func isTagged(text: String) -> Bool {
        Tag.allCases.first(where: { text.range(of: "</\($0.rawValue)>") != nil }) != nil || text.range(of: "/>") != nil
    }
}
