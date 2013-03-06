Gem::Specification.new do |s|
  s.name    = "ysd_md_payment"
  s.version = "0.2.1"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2013-02-26"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb','spec/**/*.rb']
  s.description = "Payment"
  s.summary = "Payment"
  s.homepage = "http://github.com/yuraksisa/ysd_md_payment"

  s.add_runtime_dependency "json"
  s.add_runtime_dependency "tilt"
  s.add_runtime_dependency "ysd_md_configuration"
  s.add_runtime_dependency "r18n-core"
  
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"

end
