# FormattedLabel

**FormattedLabel** is a cross-platform (iOS / macOS) library for rendering formatted text using HTML-like tags or a custom lightweight markup.

It supports:

- styled text (color, font, scale)
- inline images (local & remote)
- tappable links
- UIKit, AppKit, and SwiftUI

---

## ✨ Features

- HTML-like tag parsing
- Custom DSL markup support
- Inline images (`image`, `img`)
- Async image loading
- Text and image scaling
- Clickable links
- UIKit / AppKit / SwiftUI support
- Flexible styling system

---

## 📦 Installation (Swift Package Manager)

```swift
.package(url: "https://github.com/antonkrasilnikov/FormattedLabel", from: "1.1.0")
```

---

## 🚀 Quick Start

```swift
let label = FormattedLabel()
label.text = """
London is <text color=ff0000 scale=1.1 font=Arial>the</text> <text scale=0.9>capital</text> of <image url=https://www.historic-uk.com/assets/Images/unitedkingdom.png>
"""
```

![](example.png)

---

## 🏷 Supported Tags

| Tag            | Description     |
| -------------- | --------------- |
| `text`         | Formatted text  |
| `font`         | Font definition |
| `image`, `img` | Image insertion |

---

## ⚙️ Supported Attributes

| Attribute | Description          |
| --------- | -------------------- |
| `color`   | Text color (hex)     |
| `font`    | Font name            |
| `scale`   | Text scale           |
| `url`     | Image URL            |
| `src`     | Alternative to `url` |

---

## 🧩 Usage Examples

### Colored and scaled text

```swift
label.text = "Hello <text color=ff0000 scale=1.2>World</text>"
```

### Different fonts

```swift
label.text = """
<text font=Arial>Arial Text</text> and <text font=Helvetica>Helvetica Text</text>
"""
```

### Image insertion

```swift
label.text = """
Flag: <image url=https://www.historic-uk.com/assets/Images/unitedkingdom.png>
"""
```

---

## 🔗 Links Handling

```swift
label.markLinks = true
label.hyperlinkCallback = { url in
    print("Tapped:", url)
}
```

---

## 🧩 SwiftUI Component: FormattedText

`FormattedText` is a SwiftUI wrapper around `FormattedLabel`, allowing you to render formatted text directly in SwiftUI.

It automatically parses HTML-like or custom markup into an `NSAttributedString`, using UIKit/AppKit under the hood.

---

## 🚀 Basic Usage

```swift
FormattedText(
    text: "Hello <text color=ff0000>World</text>"
)
```

By default, it uses system font and basic styling.

---

## 🎨 Styling

```swift
FormattedText(
    text: "London is <text color=ff0000>the</text> capital",
    style: FormattedTextStyle(
        font: .custom(name: "Arial", size: 18),
        textColor: .hex("000000"),
        linespacing: 1.2,
        aligment: .leading,
        markLinks: true
    )
)
```

---

## 🔗 Link Handling

```swift
FormattedText(
    text: "Visit https://apple.com",
    style: .init(markLinks: true),
    linkCallback: { url in
        print("Tapped:", url)
    }
)
```

**Note:**

- `markLinks = true` enables:
  - automatic link detection
  - underline styling
  - tap handling

---

## ⚙️ Component Parameters

```swift
init(
    text: String,
    style: FormattedTextStyle = .init(),
    linkCallback: ((URL) -> Void)? = nil
)
```

| Parameter      | Description                    |
| -------------- | ------------------------------ |
| `text`         | Input string with markup       |
| `style`        | Visual configuration           |
| `linkCallback` | Callback triggered on link tap |

---

## 🎨 FormattedTextStyle

```swift
FormattedTextStyle(
    font: FontStyle = .preferred(font: .body),
    textColor: TextColor = .rgba(r: 0, g: 0, b: 0),
    linespacing: CGFloat = 0,
    aligment: TextAlignment = .leading,
    markLinks: Bool = true
)
```

---

### 🅰️ FontStyle

```swift
.preferred(font: Font)
.custom(name: String, size: CGFloat)
```

Examples:

```swift
font: .preferred(font: .headline)
font: .custom(name: "Arial", size: 16)
```

---

### 🎨 TextColor

```swift
.hex("ff0000")
.rgba(r: 1, g: 0, b: 0, alpha: 1)
.color(Color.red)
```

---

### 🧠 Custom Markup (DSL)

In addition to HTML-like tags, **FormattedLabel** supports a lightweight custom markup format designed for better readability and flexibility.

### ✍️ Syntax Example

```text
London is <text="the",font=Arial,fontScale=1.1,color=ff0000> 
<text="capital",fontScale=0.9> 
of <url=https://www.historic-uk.com/assets/Images/unitedkingdom.png>
```

---

## 🏷 Supported Formatters

| Formatter       | Description                                                        |
| --------------- | ------------------------------------------------------------------ |
| `text`          | Text content to display                                            |
| `color`         | Text color (hex format, e.g. `ff0000`)                             |
| `font`          | Font name                                                          |
| `scale`         | Relative text scale                                                |
| `fontScale`     | Same as `scale`                                                    |
| `url`           | Remote image URL                                                   |
| `image`         | Local image name from assets                                       |
| `imageAligment` | Vertical alignment of image: `center`, `baseline`, `capitalCenter` |
| `imageScale`    | Image scale relative to text                                       |
| `inner`         | If `true`, text is rendered on top of the image                    |

---

## 🧩 Examples

### Text styling

```text
<text=\"Hello\", color=ff0000, font=Arial, fontScale=1.2>
```

---

### Multiple styled segments

```text
<text=\"London\", fontScale=1.2>
<text=\"is\", fontScale=0.8>
<text=\"great\", color=00ff00>
```

---

### Image from URL

```text
<url=https://example.com/image.png>
```

---

### Local image

```text
<image=icon_name>
```

---

### Image with alignment and scale

```text
<image=icon_name, imageAligment=center, imageScale=1.5>
```

---

### Text over image

```text
<text=\"SALE\", inner=true, image=banner, color=ffffff>
```

---

## ⚙️ Notes

- Attributes are comma-separated
- Order of attributes does not matter
- Strings should be wrapped in quotes when needed (`text=\"...\"`)
- `fontScale` and `scale` are interchangeable

---

## 📱 Platforms

- iOS
- macOS
- SwiftUI
- UIKit / AppKit

---

## 📄 License

MIT
