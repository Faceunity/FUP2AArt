//
//  FURequestManager.m
//  FUP2A
//
//  Created by L on 2018/7/30.
//  Copyright © 2018年 L. All rights reserved.
//



NSString * TOKENURL;      // 获取token地址，现在是从json文件获取
NSString * UPLOADURL;    // 上传图片地址，现在是从json文件获取
NSString * DOWNLOADURL; // 下载avatar地址，现在是从json文件获取
NSString * NetConfigVersion;   // 作为区分请求客户端的字段
#define FUCurrentClient   @"master"     // 定义当前客户，用于取得相应的网络配置
@interface FURequestManager()
@property (nonatomic, strong) AFHTTPSessionManager *requestManager;
@property(nonatomic,copy) void(^requestResultBlock)(NSData *data, NSError *error);
@property(nonatomic,copy) FURequestResultDicBlock requestResultDicBlock;
@property (nonatomic, assign) CFAbsoluteTime startDownloadTime;
@end

static FURequestManager *sharedInstance;

@implementation FURequestManager

+ (FURequestManager *)sharedInstance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[FURequestManager alloc] init];
	});
	
	return sharedInstance;
}

-(instancetype)init
{
	self = [super init];
	
	if (self) {
		
		// 获取各个客户网络请求的配置文件，并设置
		NSString *netConfigPath = [[NSBundle mainBundle] pathForResource:@"netconfig" ofType:@"json"];
		NSData *tmpData = [[NSString stringWithContentsOfFile:netConfigPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
		if (tmpData != nil) {
			NSMutableDictionary *netConfigDic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
			NSDictionary * currentClientConfigDic = netConfigDic[FUCurrentClient];
			TOKENURL = currentClientConfigDic[@"TOKENURL"];
			UPLOADURL = currentClientConfigDic[@"UPLOADURL"];
			DOWNLOADURL = currentClientConfigDic[@"DOWNLOADURL"];
			NetConfigVersion = currentClientConfigDic[@"NetConfigVersion"];
		}
		
		AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
		policy.allowInvalidCertificates = YES;
		policy.validatesDomainName = NO;
		
		_requestManager=[AFHTTPSessionManager manager];
		_requestManager.securityPolicy = policy;
		_requestManager.requestSerializer = [AFHTTPRequestSerializer serializer];
		_requestManager.requestSerializer.timeoutInterval = 60.0;
		_requestManager.responseSerializer = [AFHTTPResponseSerializer serializer];
		
		NSMutableSet *mset=[[_requestManager.responseSerializer acceptableContentTypes] mutableCopy];
		[mset addObject:@"text/html"];
		
		[_requestManager.responseSerializer setAcceptableContentTypes:mset];
		
		__weak typeof(self)weakSelf = self;
		
		//https客户端证书设置
		[_requestManager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession*session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing*_credential) {
			NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
			__autoreleasing NSURLCredential *credential =nil;
			if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
				if([weakSelf.requestManager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
					credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
					if(credential) {
						disposition =NSURLSessionAuthChallengeUseCredential;
					} else {
						disposition =NSURLSessionAuthChallengePerformDefaultHandling;
					}
				} else {
					disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
				}
			} else {
				// client authentication
				SecIdentityRef identity = NULL;
				SecTrustRef trust = NULL;
				NSString *p12 = [[NSBundle mainBundle] pathForResource:@"p2a_demo" ofType:@"p12"];
				NSFileManager *fileManager =[NSFileManager defaultManager];
				
				if(![fileManager fileExistsAtPath:p12]) {
					NSLog(@"client.p12:not exist");
				} else {
					NSData *PKCS12Data = [NSData dataWithContentsOfFile:p12];
					
					if ([[weakSelf class] extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data])
					{
						SecCertificateRef certificate = NULL;
						SecIdentityCopyCertificate(identity, &certificate);
						const void*certs[] = {certificate};
						CFArrayRef certArray =CFArrayCreate(kCFAllocatorDefault, certs,1,NULL);
						credential =[[NSURLCredential alloc] initWithIdentity:identity certificates:(__bridge  NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
						disposition =NSURLSessionAuthChallengeUseCredential;
					}
				}
			}
			*_credential = credential;
			return disposition;
		}];
	}
	
	return self;
}

+ (BOOL)extractIdentity:(SecIdentityRef*)outIdentity andTrust:(SecTrustRef *)outTrust fromPKCS12Data:(NSData *)inPKCS12Data {
	OSStatus securityError = errSecSuccess;
	//client certificate password
	NSDictionary*optionsDictionary = [NSDictionary dictionaryWithObject:@""
																 forKey:(__bridge id)kSecImportExportPassphrase];
	
	CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
	securityError = SecPKCS12Import((__bridge CFDataRef)inPKCS12Data,(__bridge CFDictionaryRef)optionsDictionary,&items);
	
	if(securityError == 0) {
		CFDictionaryRef myIdentityAndTrust =CFArrayGetValueAtIndex(items,0);
		const void*tempIdentity =NULL;
		tempIdentity= CFDictionaryGetValue (myIdentityAndTrust,kSecImportItemIdentity);
		*outIdentity = (SecIdentityRef)tempIdentity;
		const void*tempTrust =NULL;
		tempTrust = CFDictionaryGetValue(myIdentityAndTrust,kSecImportItemTrust);
		*outTrust = (SecTrustRef)tempTrust;
	} else {
		NSLog(@"Failedwith error code %d",(int)securityError);
		return NO;
	}
	return YES;
}

- (void)createQAvatarWithImage:(UIImage *)image Params:(NSDictionary *)params CompletionWithData:(FURequestResultDicBlock)handle {
	
	if (handle) {
		self.requestResultDicBlock = handle ;
	}
	BOOL isQType = [FUManager shareInstance].avatarStyle == FUAvatarStyleQ;
	__weak typeof(self)weakSelf = self ;
	//NSString *tokenURL = TOKENURL;
	NSMutableDictionary * paramsDic = [NSMutableDictionary dictionary];
	paramsDic[@"company"] = @"faceunity";
	paramsDic[@"type"] = @"QStyle";
	CFAbsoluteTime startUpdateTime = CFAbsoluteTimeGetCurrent() ;
    
    
	[_requestManager GET:TOKENURL parameters:paramsDic progress:^(NSProgress * _Nonnull downloadProgress) {
	} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
		NSDictionary *ret = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
		NSLog(@"====== ret: %@", ret);
        
        NSLog(@"------------ avatar token time: %f ms", (CFAbsoluteTimeGetCurrent() - startUpdateTime) * 1000.0);
		NSString *latestVersion = ret[@"latest"];
		NSString *token = ret[@"token"];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if ([NetConfigVersion compare:latestVersion options:NSNumericSearch]) {  // 当前版本号小于网上版本号
			NSError * error = [NSError errorWithDomain:@"" code:FUAppVersionInvalid userInfo:nil];
			//	[SVProgressHUD showErrorWithStatus:@"testflight 有新版本APP，请您更新"];
				weakSelf.requestResultDicBlock(NO,nil, error);
				return ;
			}
			[weakSelf uploadImageWith:image params:params token:token qType:isQType];
		});
		
	} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
		weakSelf.requestResultDicBlock(NO,nil, error) ;
		weakSelf.requestResultDicBlock = nil ;
	}];
}

- (void)uploadImageWith:(UIImage *)image params:(NSDictionary *)params token:(NSString *)token qType:(BOOL)qType {
	NSError * error;
	
	
	NSData *imageData = UIImagePNGRepresentation(image) ;
	
	BOOL gender = [params[@"gender"] boolValue];
	NSDictionary * paramsDic = @{@"client_type": @(1)};
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:paramsDic options:NSJSONWritingPrettyPrinted error:&error];
	NSString * jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	params = @{
		@"gender":@(gender),
		@"version": NetConfigVersion,
		//      @"params" : jsonStr,
	};
	
	NSString *url = [[UPLOADURL stringByAppendingString:@"?access_token="] stringByAppendingString:token];
	__weak typeof(self)weakSelf = self ;
    CFAbsoluteTime startUpdateTime = CFAbsoluteTimeGetCurrent() ;

    
	[_requestManager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
		[formData appendPartWithFileData:imageData name:@"image" fileName:@"image" mimeType:@"image/jpeg"];
	} progress:^(NSProgress * _Nonnull uploadProgress) {
		
		if (uploadProgress.completedUnitCount == uploadProgress.totalUnitCount) {
			NSLog(@"------------ upload image completed ~");
		}
		
	} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
		NSLog(@"------------ avatar upload time: %f ms", (CFAbsoluteTimeGetCurrent() - startUpdateTime) * 1000.0);
		NSData *responData = (NSData *)responseObject ;
		
		NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responData options:NSJSONReadingAllowFragments error:nil];
		NSLog(@"====== dict: %@", dict);
		
		NSString *taskid = dict[@"data"][@"taskid"] ;
		NSLog(@"====== task_id: %@", taskid);
		weakSelf.startDownloadTime = CFAbsoluteTimeGetCurrent() ;
		[weakSelf downloadDataWithTask:taskid token:token];
		
	} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
		weakSelf.requestResultDicBlock(NO,nil, error) ;
		weakSelf.requestResultDicBlock = nil ;
	}];
}

- (void)downloadDataWithTask:(NSString *)taskID token:(NSString *)token {
	NSDictionary *params = @{@"taskid":taskID,@"encoding":@"url"};
	
	NSString *url = [[DOWNLOADURL stringByAppendingString:@"?access_token="] stringByAppendingString:token];
	__weak typeof(self)weakSelf = self ;
    CFAbsoluteTime startUpdateTime = CFAbsoluteTimeGetCurrent() ;
    
    
	[_requestManager POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
        
	} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
		NSData *jsonData = (NSData *)responseObject ;
		NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
		NSLog(@"====== dict: %@", dict);
		int code = [dict[@"code"] intValue];
		NSString * message = dict[@"message"];
		if (code == 2) {   // 代表成功
            NSLog(@"------------ avatar downloadTry time: %f ms", (CFAbsoluteTimeGetCurrent()  - weakSelf.startDownloadTime  ) * 1000.0);
			weakSelf.requestResultDicBlock(YES,dict, nil) ;
			
		}else if (code == 1 && [message isEqualToString:@"PROCESSING"] )  // 代表处理中
		{
			[weakSelf downloadDataWithTask:taskID token:token];
		}else if (code == 1 &&  [message isEqualToString:@"FAILED"] )   // 代表生成失败，需要处理错误码
		{
			weakSelf.requestResultDicBlock(NO,dict, nil);
		}
		
		
	} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
	}];
}

@end
