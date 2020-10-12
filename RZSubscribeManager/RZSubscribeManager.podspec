

Pod::Spec.new do |spec|


  spec.name         = "RZSubscribeManager"
  spec.version      = "1.0.0"
  spec.summary      = "Small test to test code sharing via cocoapods."
  spec.description  = "Small example to test code sharing via cocoapods."
  spec.homepage     = "https://github.com/Angel-senpai/RZSubscribeManager.git"
  spec.license      = "MIT"
  spec.authors            = { "Angel-senpai" => "daniil.murygin68@gmail.com", "Nerson" => "aleksandrsenin@icloud.com" }
  spec.platform     = :ios, "12.0"




  spec.source       = { :git => "https://github.com/Angel-senpai/RZSubscribeManager.git", :tag => "1.0.0" }


  spec.source_files  = "RZSubscribeManager/RZSubscribeManager/**/*"
  spec.exclude_files = "RZSubscribeManager/RZSubscribeManager/*.plist"
  spec.swift_version = '5.3'
  spec.ios.deployment_target  = '12.0'
  
  spec.requires_arc = true

  spec.dependency "SwiftyStoreKit"

end
