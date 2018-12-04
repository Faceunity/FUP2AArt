//
//  FURequestManager.m
//  FUP2A
//
//  Created by L on 2018/7/30.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FURequestManager.h"
#import <AFNetworking.h>


@interface FURequestManager()

@property (nonatomic, strong) AFHTTPSessionManager *requestManager;

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

                if(![fileManager fileExistsAtPath:p12])
                {
                    NSLog(@"client.p12:not exist");
                }
                else
                {
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


-(NSString *)serverShortString {
    
    return @"URL";
//    NSString *server ;
//    if ([_servicerString isEqualToString:Server6820181]) {
//        server = @"68:1" ;
//    }else if ([_servicerString isEqualToString:Server6820182]){
//        server = @"68:2" ;
//    }else if ([_servicerString isEqualToString:Server8620181]){
//        server = @"86:1" ;
//    }else if ([_servicerString isEqualToString:Server8620182]){
//        server = @"86:2" ;
//    }
//    _serverShortString = [@"URL:" stringByAppendingString:server];
//    return _serverShortString ;
}

- (void)createQAvatarWithImage:(UIImage *)image Params:(NSDictionary *)params CompletionWithData:(void (^)(NSData *data, NSError *error))handle {
    
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0) ;
    
    CFAbsoluteTime startUpdateTime = CFAbsoluteTimeGetCurrent() ;
    
    [_requestManager POST:URL parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [formData appendPartWithFileData:imageData name:@"input" fileName:@"image" mimeType:@"image/jpeg"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (uploadProgress.completedUnitCount == uploadProgress.totalUnitCount) {
            NSLog(@"------------ upload image time: %f ms", (CFAbsoluteTimeGetCurrent() - startUpdateTime) * 1000.0);
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSData *data = (NSData *)responseObject ;
        NSLog(@"------------ server time: %f ms", (CFAbsoluteTimeGetCurrent() - startUpdateTime) * 1000.0);
        handle(data, nil) ;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        handle(nil, error) ;
    }];
}

@end
