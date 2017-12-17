Pod::Spec.new do |s|
  s.name         = "XcodeEdit"
  s.version      = "2.0.0"
  s.license      = "MIT"

  s.summary      = "Reading and writing the Xcode pbxproj file format, from Swift!"

  s.description  = <<-DESC
The main goal of this project is to generate project.pbxproj files in the legacy OpenStep format used by Xcode. Using this, a project file can be modified without changing it to XML format and causing a huge git diff.
                   DESC

  s.authors           = { "Tom Lokhorst" => "tom@lokhorst.eu" }
  s.social_media_url  = "https://twitter.com/tomlokhorst"
  s.homepage          = "https://github.com/tomlokhorst/XcodeEdit"

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  s.source          = { :git => "https://github.com/tomlokhorst/XcodeEdit.git", :tag => s.version }
  s.source_files    = "Sources"

end
