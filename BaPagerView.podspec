Pod::Spec.new do |s|
  s.name         = 'BaPagerView'
  s.version      = '0.1.0'
  s.summary      = 'Configurable UIKit carousel for Swift and Objective-C'
  s.homepage     = 'https://github.com/Shy0909/BaPagerView'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Shy0909' => '41362852+Shy0909@users.noreply.github.com' }
  s.source       = { :git => "#{s.homepage}.git", :tag => "v#{s.version}" }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.module_name   = 'BaPagerView'
  s.frameworks    = 'UIKit'
  s.source_files  = [
    'Sources/BaPagerView/BaCarouselConfiguration.swift',
    'Sources/BaPagerView/BaCarouselLayout.swift',
    'Sources/BaPagerView/BaCarouselView.swift'
  ]
end
