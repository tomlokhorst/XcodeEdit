<img src="https://cloud.githubusercontent.com/assets/75655/24331694/0c12df18-123a-11e7-8045-6c3f94d83e0a.png" width="77" alt="XcKit">
<hr>

<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible" /></a>

Reading _and writing_ the the Xcode pbxproj file format, from Swift!

The main goal of this project is to generate `project.pbxproj` files in the legacy OpenStep format used by Xcode. Using this, a project file can be modified without changing it to XML format and causing a huge git diff.

Currently, this project is mostly used to support [R.swift](https://github.com/mac-cain13/R.swift).


Usage
-----

This reads a xcodeproj file (possibly in XML format), and writes it back out in OpenStep format:

```swift
let xcodeproj = URL(fileURLWithPath: "Test.xcodeproj")

let proj = try! XCProjectFile(xcodeprojURL: xcodeproj)

try! proj.write(to: xcodeproj, format: PropertyListSerialization.PropertyListFormat.openStep)
```


Carthage
--------
```
github "tomlokhorst/Xcode.swift"
```


Releases
--------

 - **1.0.0** - 2017-03-26 - Rename from Xcode.swift to XcKit
 - **0.3.0** - 2016-04-27 - Fixes to SourceTreeFolder
 - 0.2.1 - 2015-12-30 - Add missing PBXProxyReference class
 - **0.2.0** - 2015-10-29 - Adds serialization support
 - **0.1.0** - 2015-09-28 - Initial public release


Licence & Credits
-----------------

XcKit is written by [Tom Lokhorst](https://twitter.com/tomlokhorst) and available under the [MIT license](https://github.com/tomlokhorst/XcKit/blob/develop/LICENSE), so feel free to use it in commercial and non-commercial projects.

