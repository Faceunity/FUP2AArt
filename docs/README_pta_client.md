#  PTA Client(iOS)

```objective-c
/**
*  初始化 FUP2AClient data
- 需要先初始化 data 才能使用其他接口，全局只需要初始化 data 一次

*	@param coreDataPath		p2a_client_core 文件路径
*	@param package			密钥数组，必须配置好密钥，SDK 才能正常工作
*	@param size				密钥数组大小
*/
-(void)setupCore:(NSString *)coreDataPath
	authPackage : (void *)package
	authSize : (int)size;

/**
*	切换 FUP2AClient data

*	@param customDataPath  customData 文件路径
*/
-(void)setupCustomData:(NSString *)customDataPath;

/**
*  生成 head.bundle
- 根据服务端传回的数据流生成 Avatar 的头部模型

*  @param data				server.bundle 或 head.bundle
*  @param withExprOnly_		是否生成只包含expression的bundle
*  @param withLowp_			是否生成低精度的bundle

*  @return			生成的头部模型数据
*/
-(fuPTAHeadBundle *)createHeadWithData:(NSData *)data
	withExprOnly : (BOOL)withExprOnly
	withLowp : (BOOL)withLowp;

/**
*  生成 hair.Bundle
- 根据服务端传回的数据流和预置的头发模型 生成和此头部模型匹配的头发模型

*  @param headData		server.bundle 或 head.bundle
*  @param hairData		预置头发模型数据

*  @return				生成的头发模型数据
*/
-(NSData *)createHairWithHeadData:(NSData *)headData
	defaultHairData : (NSData *)hairData;

/**
*  对已现有头部模型进行编辑
- 对现有的头部模型进行形变处理，生成一个新的头部模型

*  @param headData			现有的头部模型数据, head.bundle
*  @param deformParams		形变参数
*  @param paramsSize		形变参数大小
*  @param withExprOnly		是否生成只包含expression的bundle
*  @param withLowp			是否生成低精度的bundle

*  @return					新的头部模型数据
*/
-(fuPTAHeadBundle *)deformHeadWithHeadData:(NSData *)headData
	deformParams : (float *)deformParams
	paramsSize : (NSInteger)paramsSize
	withExprOnly : (BOOL)withExprOnly
	withLowp : (BOOL)withLowp;

/**
*  传入头的数据

*  @param  data			服务端返回的数据流

*  @return				是否成功
*/
-(BOOL)setHeadData:(NSData *)data;

/**
*  释放库内的头数据
*/
-(void)releaseHeadData
  
/**
*  通过参数名获取int参数
*  @param key			参数名

*  @return				返回的参数
*/
-(int)getInt:(NSString *)key;

/**
*  通过参数名获取float参数
*  @param key			参数名

*  @return				返回的参数
*/
-(float)getFloat:(NSString *)key;

/**
*  通过参数名获取float数组参数
*  @param key			参数名

*  @return				返回的参数
*/
-(NSArray *)getFloatArray:(NSString *)key;

/**
*  通过参数名获取字符串参数
*  @param key			参数名

*  @return				返回的参数
*/
-(NSString *)getString:(NSString *)key;

/**
*  释放 client 数据
- 释放 client 全部数据，重新加载 client 之前需要释放数据
*/
-(void)releaseClientData;

/**
*  获取 FUClient 版本号

*  @return			client 版本号
*/
-(NSString *)getVersion;

```

