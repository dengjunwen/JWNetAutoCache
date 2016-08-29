Pod::Spec.new do |s|
  s.name         = "JWNetAutoCache"
  s.version      = "0.0.1"
  s.summary      = "iOS web资源缓存解决方案、异步后台更新。离线缓存"

  s.description  = <<-DESC
                   JWNetAutoCache  离线加载，自动缓存已经加载过的资源、对已经加载过的资源进行异步更新。有缓存时加载缓存，并且策略性的去更新加载的资源。达到既能最快显示，又能后台异步更新资源的目的。同时还可以在有缓存的情况下防止白屏
                   DESC
  s.homepage     = "https://github.com/dengjunwen/JWNetAutoCache"
  s.license      = "MIT (example)"
  s.author             = { "dengjunwen" => "dengjunwen1992@163.com" }
  s.source       = { :git => "https://github.com/dengjunwen/JWNetAutoCache.git", :tag => "0.0.1" }
  s.requires_arc = true
end
