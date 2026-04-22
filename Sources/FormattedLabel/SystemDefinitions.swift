#if os(macOS)

import AppKit
public typealias SystemLabel = NSLabel
public typealias SystemColor = NSColor
typealias SystemView = NSView
typealias SystemImage = NSImage
public typealias SystemFont = NSFont
typealias SystemImageView = NSImageView
typealias SystemTapGestureRecognizer = NSClickGestureRecognizer

extension NSView {
    func getGestureRecognizers() -> [NSGestureRecognizer] { gestureRecognizers }
}

#elseif os(iOS)

import UIKit
public typealias SystemLabel = UILabel
public typealias SystemColor = UIColor
typealias SystemView = UIView
typealias SystemImage = UIImage
public typealias SystemFont = UIFont
typealias SystemImageView = UIImageView
typealias SystemTapGestureRecognizer = UITapGestureRecognizer

extension UIView {
    func getGestureRecognizers() -> [UIGestureRecognizer] { gestureRecognizers ?? [] }
}

#endif
