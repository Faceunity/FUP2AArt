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

| param              | 含义           |
| ------------------ | ------------ |
| "cheek_narrow"     | 控制脸颊宽度，瘦     |
| "Head_fat"         | 控制脸颊宽度，胖     |
| "Head_shrink"      | 控制人脸整体的长度，缩短 |
| "Head_stretch"     | 控制人脸整体的长度,伸长 |
| "HeadBone_shrink"  | 控制额头区域高低，低   |
| "HeadBone_stretch" | 控制额头区域高低，高   |
| "jaw_lower"        | 控制下巴尖/平，尖    |
| "jaw_up"           | 控制下巴尖/平，平    |
| "jawbone_Narrow"   | 控制下颚宽度，窄     |
| "jawbone_Wide"     | 控制下颚宽度，宽     |

__眼睛__：  

| param             | 含义               |
| ----------------- | ---------------- |
| "Eye_both_in"     | 眼睛型宽窄,窄          |
| "Eye_both_out"    | 眼睛型宽窄,宽          |
| "Eye_close"       | 眼睛型高低,闭眼         |
| "Eye_down"        | 眼睛整体在脸部区域的位置高低,低 |
| "Eye_inner_down"  | 眼角上翘/下翘，内眼角向下    |
| "Eye_inner_up"    | 眼角上翘/下翘，内眼角向上    |
| "Eye_open"        | 眼睛型高低,睁眼         |
| "Eye_outter_down" | 眼角上翘/下翘，外眼角向下    |
| "Eye_outter_up"   | 眼角上翘/下翘，外眼角向上    |
| "Eye_up"          | 眼睛整体在脸部区域的位置高低,高 |

__嘴巴__：

| param                | 含义         |
| -------------------- | ---------- |
| "lipCorner_In"       | 嘴唇宽度,窄     |
| "lipCorner_Out"      | 嘴唇宽度,宽     |
| "lowerLip_Thick"     | 下嘴唇厚度，下嘴唇厚 |
| "lowerLip_Thin"      | 下嘴唇厚度,下嘴唇薄 |
| "lowerLipSide_Thick" | 下嘴唇厚度,下嘴角厚 |
| "mouth_Down"         | 嘴部位置高低，低   |
| "mouth_Up"           | 嘴部位置高低，高   |
| "upperLip_Thick"     | 上嘴唇厚度，上嘴唇厚 |
| "upperLip_Thin"      | 上嘴唇厚度，上嘴唇薄 |
| "upperLipSide_Thick" | 上嘴唇厚度，上嘴角厚 |

__鼻子__：

| param          | 含义       |
| -------------- | -------- |
| "nose_Down"    | 鼻子位置高低,低 |
| "nose_UP"      | 鼻子位置高低，高 |
| "noseTip_Down" | 鼻头高低，低   |
| "noseTip_Up"   | 鼻头高低，高   |
| "nostril_In"   | 鼻翼宽窄，窄   |
| "nostril_Out"  | 鼻翼宽窄，宽   |

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
## 其他
##### 打开或关闭表情裁剪  
```C  
//打开表情裁剪  
fuItemSetParamd(1,'enable_expclamp',1.0);
//关闭表情裁剪  
fuItemSetParamd(1,'disable_expclamp',1.0);
```
