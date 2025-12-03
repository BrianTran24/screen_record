Pod::Spec.new do |s|
  s.name             = 'screen_record_plus'
  s.version          = '0.0.4'
  s.summary          = 'Screen recording plugin with native API support'
  s.description      = <<-DESC
A Flutter plugin for screen recording using native APIs with coordinate-based recording support.
                       DESC
  s.homepage         = 'https://github.com/BrianTran24/screen_record'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Brian Tran' => 'brian@brian98.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
