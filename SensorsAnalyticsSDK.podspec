Pod::Spec.new do |s|
  s.name         = "SensorsAnalyticsSDK"
  s.version      = "2.1.1"
  s.summary      = "The official iOS SDK of Sensors Analytics."
  s.homepage     = "http://www.sensorsdata.cn"
  s.source       = { :git => 'https://github.com/sensorsdata/sa-sdk-ios.git', :tag => "v#{s.version}" } 
  s.license = { :type => "Apache License, Version 2.0" }
  s.author = { "Yuhan ZOU" => "zouyuhan@sensorsdata.cn" }
  s.platform = :ios, "8.0"
  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'CoreGraphics', 'QuartzCore', 'CoreMotion'
  s.libraries = 'icucore', 'sqlite3', 'z'
  s.default_subspec = ['Core', 'WebView', 'Location']

  s.subspec 'Core' do |c|
    c.source_files  =  "SensorsAnalyticsSDK/Core/**/*.{h,m}"
    c.public_header_files = "SensorsAnalyticsSDK/SensorsAnalyticsSDK.h","SensorsAnalyticsSDK/SAAppExtensionDataManager.h","SensorsAnalyticsSDK/SASecurityPolicy.h","SensorsAnalyticsSDK/SAConfigOptions.h","SensorsAnalyticsSDK/SAConstants.h"
    c.resource = 'SensorsAnalyticsSDK/SensorsAnalyticsSDK.bundle'
  end

  s.subspec 'WebView' do |w|
    w.dependency 'SensorsAnalyticsSDK/Core'
    w.source_files  =  "SensorsAnalyticsSDK/WebView/**/*.{h,m}"
    w.public_header_files = "SensorsAnalyticsSDK/SensorsAnalyticsSDK.h","SensorsAnalyticsSDK/SAAppExtensionDataManager.h","SensorsAnalyticsSDK/SASecurityPolicy.h","SensorsAnalyticsSDK/SAConfigOptions.h","SensorsAnalyticsSDK/SAConstants.h"
    w.resource = 'SensorsAnalyticsSDK/SensorsAnalyticsSDK.bundle'
  end

  # 打开 log
  s.subspec 'Location' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = 'SensorsAnalyticsSDK/Location/**/*.{h,m}'
    f.private_header_files = 'SensorsAnalyticsSDK/Location/**/*.h'
    f.frameworks = 'CoreLocation'
  end

  s.subspec 'ReactNative' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = 'SensorsAnalyticsSDK/ReactNative/**/*.{h,m}'
    f.private_header_files = 'SensorsAnalyticsSDK/ReactNative/**/*.h'
    f.frameworks = 'CoreLocation'
  end
end
