//
//  FURequestManager.m
//  FUP2A
//
//  Created by L on 2018/7/30.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FURequestManager.h"
#import <AFNetworking.h>
#import "FUManager.h"

@interface FURequestManager()

@property (nonatomic, strong) AFHTTPSessionManager *requestManager;
@property(nonatomic,copy) void(^requestResultBlock)(NSData *data, NSError *error);

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

- (void)createQAvatarWithImage:(UIImage *)image Params:(NSDictionary *)params CompletionWithData:(void (^)(NSData *data, NSError *error))handle {
    
    if (handle) {
        self.requestResultBlock = handle ;
    }

    __weak typeof(self)weakSelf = self ;
    [_requestManager GET:TOKENURL parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        NSString *ret = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"====== ret: %@", ret);

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf uploadImageWith:image params:params token:ret qType:[FUManager shareInstance].avatarStyle == FUAvatarStyleQ];
        });

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        weakSelf.requestResultBlock(nil, error) ;
        weakSelf.requestResultBlock = nil ;
    }];
}

- (void)uploadImageWith:(UIImage *)image params:(NSDictionary *)params token:(NSString *)token qType:(BOOL)qType {
    
    NSString *version = qType ? @"1.0.4" : @"1.0.2" ;
    
    NSData *imageData = UIImagePNGRepresentation(image) ;
    
    BOOL gender = [params[@"gender"] boolValue];
    params = @{
               @"gender":@(gender),
               @"version": version,
               };
    
    NSString *url = [[UPLOADURL stringByAppendingString:@"?access_token="] stringByAppendingString:token];
    __weak typeof(self)weakSelf = self ;
    [_requestManager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:imageData name:@"image" fileName:@"image" mimeType:@"image/jpeg"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (uploadProgress.completedUnitCount == uploadProgress.totalUnitCount) {
            NSLog(@"------------ upload image completed ~");
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSData *responData = (NSData *)responseObject ;
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responData options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"====== dict: %@", dict);
        
        NSString *taskid = dict[@"data"][@"taskid"] ;
        NSLog(@"====== task_id: %@", taskid);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf downloadDataWithTask:taskid token:token];
        });
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        weakSelf.requestResultBlock(nil, error) ;
        weakSelf.requestResultBlock = nil ;
    }];
}

- (void)downloadDataWithTask:(NSString *)taskID token:(NSString *)token {
    NSDictionary *params = @{@"taskid":taskID};
    
    NSString *url = [[DOWNLOADURL stringByAppendingString:@"?access_token="] stringByAppendingString:token];
    __weak typeof(self)weakSelf = self ;
	[_requestManager POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
	} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
		NSData *jsonData = (NSData *)responseObject ;
		
		NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
		NSLog(@"====== dict: %@", dict);
		int code = (int)dict[@"code"];
		NSString * message = dict[@"message"];
		NSError  *error = [[NSError alloc]init];
		if ([message isEqualToString:@"FAILED"]) {
		     NSString* str = @"上传的图片未检测到人脸！";
             NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
		     weakSelf.requestResultBlock(data, error) ;
			// [SVProgressHUD showErrorWithStatus:@"上传的图片未检测到人脸！"];
		}else{
			NSString *dataString = dict[@"data"];
			
			NSData *data = [[NSData alloc] initWithBase64EncodedString:dataString options:NSDataBase64DecodingIgnoreUnknownCharacters] ;
			
			weakSelf.requestResultBlock(data, nil) ;
		}
	} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
	}];
}

@end
