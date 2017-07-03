
Pod::Spec.new do |s|
  s.name         = "SMOSmImagebarcode"
  s.version      = "1.0.0"
  s.summary      = "SMOSmImagebarcode"
  s.description  = <<-DESC
                  SMOSmImagebarcode
                   DESC
  s.homepage     = ""
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/author/SMOSmImagebarcode.git", :tag => "master" }
  s.source_files  = "SMOSmImagebarcode/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

  