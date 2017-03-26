Pod::Spec.new do |s|
  s.name         = "Xcode.swift"
  s.version      = "0.4.0"
  s.summary      = "Reading and writing the the Xcode pbxproj file format, from Swift!"

  s.description  = <<-DESC
			The main goal of this project is to generate project.pbxproj files in the legacy OpenStep format used by Xcode.
			Using this, a project file can be modified without changing it to XML format and causing a huge git diff.
                   DESC

  s.homepage     = "https://github.com/tomlokhorst/Xcode.swift"
  s.license      = "MIT"

  s.author             = { "Tom Lokhorst" => "tom.lokhorst.eu" }
  s.social_media_url   = "https://twitter.com/tomlokhorst"

  s.platform     = :osx, "10.10"

  s.source       = { :git => "https://github.com/tomlokhorst/Xcode.swift.git", :tag => s.version.to_s }
  s.source_files = 'Sources/**/*.swift'

end
