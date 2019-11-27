

Pod::Spec.new do |s|

  s.name          = "PlateKeyboard_iOS"
  s.version       = "0.9.2"
  s.summary       = "停车王ios车牌键盘，支持原生输入框及格子样式输入框"
  s.homepage      = "https://github.com/parkingwang/PlateKeyboard_iOS"
  s.license       = { :type => 'MIT', :file => 'LICENSE' }
  s.author        = { "yzh" => "shang1219178163@gmail.com" }
  s.platform      = :ios, "8.0"
  s.source        = { :git => "https://github.com/parkingwang/PlateKeyboard_iOS.git", :tag => "#{s.version}" }
  s.source_files  = ["Source/*/*/*.{h,m,swift}","Source/*/*.{h,m,swift}"]
  s.resource      = ["Source/*/*/*.{bundle,xib}","Source/*/*.{bundle,xib}"]
  s.requires_arc  = true
  s.swift_version = "5.0"
end
