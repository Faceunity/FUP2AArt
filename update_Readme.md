# 1.6.0 升级1.7.0说明文档

## 1.新增或替换的库/资源

所有资源文件都需要替换，不一一列举

### 替换如下
* libnama.a  
* funama.h
* FURenderer.h
* p2a_client_core.bin
* p2a_client_q1.bin
* v3.bundle
* q_controller.bundle
* head.bundle



### 新增如下
* libfuai.a
* libp2a_client.a
* fuPTAClient.h
q_midBody_female
q_midBody_male

controller_config.bundle

### 删除如下
* FUP2AClient.framework
* mid_body






## 2.fuPTAClient 库代码替换


### 2.1所有FUP2AClient类名替换成fuPTAClient 

### 2.2 替换初始化方法
替换前
```
- (void)loadClientDataWithFirstSetup:(BOOL)firstSetup {
    
    NSString *qPath ;
    switch (self.avatarStyle) {
        case FUAvatarStyleNormal:{
            if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarListPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:AvatarListPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            qPath =[[NSBundle mainBundle] pathForResource:@"p2a_client_q" ofType:@"bin"];
        }
            break;
        case FUAvatarStyleQ:{
            if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarQPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:AvatarQPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            qPath =[[NSBundle mainBundle] pathForResource:@"p2a_client_q1" ofType:@"bin"];
        }
            break ;
    }
    // p2a bin
    if (firstSetup) {
        NSString *corePath = [[NSBundle mainBundle] pathForResource:@"p2a_client_core" ofType:@"bin"];
        [[fuPTAClient shareInstance] setupClientWithCoreDataPath:corePath customDataPath:qPath authPackage:&g_auth_package authSize:sizeof(g_auth_package)];
    }else {
        [[fuPTAClient shareInstance] reSetupCustomData:qPath];
    }
}
```
替换后
```
- (void)loadClientDataWithFirstSetup:(BOOL)firstSetup {
    
    NSString *qPath ;
    switch (self.avatarStyle) {
        case FUAvatarStyleNormal:{
            if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarListPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:AvatarListPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            qPath =[[NSBundle mainBundle] pathForResource:@"p2a_client_q" ofType:@"bin"];
        }
            break;
        case FUAvatarStyleQ:{
            if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarQPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:AvatarQPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            qPath =[[NSBundle mainBundle] pathForResource:@"p2a_client_q1" ofType:@"bin"];
        }
            break ;
    }
    // p2a bin
    if (firstSetup) {
        NSString *corePath = [[NSBundle mainBundle] pathForResource:@"p2a_client_core" ofType:@"bin"];
        [[fuPTAClient shareInstance] setupCore:corePath authPackage:&g_auth_package authSize:sizeof(g_auth_package)];
    }
    [[fuPTAClient shareInstance] setupCustomData:qPath];
}
```




### 2.3 捏脸后新生成头方法修改

```
- (FUAvatar *)createPupAvatarWithCoeffi:(float *)coeffi DeformHead:(BOOL)deform
```
在方法内，替换新头生成的方法

替换前
```
headData = [[fuPTAClient shareInstance] deformAvatarHeadWithHeadData:headData deformParams:coeffi paramsSize:69];
```

替换后
```
headData = [[fuPTAClient shareInstance] deformHeadWithHeadData:headData deformParams:coeffi paramsSize:90 withExprOnly:NO withLowp:NO].bundle;
```


### 2.4 发型适应头生成新bundle的方法替换

将工程中所有以下方法进行替换，注意两个方法的参数的顺序发生了变化
原方法
```
/**
*  对已现有头发模型进行编辑
    - 对现有的头发模型进行精修处理，生成一个当前头部模型匹配的头发模型

*  @param hairData         预置头发模型数据
*  @param headData         当前的头部模型数据

*  @return                 新的头发模型数据
*/

- (NSData *)deformAvatarHairWithDefaultHairData:(NSData *)hairData
currentHeadData:(NSData *)headData ;
```

新方法
```
/**
*  生成 hair.Bundle
- 根据服务端传回的数据流和预置的头发模型 生成和此头部模型匹配的头发模型

*  @param headData        server.bundle 或 head.bundle
*  @param hairData        预置头发模型数据

*  @return                生成的头发模型数据
*/
-(NSData *)createHairWithHeadData:(NSData *)headData
    defaultHairData : (NSData *)hairData;
```



## 绑定道具修改

FUAvatar类中修改道具类型枚举与句柄数组的长度

修改前
```
typedef enum : NSInteger {
    FUItemTypeController        = 0,
    FUItemTypeHead,
    FUItemTypeBody,
    FUItemTypeHair,
    FUItemTypeClothes,
    FUItemTypeGlasses,
    FUItemTypeBeard,
    FUItemTypeHat,
    FUItemTypeShoes,
    FUItemTypeAnimation,
    FUItemTypeEyeLash,
    FUItemTypeEyeBrow,
    FUItemTypeCamera,
    FUItemTypeTmp,
} FUItemType;

@interface FUAvatar ()
{
    // 句柄数组
    int items[14] ;
    // 同步信号量
    dispatch_semaphore_t signal;
}
```
修改后
```
typedef enum : NSInteger {
    FUItemTypeController        = 0,
    FUItemTypeHead,
    FUItemTypeBody,
    FUItemTypeHair,
    FUItemTypeClothes,
    FUItemTypeGlasses,
    FUItemTypeBeard,
    FUItemTypeHat,
    FUItemTypeUpper,   // 上衣
    FUItemTypeLower,   // 裤子
    FUItemTypeShoes,   // 鞋子
    FUItemTypeDecorations,  // 配饰
    FUItemTypeAnimation,
    FUItemTypeEyeLash,
    FUItemTypeEyeBrow,
    FUItemTypeCamera,
    FUItemTypeTmp,
    FUItemTypeARFilter,    // 用于编辑AR滤镜的句柄
} FUItemType;

@interface FUAvatar ()
{
    // 句柄数组
    int items[18] ;
    // 同步信号量
    dispatch_semaphore_t signal;
}
```


body加载方法修改，其中wearFemaleClothes参数表示衣服是男或女，需要加载对应的男女身体
```
//    // load Body
//    NSString *bodyPath = self.isQType ? [[NSBundle mainBundle] pathForResource:@"mid_body.bundle" ofType:nil] : (self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_body" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_body" ofType:@"bundle"]) ;
//    [self loadItemWithtype:FUItemTypeBody filePath:bodyPath];

    
    // load Body
    NSString *bodyPath;
    if (self.isQType) {
        
        if (!self.wearFemaleClothes) {
            bodyPath = [[NSBundle mainBundle] pathForResource:@"q_midBody_male.bundle" ofType:nil] ;
        }else{
            bodyPath = [[NSBundle mainBundle] pathForResource:@"q_midBody_female.bundle" ofType:nil];
        }
    }else{
        bodyPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_body" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_body" ofType:@"bundle"];
    }
    [self loadItemWithtype:FUItemTypeBody filePath:bodyPath];
```


新增controller_config，使用方法如下

FUManager中新增属性和变量
```
@property (nonatomic, assign) int defalutQController;


int q_controller_config_ptr;   // controller 配置文件道具句柄
```

FUManager的init方法中加载controller_config.bundle
```
NSString *controller =   @"q_controller.bundle";
NSString *controllerPath = [[NSBundle mainBundle] pathForResource:controller ofType:nil];
self.defalutQController = [FURenderer itemWithContentsOfFile:controllerPath];

NSString *controller_config_path = [[NSBundle mainBundle] pathForResource:@"controller_config" ofType:@"bundle"];
[self reBindItemWithToController:controller_config_path withPtr:&q_controller_config_ptr];
```
同时增加如下方法
```
/// 重新绑定道具
/// @param filePath 新的道具路径
/// @param ptr 道具句柄
- (void)reBindItemWithToController:(NSString *)filePath withPtr:(int *)ptr{
    if (*ptr > 0) {

    // 解绑
    [FURenderer unBindItems:_defalutQController items:ptr itemsCount:1];
    // 销毁
    [FURenderer destroyItem:*ptr];
    
    }
    *ptr = [self bindItemWithToController:filePath];
    
}
- (int)bindItemWithToController:(NSString *)filePath {
    // 创建道具
    int tmpHandle = [FURenderer itemWithContentsOfFile:filePath];
    [FURenderer bindItems:_defalutQController items:&tmpHandle itemsCount:1];
    return tmpHandle;
}
```
并修改FUAvatar中loadAvatar方法中的获取controller句柄的方式

原方法
```
// load controller
if (items[FUItemTypeController] == 0) {
    NSString *controller = self.isQType ? @"q_controller.bundle" : @"controller.bundle" ;
    NSString *controllerPath = [[NSBundle mainBundle] pathForResource:controller ofType:nil];
    [self loadItemWithtype:FUItemTypeController filePath:controllerPath];
}
```
新方法
```
// load controller
if (items[FUItemTypeController] == 0) {
    items[FUItemTypeController] = [FUManager shareInstance].defalutQController;
}
```
