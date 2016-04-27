<img src="https://cloud.githubusercontent.com/assets/75655/10141830/f92646ca-660e-11e5-8e1e-40c90482ead0.png" width="175" alt="Xcode.swift">
<hr>

Reading _and writing_ the the Xcode pbxproj file format, from Swift!

The main goal of this project is to generate `project.pbxproj` files in the legacy OpenStep format used by Xcode. Using this, a project file can be modified without changing it to XML format and causing a huge git diff.

Currently, this project is mostly used to support [R.swift](https://github.com/mac-cain13/R.swift).


Usage
-----

This reads a xcodeproj file (possibly in XML format), and writes it back out in OpenStep format:

```swift
let xcodeproj = NSURL(fileURLWithPath: "Test.xcodeproj")

let proj = try! XCProjectFile(xcodeprojURL: xcodeproj)

try! proj.writeToXcodeproj(xcodeprojURL: xcodeproj, format: NSPropertyListFormat.OpenStepFormat)
```


Releases
--------

 - **0.3.0** - 2016-04-27 - Fixes to SourceTreeFolder
 - 0.2.1 - 2015-12-30 - Add missing PBXProxyReference class
 - **0.2.0** - 2015-10-29 - Adds serialization support
 - **0.1.0** - 2015-09-28 - Initial public release


Licence & Credits
-----------------

Xcode.swift is written by [Tom Lokhorst](https://twitter.com/tomlokhorst) and available under the [MIT license](https://github.com/tomlokhorst/Xcode.swift/blob/develop/LICENSE), so feel free to use it in commercial and non-commercial projects.

