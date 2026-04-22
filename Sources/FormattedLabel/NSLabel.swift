#if os(macOS)
import AppKit
open class NSLabel: NSTextField {
    override init(frame frameRect: NSRect) {
      super.init(frame: frameRect)
      self.setup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        self.isBezeled = false
        self.drawsBackground = false
        self.isEditable = false
        self.isSelectable = false
    }

    open var text: String? {
        set { stringValue = newValue ?? "" }
        get { stringValue }
    }

    var attributedText: NSAttributedString? {
        set { placeholderAttributedString = newValue }
        get { placeholderAttributedString }
    }

    var textAlignment: NSTextAlignment {
        set { alignment = newValue }
        get { alignment }
    }

    var numberOfLines: Int {
        set {
            maximumNumberOfLines = newValue
            usesSingleLineMode = newValue == 1
        }
        get { usesSingleLineMode ? 1 : maximumNumberOfLines }
    }
}
#endif
