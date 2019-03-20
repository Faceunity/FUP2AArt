# FU P2A

本文主要介绍了风格化形象从创建到绘制的主要流程，SDK分类及相关接口说明，SDK鉴权以及风格化形象相关道具的分类等内容。

## SDK分类

* FUP2AClient SDK: 负责头和头发的创建与头部编辑的功能，不需要鉴权即可使用。

* nama SDK: 风格化形象绘制相关SDK，需要有鉴权证书才能使用。对于不同的功能我们会提供不同的证书，这里需要使用P2A证书才能使用绘制风格化形象的接口。由于Nama SDK的接口比较多，本文档不会详细介绍相关接口，请移步到[FULiveDemo](https://github.com/Faceunity/FULiveDemo)查看我司namaSDK使用方法。

### 道具分类

- controller道具：风格化形象的控制中心，负责绑定头、身体、衣服、胡子、头发、AR滤镜、眼镜、帽子等配饰，并负责捏脸、发色修改、胡子颜色修改、肤色修改、唇色修改、配饰颜色修改、缩放、旋转、身体动画、AR模式、人脸跟踪、表情裁剪等诸多功能的控制，实际绘制时只需要将controller道具的句柄传入nama的render接口进行绘制即可，关于controller参数使用方法，请查看[controller说明文档](controller.md)。
- 头道具：不同的人生成的头不一样，需要绑定到controller道具上才能使用。
- 身体道具：男女各一个身体，需要绑定到controller道具上才能使用。
- 头发道具：有多种款式，可以修改发色，需要绑定到controller道具上才能使用。
- 胡子道具：有多种款式，可以修改胡子颜色，需要绑定到controller道具上才能使用。
- 衣服道具：有多种款式，需要绑定到controller道具上才能使用。
- 眼镜道具：有多种款式，可以修改镜框及镜片颜色，需要绑定到controller道具上才能使用。
- 动画道具：有多种动画类型，需要绑定到controller道具上才能使用。
- 背景道具：有多种背景道具，无需绑定到controller道具上，需和controller道具一样传入nama的render接口进行绘制才行。


## 流程及接口说明

首先上传照片到服务端做人脸检测，然后使用FUP2AClient SDK通过服务端返回的人脸数据创建头和头发道具，然后利用nama SDK绘制风格化形象的头、身体、头发、衣服、胡子、眼镜等道具。同时可以通过 controller 道具实现捏脸、发色修改、胡子颜色修改、肤色修改、唇色修改、配饰颜色修改、缩放、旋转、身体动画、AR模式、人脸跟踪、表情裁剪等诸多功能，最终可以通过FUP2AClient SDK保存捏脸之后的头道具。

### 上传照片

首先需要上传照片到服务端做用户头像特征检测，并获得检测后的数据结果 server.bundle，server.bundle包含人物的发型、肤色、眼镜、唇色、脸型等详细信息。网络请求接口及参数说明如下：

### 初始化 FUP2AClient SDK

使用 FUP2AClient 相关功能前需要先进行初始化操作，相关API接口说明如下：

```objective-c
/**
 *  初始化 FUP2AClient data
 *      - 需要先初始化 data 才能使用其他接口，全局只需要初始化 data 一次
 
 *  @param data     p2a_client.bin 的 data 数据
 */
+ (void)setupWithClientData:(NSData *)data ;
```

### 生成头和头发道具

使用服务端返回的 server.bundle 并调用 FUP2AClient 的相关接口便可以生成头和头发道具，相关API接口说明如下：

```objective-c
/**
 *  生成 head.bundle
        - 根据服务端传回的数据流生成风格化形象的头部模型
 
 *  @param data        服务端传回的数据流
 
 *  @return            生成的头部模型数据
 */
+ (NSData *)createAvatarHeadWithData:(NSData *)data ;

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

注：这两个接口都支持异步并行调用。

### 修改头道具

使用捏脸功能并需要保存修改后的脸型效果时，需要调用 FUP2AClient 的重新生成头道具的接口，该接口会生成一个新的头道具，API接口说明如下：

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

注：该接口都支持异步并行调用。

### 初始化 nama SDK

使用 nama 相关功能前需要先进行初始化操作，相关API接口说明如下：

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

首先需要加载controller道具，然后再加载道具分类中的其他道具，并将这些道具绑定到controller上（背景道具除外）。在做完一系列的加载与绑定之后，需要将controller道具及背景道具的具柄存储到 int 数组中，然后在调用 Nama 的 render 相关接口时传入该 int 数组即可。道具的加载与绑定相关API如下：

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

/**
 销毁所有道具：
     - 销毁全部道具，并释放相关资源
     - 销毁道具后请将道具句柄数组中的句柄设为 0 ，以避免 SDK 使用无效的句柄而导致程序出错。
 */
+ (void)destroyAllItems;
```

### 道具的销毁与解绑

道具的销毁与解绑是指当需要切换道具或去除某个道具效果时，需要先销毁已经加载过的同类道具，然后再加载新的道具。在销毁道具前需要先从controller上解绑该道具，然后再做销毁操作。道具的销毁与解绑相关API如下：

```objective-c
/**
 销毁单个道具：
     - 通过道具句柄销毁道具，并释放相关资源
     - 销毁道具后请将道具句柄设为 0 ，以避免 SDK 使用无效的句柄而导致程序出错。
 
 @param item 道具句柄
 */
+ (void)destroyItem:(int)item;

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
```

### 道具切换

道具切换是指当需要切换身体模型、衣服、发型、眼镜等道具时，需要先解绑并销毁已加载的同类型道具，然后再创建并绑定新的道具。示例如下：

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

### 人脸检测

如果在绘制图像时需要使用人脸驱动风格化形象形象，则需要先对人脸进行检测，并获取相关人脸信息保存到TAvatarInfo结构体对象中，相关API说明如下：

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
```

示例代码如下：

```objective-c
	float expression[46] = {0};
    float translation[3] = {0};
    float rotation[4] = {0};
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

### 道具绘制

上面已经提到，然后在调用 Nama 的 render 相关接口时只需要传入包含controller道具及背景道具的 int 数组即可。绘制相关接口相关API如下：

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

这里使用的绘制方法与Nama使用的普通接口不太一样，一般应用中摄像头采集分辨率比较低，使用普通接口绘制风格化形象的话，会导致渲染出来的效果显得比较粗糙。这里我们通过采集低分辨率图片中人脸信息传入接口，然后输出高分辨率的图像的方法来绘制风格化形象。绘制示例如下：

```objective-c
static int frameid = 0 ;
- (CVPixelBufferRef) renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks{
   
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

其中renderTarget是用来当作输出的pixelBuffer,创建方式如下：


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

**更多详情，请参考Demo代码!**

