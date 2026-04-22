import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

class _HyperlinksTapGestureRecognizer: SystemTapGestureRecognizer {
    func hyperlink(label: SystemLabel) -> String? {
        guard let attributedText = label.attributedText, attributedText.length > 0 else { return nil }

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
#if os(iOS)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
#elseif os(macOS)
        let textBoundingBox = label.bounds
#endif
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                          y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer,
                                                            in: textContainer,
                                                            fractionOfDistanceBetweenInsertionPoints: nil)
        let attrPointer = NSRangePointer.allocate(capacity: 1)
        defer { attrPointer.deallocate() }
        let value = attributedText.attribute(NSAttributedString.Key.underlineStyle,
                                 at: indexOfCharacter,
                                 effectiveRange: attrPointer)
        guard let value = value as? Int, value == NSUnderlineStyle.single.rawValue else { return nil }
        return (attributedText.string as NSString).substring(with: attrPointer.pointee)
    }
}
