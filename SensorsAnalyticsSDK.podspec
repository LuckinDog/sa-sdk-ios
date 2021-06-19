Pod::Spec.new do |s|
  s.name         = "SensorsAnalyticsSDK"
  s.version      = "2.6.5"
  s.summary      = "The official iOS SDK of Sensors Analytics."
  s.homepage     = "http://www.sensorsdata.cn"
  s.source       = { :git => 'https://github.com/sensorsdata/sa-sdk-ios.git', :tag => "v#{s.version}" } 
  s.license = { :type => "Apache License, Version 2.0" }
  s.author = { "Yuhan ZOU" => "zouyuhan@sensorsdata.cn" }
  s.platform = :ios, "8.0"
  s.default_subspec = 'Core'
  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'CoreGraphics', 'QuartzCore'
  s.libraries = 'icucore', 'sqlite3', 'z'

  s.subspec 'Common' do |c|
    core_dir = "SensorsAnalyticsSDK/Core/"
    c.source_files = core_dir + "**/*.{h,m}"
    c.public_header_files = core_dir + "SensorsAnalyticsSDK.h", core_dir + "SensorsAnalyticsSDK+Public.h", core_dir + "SAAppExtensionDataManager.h", core_dir + "SASecurityPolicy.h", core_dir + "SAConfigOptions.h", core_dir + "SAConstants.h" 
    c.resource = 'SensorsAnalyticsSDK/SensorsAnalyticsSDK.bundle'
  end
  
  s.subspec 'Core' do |c|
    c.dependency 'SensorsAnalyticsSDK/Visualized'
  end

  # 支持 CAID 渠道匹配
  s.subspec 'CAID' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = "SensorsAnalyticsSDK/CAID/**/*.{h,m}"
    f.private_header_files = 'SensorsAnalyticsSDK/CAID/**/*.h'
  end

  # 全埋点
  s.subspec 'AutoTrack' do |g|
    g.dependency 'SensorsAnalyticsSDK/Common'
    g.source_files = "SensorsAnalyticsSDK/AutoTrack/**/*.{h,m}"
    g.public_header_files = 'SensorsAnalyticsSDK/AutoTrack/SensorsAnalyticsSDK+SAAutoTrack.h'
  end

# 可视化相关功能，包含可视化全埋点和点击图
  s.subspec 'Visualized' do |f|
    f.dependency 'SensorsAnalyticsSDK/AutoTrack'
    f.source_files = "SensorsAnalyticsSDK/Visualized/**/*.{h,m}"
    f.public_header_files = 'SensorsAnalyticsSDK/Visualized/SensorsAnalyticsSDK+Visualized.h'
  end

  # 开启 GPS 定位采集
  s.subspec 'Location' do |f|
    f.frameworks = 'CoreLocation'
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = "SensorsAnalyticsSDK/Location/**/*.{h,m}"
    f.private_header_files = 'SensorsAnalyticsSDK/Location/**/*.h'
#    f.exclude_files = "SensorsAnalyticsSDK/Location/**/*.{h,m}"
  end

  # 开启设备方向采集
  s.subspec 'DeviceOrientation' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = 'SensorsAnalyticsSDK/DeviceOrientation/**/*.{h,m}'
    f.private_header_files = 'SensorsAnalyticsSDK/DeviceOrientation/**/*.h'
    f.frameworks = 'CoreMotion'
  end

  # 推送点击
  s.subspec 'AppPush' do |f|
    f.dependency 'SensorsAnalyticsSDK/Core'
    f.source_files = "SensorsAnalyticsSDK/AppPush/**/*.{h,m}"
    f.private_header_files = 'SensorsAnalyticsSDK/AppPush/**/*.h'
  end

  # 使用崩溃事件采集
  s.subspec 'Exception' do |e|
    e.dependency 'SensorsAnalyticsSDK/Common'
    e.source_files  =  "SensorsAnalyticsSDK/Exception/**/*.{h,m}"
    e.private_header_files = 'SensorsAnalyticsSDK/Exception/**/*.h'
  end

  # 使用 UIWebView 或者 WKWebView 进行打通
  s.subspec 'WebView' do |w|
    w.dependency 'SensorsAnalyticsSDK/Core'
    w.source_files  =  "SensorsAnalyticsSDK/WebView/**/*.{h,m}"
    w.public_header_files = 'SensorsAnalyticsSDK/WebView/SensorsAnalyticsSDK+WebView.h'
  end

  # 使用 WKWebView 进行打通
  s.subspec 'WKWebView' do |w|
    w.dependency 'SensorsAnalyticsSDK/Core'
    w.source_files  =  "SensorsAnalyticsSDK/WKWebView/**/*.{h,m}"
    w.public_header_files = 'SensorsAnalyticsSDK/WKWebView/SensorsAnalyticsSDK+WKWebView.h'
  end

end
