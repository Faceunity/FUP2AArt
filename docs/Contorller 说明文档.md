# Contorller 参数文档

## 特别说明
```C
//文档中假设：通过fuCreateItemFromPackage创建的controller.bundle的句柄为1
```
------

## 设置角色位置
```C
//NAMA中使用右手坐标系，X轴水平向右，Y轴竖直向上，Z轴垂直屏幕向外
```
------
##### 设置角色的旋转角度
```C
//第三个参数是归一化的旋转角度，范围[0.0, 1.0]，0.0代表0度，1.0代表360度
fuItemSetParamd(1, "target_angle", 0.5);
```
##### 设置角色的大小
```C
//第三个参数是角色在三维空间中Z方向的坐标，范围[-1000, 200]，数值越大，显示的角色越大
fuItemSetParamd(1, "target_scale", -300.0);
```
##### 设置角色在竖直方向上的位置
```C
//第三个参数是角色在三维空间中Y方向的位置，范围[-300, 400]
fuItemSetParamd(1, "target_trans", 30.0);
```
##### 设置角色在三维空间的位置
```C
//第三个参数是角色在三维空间中的坐标[x, y, z]，x范围[-100, 100]，y范围[-300, 400]，z范围[-1000, 200]
fuItemSetParamdv(1, "target_position", [30.0, 0.0, -300]);
```
##### 调用重置命令，使上述对位置的设置命令生效
```C
//第三个参数为过渡帧数，范围[1.0, 60.0]，表示经过多少帧从当前位置过渡到目标位置
fuItemSetParamd(1, "reset_all", 1.0);
```
------
##### 旋转角色
```C
//第三个参数是旋转增量，取值范围[-1.0, 1.0]
fuItemSetParamd(1, "rot_delta", 1.0);
```
##### 缩放角色
```C
//第三个参数缩放增量，取值范围[-1.0, 1.0]
fuItemSetParamd(1, "scale_delta", 1.0);
```
##### 上下移动角色
```C
//第三个参数是上下增量，取值范围[-1.0, 1.0]
fuItemSetParamd(1, "translate_delta", 1.0);
```
------

## 动画控制
```C
//假设：通过fuCreateItemFromPackage创建的动画道具anim.bundle的句柄为2
```
------
```C
//从头播放句柄为2的动画（循环）
fuItemSetParamd(1, "play_animation", 2);

//从头播放句柄为2的动画（单次）
fuItemSetParamd(1, "play_animation_once", 2);

//继续播放当前动画
fuItemSetParamd(1, "start_animation", 1);

//暂停播放当前动画
fuItemSetParamd(1, "pause_animation", 1);

//结束播放动画
fuItemSetParamd(1, "stop_animation", 1);

//设置动画的过渡时间，单位为秒
fuItemSetParamd(1, "animation_transition_time", 4.0); 

//获取句柄为2的动画的当前进度
//进度0~0.9999为第一次循环，1.0~1.9999为第二次循环，以此类推
//即时play_animation_once，进度也会突破1.0，照常运行
fuItemGetParamd(1, "{\"name\":\"get_animation_progress\", \"anim_id\":2}"); 

//获取句柄为2的动画的总帧数
fuItemGetParamd(1, "{\"name\":\"get_animation_frame_num\", \"anim_id\":2}"); 

//1为开启，0为关闭，开启的时候移动角色的值会被设进骨骼系统，这时候带DynamicBone的模型会有相关效果
//如果添加了没有骨骼的模型，请关闭这个值，否则无法移动模型
//默认开启
//每个角色的这个值都是独立的
fuItemSetParamd(1, "modelmat_to_bone", 1.0); 

//1为开启，0为关闭，开启的时候已加载的物理会生效，同时加载新的带物理的bundle也会生效，关闭的时候已加载的物理会停止生效，但不会清除缓存（这时候再次开启物理会在此生效），这时加载带物理的bundle不会生效，且不会产生缓存，即关闭后加载的带物理的bundle，即时再次开启，物理也不会生效，需要重新加载
fuItemSetParamd(1, "enable_dynamicbone", 1.0); 
```
------
## 相机动画控制
//启用/暂停当前动画
//1为开启，0为关闭，
fuItemSetParamd(1,"enable_camera_animation",1);

//停止当前动画，并回到第1帧
fuItemSetParamd(1,"stop_camera_animation",1);

//循环动画
//1为循环，0为不循环，
fuItemSetParamd(1,"camera_animation_loop",1);

------
##### 使用自定义的动画系统时间轴，必须按以下步骤
```C
//1.重置一下当前的动画系统，准备切换时间轴
fuItemSetParamd(1, "stop_animation", 1); 
fuItemSetParamd(1, "start_animation", 1); 
fuItemSetParamd(1, "enable_set_time", 1); 
//2.之后，每次渲染前设置动画系统的当前时间，单位为秒
fuItemSetParamd(1, "animation_time_current", 0.1); 
//3.如果要切换回系统时间
fuItemSetParamd(1, "stop_animation", 1); 
fuItemSetParamd(1, "start_animation", 1); 
fuItemSetParamd(1, "enable_set_time", 0); 
```

## 颜色设置
```C
//所有输入的颜色值都为RGB，范围0-255
```
------
##### 肤色
```C
//设置角色头和身体的肤色
fuItemSetParamdv(1, "skin_color", [255, 0, 0]);
//获取当前肤色在肤色表的索引，从0开始
int skin_color_index = fuItemGetParamd(1, "skin_color_index");
```
------
##### 唇色
```C
//设置唇色
fuItemSetParamdv(1, "lip_color", [255, 0, 0]);
//获取当前唇色在唇色表的索引，从0开始
int lip_color_index = fuItemGetParamd(1, "lip_color_index");
```
------
##### 瞳孔颜色
```C
//设置瞳孔颜色
fuItemSetParamdv(1, "iris_color", [255,0,0]);
```
------
##### 眼睛颜色
```C
//设置眼镜片颜色
fuItemSetParamdv(1, "glass_color", [255,0,0]);
//设置眼镜框颜色
fuItemSetParamdv(1, "glass_frame_color", [255,0,0]);
```
------
##### 头发颜色
```C
//设置头发颜色
fuItemSetParamdv(1, "hair_color", [255, 0, 0]);
//设置颜色强度，参数大于0.0，一般取值为1.0
fuItemSetParamd(1, "hair_color_intensity", 1.0);
```
------
##### 胡子颜色
```C
//设置胡子颜色
fuItemSetParamdv(1, "beard_color", [255,0,0]);
```
------
##### 帽子颜色
```C
//设置胡子颜色
fuItemSetParamdv(1, "hat_color", [255,0,0]);
```
------
##### 设置背景颜色
```C
//开启enable_background_color，只有开启后，才能通过set_background_color，设置纯色背景
fuItemSetParamd(1, "enable_background_color", 1.0);
fuItemSetParamdv(1, "set_background_color", [255, 255, 255, 255]);
//开启enable_background_color后背景道具失效，所以如果要使用背景道具，注意关闭enable_background_color
fuItemSetParamd(1, "enable_background_color", 0.0);
```
------
## 特殊模式

### AR模式
```C
//开启AR模式
fuItemSetParamd(1, "enter_ar_mode", 1.0);
//关闭AR模式
fuItemSetParamd(1, "quit_ar_mode", 1.0);
```
------
### Blendshape混合
```C
//开启或关闭Blendshape混合：value = 1.0表示开启，value = 0.0表示不开启
fuItemSetParamd(1, "enable_expression_blend", value);
//设置Blendshape混合参数：blend_expression、expression_weight0、expression_weight1，只在enable_expression_blend设置为1时有效
//blend_expression是用户输入的bs系数数组，取值为0~1，序号0-45代表基表情bs，46-56代表口腔bs，57-66代表舌头bs
var d = [];
for(var i = 0; i<57; i++){
	d[i] = 0;
}
fuItemSetParamdv(1, "blend_expression", d);
//expression_weight0是blend_expression的权重，expression_weight1是算法检测返回的表情或者加载的动画表情系数数组的权重，取值为0~1
var d = [];
for(var i = 0; i<57; i++){
	d[i] = 0;
}
fuItemSetParamdv(1, "expression_weight0", d);
```
------
### 眼睛注视相机
```C
//开启眼镜注释功能，value = 1.0表示开启，value = 0.0表示不开启
fuItemSetParamd(1, "enable_fouce_eye_to_camera", value);
//设置眼睛注视相机参数：fouce_eye_to_camera_height_adjust、fouce_eye_to_camera_distance_adjust、fouce_eye_to_camera_weight
fuItemSetParamd(1, "fouce_eye_to_camera_height_adjust", 30.0); //调整虚拟相机相对高度
fuItemSetParamd(1, "fouce_eye_to_camera_distance_adjust", 30.0); //调整虚拟相机相对距离
fuItemSetParamd(1, "fouce_eye_to_camera_weight", 1.0); //调整注视的影响权重，1.0表示完全启用，0.0表示无影响
```
------
### 多人模式
```C
//使用fuBindItems绑定道具, fuUnbindItems解绑道具，以及对controller设置的参数，作用的都是当前角色，默认情况下，当前角色的ID是0号。
//使用多人模式，需要通过设置参数current_instance_id，切换当前角色，例如切换到1号角色：
fuItemSetParamd(1, "current_instance_id", 1.0);
```
------
### CNN 面部追踪
```C
//1.使用CNN 面部追踪前，用户需要通过fuFaceCaptureCreate创建面部追踪模型
var face_capture = fuFaceCaptureCreate(__pointer data, int sz);
//2.将这个模型注册到controller的当前角色上，并分配人脸索引，索引从0开始
fuItemSetParamu64(1, "register_face_capture_manager", face_capture);
fuItemSetParam(1, "register_face_capture_face_id", 0.0);
//3.设置close_face_capture，说明启用或者关闭CNN面部追踪，value = 0.0表示开启，value = 1.0表示关闭
fuItemSetParamd(1, "close_face_capture", 1.0);

//4.如果开启CNN 面部追踪，每帧都需要调用fuFaceCaptureProcessFrame处理输入图像
fuFaceCaptureProcessFrame(face_capture, __pointer img_data, int image_w, int image_h, int fu_image_format, int rotate_mode)

//5.最后，退出程序前，需要销毁面部追踪模型
fuFaceCaptureDestory(face_capture)
```
------
### 捏脸
##### 进入或者退出捏脸模式 
```C
//进入捏脸模式  
fuItemSetParamd(1, "enter_facepup_mode", 1);
//退出捏脸模式
fuItemSetParamd(1, "quit_facepup_mode", 1);
```
##### 细分部位调整 
```C
//设置捏脸参数，最后保存，保存会将当前参数保存进bundle中
//参数名为json结构，
{
    "name":"facepup", //固定
    "param":"Head_Fat" //具体动作, 见下表
}
//数值范围[0, 1]
fuItemSetParamd(1, "{\"name\":\"facepup\",\"param\":\"Head_Fat\"}", 1.0);
```
##### 获取保存在bundle中的捏脸参数
```C
//参数名为json结构，
{
    "name":"facepup", //固定
    "param":"Head_Fat" //具体动作 ,见下表
}
//数值范围[0,1]
fuItemGetParamd(1,"{\"name\":\"facepup\",\"param\":\"Head_Fat\"}");

//获取保存在bundle中的全部捏脸参数
fuItemGetParamfv(1, "facepup_expression", (float*)buf, (int)sz);
```

##### 参数表：
__脸型__：  

| param              | 含义         |
| ------------------ | ------------ |
| "HeadBone_wide " |头型变宽  |
| "Head_narrow " |头型变窄  |
| "head_shrink " |头部缩短  |
| "head_stretch " |头部拉长  |
| "head_fat " |胖  |
| "head_thin " |瘦  |
| "cheek_wide " |颊变宽  |
| "cheekbone_narrow " |颊变短  |
| "jawbone_Wide " |下颌角向下  |
| "jawbone_Narrow " |下颌角向下  |
| "jaw_m_wide " |下颌变宽  |
| "jaw_M_narrow " |下颌变窄  |
| "jaw_wide " |下巴变宽  |
| "jaw_narrow " |下巴变窄  |
| "jaw_up " |下巴变短  |
| "jaw_lower " |下巴变长  |
| "jawTip_forward " |下巴向前  |
| "jawTip_backward " |下巴向后  |
| "jawBone_m_up " |下颌中间变窄  |
| "jawBone_m_down " |下颌中间变宽  |

__眼睛__：  

| param                | 含义       |
| -------------------- | ---------- |
| "Eye_wide " |眼睛放大  |
| "Eye_shrink " |眼睛缩小  |
| "Eye_up " |眼睛向上  |
| "Eye_down " |眼睛向下  |
| "Eye_in " |眼睛向里  |
| "Eye_out " |眼睛向外  |
| "Eye_close_L " |左眼闭  |
| "Eye_close_R " |右眼闭  |
| "Eye_open_L " |左眼睁  |
| "Eye_open_R " |右眼睁  |
| "Eye_upper_up_L " |左上眼皮向上  |
| "Eye_upper_up_R " |右上眼皮向上  |
| "Eye_upper_down_L " |左上眼皮向下  |
| "Eye_upper_down_R " |右上眼皮向下  |
| "Eye_upperBend_in_L " |左上眼皮向里  |
| "Eye_upperBend_in_R " |右上眼皮向里  |
| "Eye_upperBend_out_L " |左上眼皮向外  |
| "Eye_upperBend_out_R " |右上眼皮向外  |
| "Eye_downer_up_L " |左下眼皮向上  |
| "Eye_downer_up_R " |右下眼皮向上  |
| "Eye_downer_dn_L " |左下眼皮向下  |
| "Eye_downer_dn_R " |右下眼皮向下  |
| "Eye_downerBend_in_L " |左下眼皮向里  |
| "Eye_downerBend_in_R " |右下眼皮向里  |
| "Eye_downerBend_out_L " |左下眼皮向外  |
| "Eye_downerBend_out_R " |右下眼皮向外  |
| "Eye_outter_in " |外眼角向里  |
| "Eye_outter_out " |外眼角向外  |
| "Eye_outter_up " |外眼角向上  |
| "Eye_outter_down " |外眼角向下  |
| "Eye_inner_in " |内眼角向里  |
| "Eye_inner_out " |内眼角向外  |
| "Eye_inner_up " |内眼角向上  |
| "Eye_inner_down " |内眼角向下  |
| "Eye_forward " |眼睛向前  |

__嘴巴__：

| param                | 含义         |
| -------------------- | ------------ |
| "upperLip_Thick " |上唇变厚  |
| "upperLipSide_Thick " |上唇两侧变厚  |
| "lowerLip_Thick " |下唇变厚  |
| "lowerLipSide_Thin " |下唇两侧变薄  |
| "lowerLipSide_Thick " |下唇两侧变厚  |
| "upperLip_Thin " |上唇变薄  |
| "lowerLip_Thin " |下唇变薄  |
| "mouth_magnify " |嘴巴放大  |
| "mouth_shrink " |嘴巴缩小  |
| "lipCorner_Out " |嘴角向外  |
| "lipCorner_In " |嘴角向里  |
| "lipCorner_up " |嘴角向上  |
| "lipCorner_down " |嘴角向下  |
| "mouth_m_down " |唇尖向下  |
| "mouth_m_up " |唇尖向上  |
| "mouth_Up " |嘴向上  |
| "mouth_Down " |嘴向下  |
| "mouth_side_up " |唇线两侧向上  |
| "mouth_side_down " |唇线两侧向下  |
| "mouth_forward " |嘴向前  |
| "mouth_backward " |嘴向后  |
| "upperLipSide_thin " |上唇两侧变薄  |

__鼻子__：

| param          | 含义       |
| -------------- | ---------- |
| "nostril_Out " |鼻翼变宽  |
| "nostril_In " |鼻翼变窄  |
| "noseTip_Up " |鼻尖向上  |
| "noseTip_Down " |鼻尖向下  |
| "nose_Up " |鼻子向上  |
| "nose_tall " |鼻子变高  |
| "nose_low " |鼻子变矮  |
| "nose_Down " |鼻子向下  |
| "noseTip_forward " |鼻尖向前  |
| "noseTip_backward " |鼻尖向后  |
| "noseTip_magnify " |鼻尖放大  |
| "noseTip_shrink " |鼻尖缩小  |
| "nostril_up " |鼻翼向上  |
| "nostril_down " |鼻翼向下  |
| "noseBone_tall " |鼻梁变高  |
| "noseBone_low " |鼻梁变低  |
| "nose_wide " |鼻子变宽  |
| "nose_shrink " |鼻子变窄  |

------

## 其他

### 更新背景道具贴图
```C
//背景道具包含背景贴图和画中画贴图
//更新背景贴图
fuCreateTexForItem(1, "background_bg_tex", __pointer data, int width, int height)
//更新画中画贴图
fuCreateTexForItem(1, "background_live_tex", __pointer data, int width, int height)
```
------
### 隐藏脖子
```C
fuItemSetParam(1, "hide_neck", 1.0);
```
------
### 输入脸部mesh顶点序号获取其在屏幕空间的坐标

```C
//计算序号为1顶点在屏幕空间的坐标
fuItemSetParamd(1, "query_vert", 1);
//获取坐标x 
fuItemGetParamd(1, "query_vert_x");
//获取坐标y
fuItemGetParamd(1, "query_vert_y");
```
------
### 获取serverinfo信息
```C
//参数名是json格式，name固定是serverinfo，param是参数名。
```
##### 获取头发分类类别
```C  
var ret = fuItemGetParamd(1, "{\"name\":\"serverinfo\", \"param\":\"hair_label\"}");
```

