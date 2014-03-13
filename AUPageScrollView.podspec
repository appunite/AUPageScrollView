Pod::Spec.new do |s|

  s.name         = "AUPageScrollView"
  s.version      = "1.0.1"
  s.summary      = "AUPageScrollView by AppUnite"
  s.homepage     = "http://git.appunite.com"
  s.license      = { :type => 'Apache', :file => 'LICENCE' }
  s.author       = { "Emil Wojtaszek" => "emil@appunite.com" }
  s.platform     = :ios, '5.0'
  s.source       = { :git => "https://github.com/appunite/AUPageScrollView.git", :tag => s.version.to_s }
  s.source_files  = 'Classes', 'Classes/**/*.{h,m}'
  s.requires_arc = true

end
