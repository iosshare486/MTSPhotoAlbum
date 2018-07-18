#
#  Be sure to run `pod spec lint TSDataPersistence.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#
Pod::Spec.new do |s|

  s.name         = "MTSPhotoAlbum"
  s.version      = "0.0.3"
  s.summary      = "MTSPhotoAlbum"
  s.description  = <<-DESC
            photo album for select
                   DESC
  s.homepage     = "https://gitlab.caiqr.com"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Paul" => "zhangjunjie@caiqr.com" }
 
  s.ios.deployment_target = '9.0'
  s.source       = { :git => "http://gitlab.caiqr.com/ios_module/MTSPhotoAlbum.git", :tag => "#{s.version.to_s}" }
  s.source_files = "MTSPhotoAlbum/"
  s.resources = "MTSPhotoAlbum/KMTSNPhotoAlbum.bundle"
  s.framework  = "UIKit","Photos"
  s.swift_version = '4.1'
  s.dependency "TSUtility"
  s.dependency "SnapKit"
  s.requires_arc = true

end
