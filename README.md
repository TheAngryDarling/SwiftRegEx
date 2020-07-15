# Regular Expression

![swift >= 4.0](https://img.shields.io/badge/swift-%3E%3D4.0-brightgreen.svg)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
[![Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat)](LICENSE.md)

A swift wrapper around NSRegularExpression.  This package simplifies the use of regular expression with the conversion of NS objects to Swift objects

This class also provides cross platform support for group names from Swift 4.0 and above, where as the NSTextCheckingResult only supports it on Apple platforms with newer OS's (MacOS 13, iOS 11, watchOS 4)

## Usage

Full way of matching patterns

```swift
import RegEx

let pattern: String = "..."
let string: String = "..."
let regEx = try RegEx(pattern: pattern)
let matches = regEx.matches(in: string)
for match in matches {
    // let value = match.value
    // let range = match.range
    // let groupRange: Range<String.Index>? = match.range(at: 0)
    // let groupRangeByName: Range<String.Index>? = match.range(withName: "GroupName")
    // let groupValue = match.value(at: 0)
    // let groupValueByName = match.value(withName: "GroupName")
}
```

Get first match

```swift
import RegEx

let pattern: String = "..."
let string: String = "..."
let regEx = try RegEx(pattern: pattern)
if let match = regEx.firstMatch(in: string) {
    // let value = match.value
    // let range = match.range
    // let groupRange: Range<String.Index>? = match.range(at: 0)
    // let groupRangeByName: Range<String.Index>? = match.range(withName: "GroupName")
    // let groupValue = match.value(at: 0)
    // let groupValueByName = match.value(withName: "GroupName")
}
```

Directly from String

```swift
import RegEx

let pattern: String = "..."
let string: String = "..."
let matches = try string.match(pattern: pattern)
for match in matches {
    // let value = match.value
    // let range = match.range
    // let groupRange: Range<String.Index>? = match.range(at: 0)
    // let groupRangeByName: Range<String.Index>? = match.range(withName: "GroupName")
    // let groupValue = match.value(at: 0)
    // let groupValueByName = match.value(withName: "GroupName")
}

if let match = try string.firstMatch(pattern: pattern) {
    // let value = match.value
    // let range = match.range
    // let groupRange: Range<String.Index>? = match.range(at: 0)
    // let groupRangeByName: Range<String.Index>? = match.range(withName: "GroupName")
    // let groupValue = match.value(at: 0)
    // let groupValueByName = match.value(withName: "GroupName")
}
```

## Author

* **Tyler Anger** - *Initial work*  - [TheAngryDarling](https://github.com/TheAngryDarling)

## License

This project is licensed under Apache License v2.0 - see the [LICENSE.md](LICENSE.md) file for details.
