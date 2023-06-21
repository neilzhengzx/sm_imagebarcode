require "json"
package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name          = package['name']
  s.version       = package['version']
  s.summary       = package['description']
  s.description   = package['description']
  s.author        = package['author']
  s.license       = package['license']
  s.requires_arc  = true
  s.homepage      = "http://git.smobiler.com:8442/RN-Source/sm_imagebarcode"
  s.source        = { :git => 'http://git.smobiler.com:8442/RN-Source/sm_imagebarcode.git', :tag => "v#{s.version}" }
  s.platform      = :ios, '9.0'
  s.source_files  = "ios/**/*.{h,m}"
  s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '"$(SRCROOT)/../libs"' }

  s.dependency 'React-Core'
end
