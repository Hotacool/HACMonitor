#
# Be sure to run `pod lib lint HACMonitor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HACMonitor'
  s.version          = '0.1.0'
  s.summary          = 'A simple lib to monitor App cpu, memory.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Hotacool/HACMonitor'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'sicong.qian' => 'shisosen@163.com' }
  s.source           = { :git => 'https://github.com/Hotacool/HACMonitor.git', :tag => s.version.to_s }
  s.social_media_url = 'http://www.jianshu.com/u/24ef34aa7b41'

  s.ios.deployment_target = '8.0'

  s.source_files = 'HACMonitor/Classes/**/*'
  
  # s.resource_bundles = {
  #   'HACMonitor' => ['HACMonitor/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
