# PTA Client SDK-iOS

本文主要介绍了如何快速跑通我们的FUPTA工程 、如何创建和编辑风格化形象、如何绘制风格化形象、SDK的分类及相关资源说明等。工程中会使用到两个库文件:FUP2AClient SDK、Nama SDK，其中 FUP2AClient SDK 用来做风格化形象的生成，Nama SDK 用来做风格化形象的绘制。

更新日志：
1. 捏脸维度升级。目前支持65个维度。支持脸型，眼型，鼻型，嘴型4大区域。
2. 捏脸交互升级。各个角度智能显示捏脸点位。支持用户实时拖拽点位，实现捏脸调整。
3. 表情包，合影接口升级。方便用户更快捷的接入相应功能。
4. 性能优化，内存优化。

## 快速开始

下载工程后需要先获取一个证书：

* authpack.h：Nama SDK鉴权证书，用于在客户端，使用Nama SDK 绘制的鉴权。

将authpack.h文件添加至工程目录下，然后直接运行工程即可。

## 资源说明

### SDK

- **FUP2AClient.framework**： FUP2AClient SDK 负责头和头发的创建，以及头部编辑的功能。不需要鉴权即可使用。
- **libnama.a**: Nama SDK，进行风格化形象绘制，需要有鉴权证书才能使用。Nama SDK的接口与资源详细说明，请查看[FULiveDemo 说明文档](https://github.com/Faceunity/FULiveDemo)。

### 道具

- **controller.bundle**：风格化形象的控制中心，负责绑定头、身体、衣服、胡子、头发、AR滤镜、眼镜、帽子等配饰。并负责捏脸、发色修改、胡子颜色修改、肤色修改、唇色修改、配饰颜色修改、缩放、旋转、身体动画、AR模式、人脸跟踪、表情裁剪等诸多功能的控制。实际绘制时只需要将controller道具的句柄传入Nama的render接口进行绘制即可，关于controller参数使用方法，请查看[controller说明文档](Controller%20%E8%AF%B4%E6%98%8E%E6%96%87%E6%A1%A3.md)。

- **head.bundle**：头道具，不同的人生成的头不一样，需要绑定到controller道具上才能使用。
- **body.bundle**：身体道具，男女各一个身体，需要绑定到controller道具上才能使用。
- **hair.bundle**：预置头发道具，用于形象生成时生成与头道具大小相匹配的头发道具。可以修改发色，新生成的头发道具需要绑定到controller道具上才能使用。
- **beard.bundle**：胡子道具，有多种款式，可以修改胡子颜色，需要绑定到controller道具上才能使用。
- **eyebrow.bundle**：眉毛道具，有多种款式，需要绑定到controller道具上才能使用。
- **eyelash.bundle**：睫毛道具，有多种款式，需要绑定到controller道具上才能使用。
- **clothes.bundle**：衣服道具，有多种款式，需要绑定到controller道具上才能使用。
- **glass.bundle**：眼镜道具，有多种款式，可以修改镜框及镜片颜色，需要绑定到controller道具上才能使用。
- **animation.bundle**：动画道具，有多种动画类型，需要绑定到controller道具上才能使用。
- **bg.bundle**：背景道具，有多种背景道具，无需绑定到controller道具上，需和controller道具一样传入Nama的render接口进行绘制才行。

## 功能简介

本工程主要包括以下功能：

* 形象生成：上传照片到服务端对人脸进行检测，利用服务端返回的数据生成风格化形象；对风格化形象进行美型后，重新生成形象。
* 形象绘制：实现风格化形象的实时绘制。
* 形象驱动：通过人脸驱动风格化形象。
* 形象编辑：支持美型，以及对肤色、唇色、瞳色、发型、胡子、眼镜、帽子、衣服的个性化编辑；
* 形象应用：支持单人场景、多人场景、动画场景的合影和 GIF动图的导出；

## 形象生成

首先上传照片到服务端做人脸检测，并得到服务端返回的数据，然后使用服务端返回的数据调用FUP2AClient SDK来创建头和头发道具。另外当对风格化形象进行美型后，也需要重新生成形象的头道具。主要流程如下：

* 上传照片
* 初始化 FUP2AClient SDK 
* 使用 FUP2AClient SDK 生成头道具
* 使用 FUP2AClient SDK 生成头发道具
* 使用 FUP2AClient SDK 重新生成头道具

### 上传照片

用户上传照片到服务端，服务端对该图片做人脸检测，并返回检测后的人脸数据： server.bundle。server.bundle 包含用户的发型、肤色、眼镜、唇色、脸型等详细信息。

### 初始化 FUP2AClient SDK 

调用 FUP2AClient SDK 相关接口前，需要先进行初始化，且只需要初始化一次。

初始化接口说明如下：

```objective-c
/**
 *  初始化 FUP2AClient data
 *      - 需要先初始化 data 才能使用其他接口，全局只需要初始化 data 一次
 
 *  @param data     p2a_client.bin 的 data 数据
 */
+ (void)setupWithClientData:(NSData *)data ;
```

### 生成头道具

使用 server.bundle 调用 FUP2AClient SDK 相关接口便可以生成头道具，相关API接口说明如下：

```objective-c
/**
 *  生成 head.bundle
        - 根据服务端传回的数据流生成风格化形象的头部模型
 
 *  @param data        服务端传回的数据流
 
 *  @return            生成的头部模型数据
 */
+ (NSData *)createAvatarHeadWithData:(NSData *)data ;
```

注：该接口支持异步并行调用。

### 生成头发道具

使用 server.bundle 与预置的 hair.bundle，调用 FUP2AClient SDK 相关接口，生成与头道具大小相匹配的头发道具，相关API接口说明如下：

```objective-c
/**
 *  生成 hair.Bundle
        - 根据服务端传回的数据流和预置的头发模型 生成和此头部模型匹配的头发模型
 
 *  @param serverData   服务端传回的数据流
 *  @param hairData     预置头发模型数据
 
 *  @return            生成的头发模型数据
 */
+ (NSData *)createAvatarHairWithServerData:(NSData *)serverData
                           defaultHairData:(NSData *)hairData ;
```

注：该接口支持异步并行调用。

### 重新生成头道具

对风格化形象进行美型后，重新生成形象的头道具。需要调用 FUP2AClient SDK 的 deformAvatarHeadWithHeadData 接口生成新的头道具，API接口说明如下：

API接口说明如下：

```objective-c
/**
 *  对已存在的头部模型进行编辑
    - 对现有的头部模型进行形变处理，生成一个新的头部模型
 
 *  @param headData         现有的头部模型数据
 *  @param deformParams     形变参数
 *  @param paramsSize       形变参数大小
 
 *  @return                 新的头部模型数据
 */
+ (NSData *)deformAvatarHeadWithHeadData:(NSData *)headData
                   deformParams:(float *)deformParams
                              paramsSize:(NSInteger)paramsSize;
```

注：该接口支持异步并行调用。

## 形象绘制

使用 FUP2AClient SDK 生成的风格化形象，目前支持通过 Nama SDK 进行绘制，后续将支持使用其他绘制引擎进行绘制，如 Unity 3D。使用 Nama SDK 进行绘制，主要流程如下：

* 初始化 Nama SDK
* 道具加载与绑定
* 道具绘制
* 道具的解绑与销毁

### 初始化 Nama SDK

使用 Nama SDK 前，需要先对 Nama SDK 进行初始化。初始化接口说明如下：

```objective-c
/**
 初始化接口3：
     - 初始化SDK，并对 SDK 进行授权，在调用其他接口前必须要先进行初始化。
     - 与 初始化接口2 相比改为通过 v3.bundle 的文件路径进行初始化，并且删除了废弃的 ardata 参数。
 
 @param v3path v3.bundle 对应的文件路径
 @param package 密钥数组，必须配置好密钥，SDK 才能正常工作
 @param size 密钥数组大小
 @param shouldCreate  如果设置为 YES，我们会在内部创建并持有一个 EAGLContext，此时必须使用OC层接口
 */
- (void)setupWithDataPath:(NSString *)v3path authPackage:(void *)package authSize:(int)size shouldCreateContext:(BOOL)shouldCreate;
```

### 道具加载与绑定

加载风格化形象相关道具时，需要先加载controller道具，然后再加载道具分类中的其他道具，并将这些道具绑定到 controller 道具上（背景道具除外）。道具的加载与绑定相关API如下：

```objective-c
/**
 通过道具文件路径创建道具：
     - 通过道具文件路径创建道具句柄
 
 @param path 道具文件路径
 @return 创建的道具句柄
 */
+ (int)itemWithContentsOfFile:(NSString *)path;

/**
 绑定道具：
     -  该接口可以将一些普通道具绑定到某个目标道具上，从而实现道具间的数据共享，在视频处理时只需要传入该目标道具句柄即可
 
 @param item 目标道具句柄
 @param items 需要被绑定到目标道具上的其他道具的句柄数组
 @param itemsCount 句柄数组包含的道具句柄个数
 @return 被绑定到目标道具上的普通道具个数
 */
+ (int)bindItems:(int)item items:(int*)items itemsCount:(int)itemsCount;
```

### 道具绘制

在绘制风格化形象道具时，首先将 controller 道具及背景道具句柄存储到的一个 int 数组中，然后把该 int 数组作为参数传入 renderItems 进行绘制即可。相关接口相关API如下：

```objective-c
/**
 道具绘制接口

 @param inPtr 输入数据
 @param inFormat 输入数据格式
 @param outPtr 输出数据
 @param outFormat 输出数据格式
 @param width 图像宽度
 @param height 图像高度
 @param frameid 当前处理的视频帧序数，每次处理完对其进行加 1 操作，不加 1 将无法驱动道具中的特效动画
 @param items 包含多个道具句柄的 int 数组
 @param itemCount 句柄数组中包含的句柄个数
 @param flip 道具镜像使能，如果设置为 YES 可以将道具做镜像操作
 @return 返回内部纹理ID
 */
- (int)renderItems:(void *)inPtr inFormat:(FUFormat)inFormat outPtr:(void *)outPtr outFormat:(FUFormat)outFormat width:(int)width height:(int)height frameId:(int)frameid items:(int *)items itemCount:(int)itemCount flipx:(BOOL)flip;
```

在绘制风格化形象的模式下，该接口输入的数据格式为 FU_FORMAT_AVATAR_INFO ，输出的数据为渲染好的图像数据，支持多种主流图像格式，也支持输出纹理ID。在输入格式为FU_FORMAT_AVATAR_INFO，输出的图像宽高可以自定义。接口示例如下：

```objective-c
static int frameid = 0 ;
- (CVPixelBufferRef) renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks{
   
    float expression[46] = {0};
    float translation[3] = {0};
    float rotation[4] = {0,0,0,1};
    float rotation_mode[1] = {0};
    float pupil_pos[2] = {0};
    int is_valid = 0 ;
    
    TAvatarInfo info;
    info.p_translation = translation;
    info.p_rotation = rotation;
    info.p_expression = expression;
    info.rotation_mode = rotation_mode;
    info.pupil_pos = pupil_pos;
    info.is_valid = is_valid ;
    
   CVPixelBufferLockBaseAddress(renderTarget, 0);

    void *bytes = (void *)CVPixelBufferGetBaseAddress(renderTarget);
    int stride1 = (int)CVPixelBufferGetBytesPerRow(renderTarget);
    int h1 = (int)CVPixelBufferGetHeight(renderTarget);
    
    [[FURenderer shareRenderer] renderItems:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:bytes outFormat:FU_FORMAT_BGRA_BUFFER width:stride1/4 height:h1 frameId:frameid items:mItems itemCount:3 flipx:NO];
    
    CVPixelBufferUnlockBaseAddress(renderTarget, 0);

    frameid++;
    return renderTarget ;
}
```

其中renderTarget是用来当作输出的pixelBuffer，创建方式如下：

```objective-c
- (void)createPixelBuffer
{
    CGSize size = [UIScreen mainScreen].currentMode.size;
    if (size.width > 850) {
        
        CGFloat a = 0.7;
        CGFloat w = (((int)(size.width*a) + 3)>>2) * 4;
        CGFloat h = (((int)(size.height*a) + 3)>>2) * 4;
        size = CGSizeMake(w, h);
    }
    
    if (!renderTarget) {
        NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
                                                  @(kCVPixelFormatType_32BGRA),
                                              (NSString*) kCVPixelBufferWidthKey : @(size.width),
                                              (NSString*) kCVPixelBufferHeightKey : @(size.height),
                                              (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
                                              (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                            size.width, size.height,
                            kCVPixelFormatType_32BGRA,
                            (__bridge CFDictionaryRef)pixelBufferOptions,
                            &renderTarget);
    }
}
```

### 道具的解绑与销毁

当要切换或去除道具效果时，需先解绑并销毁已绑定的同类型道具，然后再加载绑定新的道具。相关API如下：

```objective-c
/**
 解绑道具：
 -  该接口可以将一些普通道具从某个目标道具上解绑
 
 @param item 目标道具句柄
 @param items 需要从目标道具上解除绑定的普通道具的句柄数组
 @param itemsCount 句柄数组包含的道具句柄个数
 @return 被绑定到目标道具上的普通道具个数
 */
+ (int)unBindItems:(int)item items:(int *)items itemsCount:(int)itemsCount;

/**
 解绑所有道具：
     - 该接口可以解绑绑定在目标道具上的全部道具
 
 @param item 目标道具句柄
 @return 从目标道具上解除绑定的普通道具个数
 */
+ (int)unbindAllItems:(int)item;

/**
 销毁单个道具：
     - 通过道具句柄销毁道具，并释放相关资源
     - 销毁道具后请将道具句柄设为 0 ，以避免 SDK 使用无效的句柄而导致程序出错。
 
 @param item 道具句柄
 */
+ (void)destroyItem:(int)item;
```

### 道具切换与销毁示例

```objective-c
// 加载道具
- (void)loadItemWithtype:(FUItemType)itemType Name:(NSString *)itemName {
    if ([itemName isEqualToString:@"noitem"] || itemName == nil ) {
        // 销毁此道具
        [self destroyItemWithType:itemType];
        return ;
    }
    
    NSString *itemPath = [self bundlePathWithName:itemName];
    
    //创建道具
    int tmpHandle = [FURenderer itemWithContentsOfFile:itemPath];
    
    // 销毁已加载的同类道具
    [self destroyItemWithType:itemType];
    
    // 如果是controller或背景道具，则将道具句柄存放在道具数组中。
    if (itemType == FUItemTypeController || itemType == FUItemTypeBackground) {
        mItems[itemType] = tmpHandle;
    }else{
        // 如果是普通道具，则绑定到controller上
        fuBindItems(mItems[FUItemTypeController], &tmpHandle, 1) ;
    }
}

// 销毁某个道具
- (void)destroyItemWithType:(FUItemType)itemType {
    
    if (mItems[itemType] != 0) {
        
        // 解绑
        if (mItems[FUItemTypeController] && itemType > 2) {
            int tmp[1];
            tmp[0]  = mItems[itemType];
            fuUnbindItems(mItems[FUItemTypeController], tmp, 1) ;
        }
        // 销毁
        [FURenderer destroyItem:mItems[itemType]];
        mItems[itemType] = 0;
    }
}
```

## 形象驱动

形象驱动是指使用 Nama SDK 进行人脸检测，再使用检测到人脸信息驱动风格化形象的功能。流程为：先对人脸进行检测，将获取到人脸信息保存到TAvatarInfo结构体中，再将 TAvatarInfo 作为参数传入 renderItems 接口即可，相关API说明如下：

```objective-c
/**
 人脸信息跟踪：
     - 该接口只对人脸进行检测，如果程序中没有运行过视频处理接口( 视频处理接口8 除外)，则需要先执行完该接口才能使用 获取人脸信息接口 来获取人脸信息
 
 @param inputFormat 输入图像格式：FU_FORMAT_BGRA_BUFFER 或 FU_FORMAT_NV12_BUFFER
 @param inputData 输入的图像 bytes 地址
 @param width 图像宽度
 @param height 图像高度
 @return 检测到的人脸个数，返回 0 代表没有检测到人脸
 */
+ (int)trackFace:(int)inputFormat inputData:(void*)inputData width:(int)width height:(int)height;

/**
 获取人脸信息：
     - 在程序中需要先运行过视频处理接口( 视频处理接口8 除外)或 人脸信息跟踪接口 后才能使用该接口来获取人脸信息；
     - 该接口能获取到的人脸信息与我司颁发的证书有关，普通证书无法通过该接口获取到人脸信息；
     - 具体参数及证书要求如下：
 
         landmarks: 2D人脸特征点，返回值为75个二维坐标，长度75*2
         证书要求: LANDMARK证书、AVATAR证书
 
         landmarks_ar: 3D人脸特征点，返回值为75个三维坐标，长度75*3
         证书要求: AVATAR证书
 
         rotation: 人脸三维旋转，返回值为旋转四元数，长度4
         证书要求: LANDMARK证书、AVATAR证书
 
         translation: 人脸三维位移，返回值一个三维向量，长度3
         证书要求: LANDMARK证书、AVATAR证书
 
         eye_rotation: 眼球旋转，返回值为旋转四元数,长度4
         证书要求: LANDMARK证书、AVATAR证书
 
         rotation_raw: 人脸三维旋转（不考虑屏幕方向），返回值为旋转四元数，长度4
         证书要求: LANDMARK证书、AVATAR证书
 
         expression: 表情系数，长度46
         证书要求: AVATAR证书
 
         projection_matrix: 投影矩阵，长度16
         证书要求: AVATAR证书
 
         face_rect: 人脸矩形框，返回值为(xmin,ymin,xmax,ymax)，长度4
         证书要求: LANDMARK证书、AVATAR证书
 
         rotation_mode: 人脸朝向，0-3分别对应手机四种朝向，长度1
         证书要求: LANDMARK证书、AVATAR证书
 
 @param faceId 被检测的人脸 ID ，未开启多人检测时传 0 ，表示检测第一个人的人脸信息；当开启多人检测时，其取值范围为 [0 ~ maxFaces-1] ，取其中第几个值就代表检测第几个人的人脸信息
 @param name 人脸信息参数名： "landmarks" , "eye_rotation" , "translation" , "rotation" ....
 @param pret 作为容器使用的 float 数组指针，获取到的人脸信息会被直接写入该 float 数组。
 @param number float 数组的长度
 @return 返回 1 代表获取成功，返回 0 代表获取失败
 */
+ (int)getFaceInfo:(int)faceId name:(NSString *)name pret:(float *)pret number:(int)number;
```

示例代码如下：

```objective-c
	float expression[46] = {0};
    float translation[3] = {0};
    float rotation[4] = {0,0,0,1};
    float rotation_mode[1] = {0};
    float pupil_pos[2] = {0};
    int is_valid = 0 ;
    
    if (renderMode == FURenderPreviewMode) {
        CVPixelBufferLockBaseAddress(pixelBuffer, 0) ;
        
        void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) ;
        int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
        int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
        
        [FURenderer trackFace:FU_FORMAT_BGRA_BUFFER inputData:baseAddress width:stride/4 height:height];
        [FURenderer getFaceInfo:0 name:@"expression" pret:expression number:46];
        [FURenderer getFaceInfo:0 name:@"translation" pret:translation number:3];
        [FURenderer getFaceInfo:0 name:@"rotation" pret:rotation number:4];
        [FURenderer getFaceInfo:0 name:@"rotation_mode" pret:rotation_mode number:1];
        [FURenderer getFaceInfo:0 name:@"pupil_pos" pret:pupil_pos number:2];
        
        [FURenderer getFaceInfo:0 name:@"landmarks" pret:landmarks number:150];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0) ;
        
        is_valid = [FURenderer isTracking];
    }

    TAvatarInfo info;
    info.p_translation = translation;
    info.p_rotation = rotation;
    info.p_expression = expression;
    info.rotation_mode = rotation_mode;
    info.pupil_pos = pupil_pos;
    info.is_valid = is_valid ;
```

## 形象编辑

形象编辑功能包括：美型，以及对肤色、唇色、瞳色、发型、胡子、眼镜、帽子、衣服的个性化编辑。

- 通过修改 controller.bundle 的相关参数，可以实现美型、及对肤色、唇色、瞳色、发色、胡子颜色、眼镜颜色、帽子颜色的修改。详情请参考[controller说明文档](Controller%20%E8%AF%B4%E6%98%8E%E6%96%87%E6%A1%A3.md)。
- 通过加载并绑定相关道具到 controller.bundle 道具上，可以对发型、胡子、眼镜、帽子、衣服的样式进行修改。详情请参考[道具加载与绑定](#道具加载与绑定)。

在保存形象时，仅有美型功能需要使用 FUP2AClient SDK 的接口生成新的头道具，而其他参数值及道具（发型、胡子、眼镜、帽子、衣服）信息需要客户端缓存。

## 形象应用
形象应用功能包括：单人场景、多人场景、动画场景。

- 单人场景和多人场景可以分别对单个形象和多个形象进行动作编辑，并保存场景图像到手机系统相册。
- 动画场景可以对形象进行动画编辑，导出形象动画为 GIF动图和MP4视频，默认保存为MP4视频，并保存到手机系统相册。

具体功能接入可以参考 Demo 代码

**更多详情，请参考Demo代码!**
