source 'https://cdn.cocoapods.org/'



platform :ios,  '8.0'
install! 'cocoapods',
:disable_input_output_paths => true

target 'FUP2A' do
  pod 'SVProgressHUD', '~> 2.0.3'
	pod 'AFNetworking', '3.1.0', :subspecs => ['Serialization', 'Security', 'NSURLSession', 'Reachability']
	# 解决 apple Deprecated API Usage - Apple will stop accepting submissions of apps that use UIWebView APIs 上架问题
  pod 'SDWebImage', '4.4.2'
  pod 'Masonry',  '1.1.0'
	pod 'Bugly'
end
