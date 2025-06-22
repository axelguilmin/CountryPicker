Pod::Spec.new do |s|
  s.name                    = 'CountryPicker'
  s.version                 = '3.0.0'
  s.summary                 = "CountryPicker, fork of ADCountryPicker, is a swift country picker controller. Provides country name, ISO 3166 country codes, and calling codes"
  s.homepage                = "https://github.com/axelguilmin/CountryPicker"
  s.license                 = { :type => "MIT", :file => "LICENSE" }
  s.author                  = { "Axel Guilmin"  => "https://github.com/axelguilmin/CountryPicker" }
  s.platform                = :ios
  s.ios.deployment_target   = "13.0"
  s.source                  = { :git => "https://github.com/axelguilmin/CountryPicker.git", :tag => '3.0.0' }
  s.source_files            = 'Source/*.swift'
  s.resources               = ['Source/CallingCodes.plist']
  s.requires_arc            = true
end
