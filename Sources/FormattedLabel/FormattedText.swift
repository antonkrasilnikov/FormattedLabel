import SwiftUI

#if os(iOS)
typealias ViewRepresentable = UIViewRepresentable
#elseif os(macOS)
typealias ViewRepresentable = NSViewRepresentable
#endif

public struct FormattedText: ViewRepresentable {
    public let text: String
    public let style: FormattedTextStyle
    public let linkCallback: ((URL) -> Void)?

    public init(text: String, style: FormattedTextStyle = .init(), linkCallback: ((URL) -> Void)? = nil) {
        self.style = style
        self.linkCallback = linkCallback
        self.text = text
    }

    private func make(context: Context) -> some FormattedLabel {
        let label = FormattedLabel()
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.hyperlinkCallback = linkCallback
#if os(iOS)
        if style.markLinks {
            label.isUserInteractionEnabled = true
        }
#endif
        return label
    }

    private func update(_ uiView: FormattedLabel, context: Context) {
        uiView.modify {
            uiView.numberOfLines = 0
            uiView.font = style.font.platformFont
            uiView.textColor = style.textColor.platfotmColor
            uiView.linespacing = style.linespacing
            uiView.markLinks = style.markLinks
            uiView.textAlignment = .init(aligment: style.aligment)
            uiView.text = text
        }
    }

#if os(iOS)
    public func makeUIView(context: Context) -> some FormattedLabel {
        make(context: context)
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {
        update(uiView, context: context)
    }
#elseif os(macOS)
    public func makeNSView(context: Context) -> some FormattedLabel {
        make(context: context)
    }

    public func updateNSView(_ nsView: NSViewType, context: Context) {
        update(nsView, context: context)
    }
#endif
}

public struct FormattedTextStyle {
    public enum FontStyle {
        case preferred(font: Font)
        case custom(name: String, size: CGFloat)

        var platformFont: SystemFont {
            switch self {
            case .preferred(let font):
                return SystemFont.preferredFont(from: font)
            case .custom(let name, let size):
                return SystemFont(name: name, size: size) ?? .systemFont(ofSize: size)
            }
        }
    }
    public struct TextColor {
        let platfotmColor: SystemColor
        @available(iOS 14.0, macOS 11.0, *)
        public static func color(_ value: Color) -> TextColor {
            .init(platfotmColor: .init(value))
        }
        public static func rgba(r: CGFloat, g: CGFloat, b: CGFloat, alpa: CGFloat = 1) -> TextColor {
            .init(platfotmColor: .init(red: r, green: g, blue: b, alpha: alpa))
        }
        public static func hex(_ value: String) -> TextColor {
            .init(platfotmColor: .init(hex: value))
        }
    }
    let font: FontStyle
    let textColor: TextColor
    let linespacing: CGFloat
    let markLinks: Bool
    let aligment: TextAlignment

    public init(font: FontStyle = .preferred(font: .body),
                textColor: TextColor = TextColor.rgba(r: 0, g: 0, b: 0),
                linespacing: CGFloat = 0,
                aligment: TextAlignment = .leading,
                markLinks: Bool = true) {
        self.font = font
        self.textColor = textColor
        self.linespacing = linespacing
        self.markLinks = markLinks
        self.aligment = aligment
    }
}

private extension SystemFont {
    class func preferredFont(from font: Font) -> SystemFont {
        let style: SystemFont.TextStyle

        func styleBase() -> SystemFont.TextStyle {
            switch font {
            case .largeTitle:  return .largeTitle
            case .title:       return .title1
            case .headline:    return .headline
            case .subheadline: return .subheadline
            case .callout:     return .callout
            case .caption:     return .caption1
            case .footnote:    return .footnote
            case .body: fallthrough
            default:           return .body
            }
        }

        func style14() -> SystemFont.TextStyle {
            if #available(iOS 14.0, macOS 11.0, *) {
                switch font {
                case .title2:      return .title2
                case .title3:      return .title3
                case .caption2:    return .caption2
                default:           break
                }
            }
            return styleBase()
        }

        return SystemFont.preferredFont(forTextStyle: style14())
    }
}

private extension NSTextAlignment {
    init(aligment: TextAlignment) {
        switch aligment {
        case .leading:
            self = .left
        case .center:
            self = .center
        case .trailing:
            self = .right
        }
    }
}
