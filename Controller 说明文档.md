# Contorller 参数文档
## 捏脸  
##### 进入捏脸模式  
```C
fuItemSetParamd(1,'enter_facepup_mode',1);
```
##### 退出捏脸模式
```C
fuItemSetParamd(1,'quit_facepup_mode',1);
```
##### 细分部位调整 
设置捏脸参数，最后保存，保存会将当前参数保存进bundle中。
```C
//参数名为json结构，
{
    "name":"facepup", //固定
    "param":"Head_fat" //具体动作 ,见下表
}
//数值范围[0,1]
var ret1 = fuItemSetParamd(1,'{\"name\":\"facepup\",\"param\":\"Head_fat\"}',1.0);
console.log("ret1:",ret1);
```
获取保存在bundle中的捏脸参数。
```C
//参数名为json结构，
{
    "name":"facepup", //固定
    "param":"Head_fat" //具体动作 ,见下表
}
//数值范围[0,1]
var ret1 = fuItemGetParamd(1,'{\"name\":\"facepup\",\"param\":\"Head_fat\"}');
console.log("ret1:",ret1);
```

##### 参数表：
__脸型__： 

| param              | 含义         |
| ------------------ | ------------ |
| "HeadBone_stretch" | 头骨纵向拉伸 |
| "HeadBone_shrink"  | 头骨纵向缩短 |
| "HeadBone_wide"    | 头骨水平变宽 |
| "HeadBone_narrow"  | 头骨水平变窄 |
| "Head_wide"        | 头型变宽     |
| "Head_narrow"      | 头型变窄     |
| "head_shrink"      | 头部缩短     |
| "head_stretch"     | 头部拉长     |
| "head_fat"         | 胖           |
| "head_thin"        | 瘦           |
| "cheek_wide"       | 颊变宽       |
| "cheekbone_narrow" | 颊变短       |
| "jawbone_Wide"     | 颧骨变宽     |
| "jawbone_Narrow"   | 颧骨变窄     |
| "jaw_m_wide"       | 颧骨中部变宽 |
| "jaw_M_narrow"     | 颧骨中部变窄 |
| "jaw_wide"         | 下巴宽       |
| "jaw_narrow"       | 下巴尖       |
| "jaw_up"           | 下巴高       |
| "jaw_lower"        | 下巴低       |

__眼睛__： 

| param                | 含义       |
| -------------------- | ---------- |
| "Eye_wide"           | 眼睛宽     |
| "Eye_shrink"         | 眼睛小     |
| "Eye_up"             | 眼睛位置高 |
| "Eye_down"           | 眼睛位置低 |
| "Eye_in"             | 眼睛内凹   |
| "Eye_out"            | 眼睛外凸   |
| "Eye_close"          | 眼睛细     |
| "Eye_open"           | 眼睛圆     |
| "Eye_upper_up"       | 上眼睑朝上 |
| "Eye_upper_down"     | 上眼睑朝下 |
| "Eye_upperBend_in"   | 上眼向内拱 |
| "Eye_upperBend_out"  | 上眼向外拱 |
| "Eye_downer_up"      | 下眼向上   |
| "Eye_downer_dn"      | 下眼向下   |
| "Eye_downerBend_in"  | 下眼外翻   |
| "Eye_downerBend_out" | 下眼内翻   |
| "Eye_outter_in"      | 眼外沿内收 |
| "Eye_outter_out"     | 眼外沿外放 |
| "Eye_outter_up"      | 外眼角上扬 |
| "Eye_outter_down"    | 外眼角下弯 |
| "Eye_inner_in"       | 眼距短     |
| "Eye_inner_out"      | 眼距长     |
| "Eye_inner_up"       | 内眼角上扬 |
| "Eye_inner_down"     | 内眼角下弯 |

__嘴巴__：

| param                | 含义         |
| -------------------- | ------------ |
| "upperLip_Thick"     | 上嘴唇厚     |
| "upperLipSide_Thick" | 上嘴唇两侧厚 |
| "lowerLip_Thick"     | 下嘴唇厚     |
| "lowerLipSide_Thin"  | 下嘴唇两侧薄 |
| "lowerLipSide_Thick" | 下嘴唇两侧厚 |
| "upperLip_Thin"      | 上嘴唇薄     |
| "lowerLip_Thin"      | 下嘴唇薄     |
| "mouth_magnify"      | 嘴宽         |
| "mouth_shrink"       | 嘴窄         |
| "lipCorner_Out"      | 嘴角长       |
| "lipCorner_In"       | 嘴角短       |
| "lipCorner_up"       | 嘴角上扬     |
| "lipCorner_down"     | 嘴角下翻     |
| "mouth_m_down"       | 嘴中部向下   |
| "mouth_m_up"         | 嘴中部向上   |
| "mouth_Up"           | 嘴朝上       |
| "mouth_Down"         | 嘴朝下       |

__鼻子__：

| param          | 含义       |
| -------------- | ---------- |
| "nostril_Out"  | 鼻孔大     |
| "nostril_In"   | 鼻孔小     |
| "noseTip_Up"   | 鼻头上翻   |
| "noseTip_Down" | 鼻头下翻   |
| "nose_Up"      | 鼻子位置高 |
| "nose_tall"    | 鼻子高     |
| "nose_low"     | 鼻子扁     |
| "nose_Down"    | 鼻子位置低 |

---
## FOV
设置场景FOV
```C
//数值范围(0,90),建议不要过小，也不要过大。
fuItemSetParamd(1,'render_fov',30);
```
---

## 肤色设置
肤色调整根据色表进行调整。  
##### 获取肤色色表长度
```C
int colorIndexCnt = fuItemGetParamd(1,'color_index');
```
##### 设置肤色
设置角色包括头和身体的肤色
```C
fuItemSetParamdv(1,'skin_color', [255,0,0]);
// 得到默认嘴唇颜色index
int skin_color_index = fuItemGetParamd(1,'skin_color_index');
```

------

## 可配置颜色
```C
//所有输入颜色值为SRGB，0-255

// 嘴唇颜色
fuItemSetParamdv(1,'lip_color', [255,0,0]);
// 得到默认嘴唇颜色index
int lip_color_index = fuItemGetParamd(1,'lip_color_index');

// 头发颜色
fuItemSetParamdv(1,'hair_color', [255,0,0]);
fuItemSetParamd(1,'hair_color_intensity', 1.0);
// 胡子颜色
fuItemSetParamdv(1,'beard_color', [255,0,0]);
// 瞳孔颜色
fuItemSetParamdv(1,'iris_color', [255,0,0]);
// 眼睛片颜色
fuItemSetParamdv(1,'glass_color', [255,0,0]);
// 眼镜框颜色
fuItemSetParamdv(1,'glass_frame_color', [255,0,0]);

```

-------

## 重置

##### 重置旋转

```C
//第三个值为每帧的弧度变化
fuItemSetParamd(1,'reset_angle',0.1);
```

##### 重置缩放
```C
//第三个值为缩放速度
fuItemSetParamd(1,'reset_scale',1.0);
```

##### 重置位置
```C
//第三个值为位置偏移速度
fuItemSetParamd(1,'reset_translate',1.0);
```

##### 重置所有(旋转，缩放，位置)
```C
//第三个值为重置速度 一般设置1.0,最大不宜超过10.0,最小不应小于0.0
fuItemSetParamd(1,'reset_all',1.0);
```

##### 设置重置目标弧度
```C
//第三个值为弧度值
fuItemSetParamd(1,'target_angle',1.0);
```

##### 设置重置目标大小
```C
//第三个值为大小 范围[-50,140]
fuItemSetParamd(1,'target_scale',1.0);
```

##### 设置重置目标垂直位置
```C
//第三个值为垂直位置 范围[0,110]
fuItemSetParamd(1,'target_trans',1.0);
```

------

## 位置

basic版的位置是art版的0.01倍，示例范围以basic版为基准，basic数值放大100倍即为art版的数值  

##### 设置水平位置  

```C
//第三个值为水平世界坐标 设置范围一般在[-1,1] 超过范围可能超出屏幕
fuItemSetParamd(1,'translation_x',1.0);
```

##### 设置垂直位置
```C
//第三个值为垂直世界坐标 设置范围一般在[-3,1], -1模型位于屏幕中心高度 超过范围可能超出屏幕
fuItemSetParamd(1,'translation_y',1.0);
```

##### 设置前后位置
```C
//第三个值为前后世界坐标 设置范围一般在[1,10] 数值越大离屏幕越远 超过范围可能超出屏幕
fuItemSetParamd(1,'translation_z',1.0);
```

##### 设置缩放增量
```C
//第三个值为缩放增量 通常取值范围[-1,1]
fuItemSetParamd(1,'scale_delta',1.0);
```

##### 设置上下增量
```C
//第三个值为上下增量 通常取值范围[-1,1]
fuItemSetParamd(1,'translate_delta',1.0);
```

##### 设置旋转增量
```C
//第三个值为旋转增量弧度
fuItemSetParamd(1,'rot_delta',1.0);
```

##### 选择预设位置  

```C
//0为半身位置，1为全身位置
fuItemSetParamd(1,"cam_type",0);
```

------

## 特殊模式

##### 开启动画追踪人头
```C
fuItemSetParamd(1,'enter_track_rotation_mode',1.0);
```

##### 关闭动画追踪人头
```C
fuItemSetParamd(1,'quit_track_rotation_mode',1.0);
```

##### 开启ar人头
```C
fuItemSetParamd(1,'enter_ar_mode',1.0);
```

##### 关闭ar人头
```C
fuItemSetParamd(1,'quit_ar_mode',1.0);
```


## 获取serverinfo
##### 获取头发分类类别
```C  
//参数名是json格式,name固定是serverinfo,param是参数名。
var ret1 = fuItemGetParamd(1,'{\"name\":\"serverinfo\",\"param\":\"hair_label\"}');
console.log("ret1:",ret1);
```


## 光照
##### 设置主副光源参数
```C  
//L0为主光，L1为副光，均为直射光
//设置光源颜色，RGB值，范围（0~1）
fuItemSetParamd(1,'L0_R',1.0);	//同理设置L1_R
fuItemSetParamd(1,'L0_G',1.0);
fuItemSetParamd(1,'L0_B',1.0);
//设置光源强度，范围（0~1~N）
fuItemSetParamd(1,'L0_intensity',1.0);	//同理设置L1_intensity
//设置光源方向，角度，范围（-N~0~360~N）
fuItemSetParamd(1,'L0_yaw',1.0);	//同理设置L1_yaw
fuItemSetParamd(1,'L0_pitch',1.0);
```

##### 设置环境光参数
```C  
//环境光由SH系数和环境贴图组成，暂不能直接修改
//设置环境光强度，范围（0~1~N）
fuItemSetParamd(1,'env_intensity',1.0);
//设置环境光旋转，弧度，范围（-N~0~2π~N）
fuItemSetParamd(1,'env_rotate',0);
```


## 其他
##### 打开或关闭表情裁剪  
```C  
//打开表情裁剪  
fuItemSetParamd(1,'enable_expclamp',1.0);
//关闭表情裁剪  
fuItemSetParamd(1,'disable_expclamp',1.0);
```
##### 动画控制

```c  
//播放动画  
fuItemSetParamd(1,'animState',1.0);
//暂停动画  
fuItemSetParamd(1,'animState',2.0);
//停止动画  
fuItemSetParamd(1,'animState',3.0);
//设置动画 fps 为24，默认为24
fuItemSetParamd(1,'animfps',24);
//跳到第30帧 
fuItemSetParamd(1,'animFrameId',30);
//跳到第30帧，并继续播放
fuItemSetParamd(1,'animFrameId',30);
fuItemSetParamd(1,'animState',1.0);
// 得到动画最大帧数
int maxFrameNum = fuItemGetParamd(1,'maxFrameNum');
// 得到当前动画帧数
int frameNum = fuItemGetParamd(1,'frameNum');
// 得到当前帧位置
int animFrameId = fuItemGetParamd(1,'animFrameId');
//只播一次动画，1是开启0是关闭
fuItemSetParamd(1,'play_once',1);
//开启BlendShape动画遮罩
fuItemSetParamd(1,"ENABLEEXPRESSIONMASK",1);
//设置遮罩参数，遮罩参数只在ENABLEEXPRESSIONMASK设置为1时有效
//这个参数值是一个长度为表情系数长度的数组，取值为0~1，当值为0时跟踪输出的blendshape为真实计算值，当值为1时动画输出的blendshape为真实计算值，当值为x时真实计算值为bs(跟踪)* (1-x) + bs(动画) * x
var d = [];
for(var i = 0;i<56;i++){
	d[i] = 0;
}
fuItemSetParamdv(1,"expression_MASK",d);
```

**输入脸部mesh顶点序号获取其在屏幕空间的坐标**

```c
//设置顶点序号为1
fuItemSetParamd(1,'query_vert',1);
//获取坐标x 
fuItemGetParamd(1,'query_vert_x');
//获取坐标y
fuItemGetParamd(1,'query_vert_y');
```

**平行光阴影**

```c
// 关闭阴影
fuItemSetParamd(1,'enable_shadow',0);
// 开启阴影
fuItemSetParamd(1,'enable_shadow',1);
```

**更改眼睛反射的高光**

```c
//设置反射强度为1
fuItemSetParamd(1,"{\"name\":\"avatar\",\"param\":\"refl_intensity\"}",1);
//设置反射旋转为90（角度）（y轴）
fuItemSetParamd(1,"{\"name\":\"avatar\",\"param\":\"refl_rotate\"}",90);
```


**开启或关闭物理**

```c
//1.请在加载controller后，bind组件之前设置，值为1时开启，0为关闭，默认为1
fuItemSetParamd(1,'ENABLEPHYSICS',1);
//2.如需中途开启物理请unbind且卸载所有bundle，重复1，然后再重新加载所需的bundle
```
