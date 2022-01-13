//
//  fuPTAClientLite.h
//
//

#import <Foundation/Foundation.h>

__attribute__((visibility("default"))) @interface fuPTAClientLite : NSObject

/**
*  获取版本号

*  @return			client 版本号
*/
+ (NSString*)getVersion;

/**
*	加载数据包

*	@param dataPath  data 文件路径
*/
+ (BOOL)setData:(NSString*)dataPath;

/**
 *	释放已加载的所有数据包
 */
+ (void)releaseData;

/**
*  设置证书

*	@param package			密钥数组，必须配置好密钥，SDK 才能正常工作
*	@param size				  密钥数组大小
*/
+ (BOOL)setAuth:(void*)package authSize:(int)size;

/**
*  设置证书，只本地检验证书

*	@param package			密钥数组，必须配置好密钥，SDK 才能正常工作
*	@param size				  密钥数组大小
*/
+ (BOOL)setAuthInternalCheck:(void*)package authSize:(int)size;

/**
*  设置证书，只本地检验证书，附加额外的验证信息

*	@param package			密钥数组，必须配置好密钥，SDK 才能正常工作
*	@param size				  密钥数组大小
*	@param info				  额外信息数组
*	@param info_size		  额外信息数组大小
*/
+ (BOOL)setAuthInternalCheckEx:(void*)package
                      authSize:(int)size
                          info:(void*)info
                      infoSize:(int)infoSize;

/**
*  设置头bundle

*	@param bundle			头bundle

* @return			    句柄
*/
+ (int)setBundle:(NSData*)bundle;

/**
*  释放句柄

*	@param handle		句柄
*/
+ (void)releaseHandle:(int)handle;

/**
*  生成头

*  @handle      返回的句柄

*  @return			生成是否成功
*/
// + (BOOL)generateHead:(int)handle;

/**
*  捏脸

*  @handle                返回的句柄
*  @param deformParams		捏脸参数
*  @param paramsSize		  捏脸参数长度

*  @return			          生成是否成功
*/
+ (BOOL)facepup:(int)handle deformParams:(float*)deformParams paramsSize:(NSInteger)paramsSize;

/**
*  脸上部件（如胡子）随捏脸一起处理

*  @handle                返回的句柄
*  @param bundle		  待捏脸的bundle

*  @return			      生成是否成功
*/
+ (NSData*)facepupMesh:(int)handle bundle:(NSData*)bundle;

/**
*  获取 head.bundle

*  @handle     返回的句柄
*  @lessBS     删除可删除的bs
*  @lowp       低精度

*  @return			head.bundle
*/
+ (NSData*)getHeadBundle:(int)handle lessBS:(BOOL)lessBS lowp:(BOOL)lowp;

/**
*  deform mesh类型的bundle

*  @handle     返回的句柄
*  @bundle     预置的bundle

*  @return		 deform后的bundle
*/
+ (NSData*)deformMesh:(int)handle bundle:(NSData*)bundle;

/**
*  deform眉毛bundle

*  @handle     返回的句柄
*  @bundle     预置的bundle

*  @return		 deform后的bundle
*/
+ (NSData*)deformBrow:(int)handle bundle:(NSData*)bundle;

/**
*  读取int类型信息

*  @handle     返回的句柄
*  @key        读取信息的键值
*/
+ (int)infoGetInt:(int)handle key:(NSString*)key;

/**
*  读取float类型信息

*  @handle     返回的句柄
*  @key        读取信息的键值
*/
+ (float)infoGetFloat:(float)handle key:(NSString*)key;

/**
*  读取float数组类型信息

*  @handle     返回的句柄
*  @key        读取信息的键值
*/
+ (NSArray*)infoGetFloatVec:(float)handle key:(NSString*)key;

/**
*  读取string类型信息

*  @handle     返回的句柄
*  @key        读取信息的键值
*/
+ (NSString*)infoGetString:(float)handle key:(NSString*)key;

@end
