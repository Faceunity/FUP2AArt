## PTA 技术对接综述

&emsp;&emsp;PTA 技术对接文档分为：《[PTA Server API](docs/PTA%20Server%20API.pdf)》，《[PTA Client SDK](docs/PTA%20Client%20SDK.md)》，以及《[Controller 说明文档](docs/Contorller%20说明文档.md)》3大部分。

### 1. 内容说明

&emsp;&emsp;《[PTA Server API](docs/PTA%20Server%20API.pdf)》：描述了如何调用PTA 服务端接口的文档。

&emsp;&emsp;《[PTA Client SDK](docs/PTA%20Client%20SDK.md))》：描述了客户端SDK，如何创建和编辑风格化形象，以及通过Nama SDK绘制风格化形象的文档。

&emsp;&emsp;《[Controller 说明文档](docs/Contorller 说明文档.md)》：封装了客户端SDK在创建，编辑风格化形象，以及AR 模式，面部追踪过程中，涉及到的接口列表文档。	

### 2.对接流程

&emsp;&emsp;客户可以先根据《PTA Server API》来申请相关的PTA服务权限。通过连接我们的Demo 服务器，或在我们技术团队辅助下架设自己服务器，来调用PTA Server API。PTA Server、测试服务器、PTA Demo，您正式服务器和正式APP之间的架构关系如下图所示。

<img src=".\docs\res\PTA_structure.png"  />

​	

&emsp;&emsp;根据《PTA 对接说明文档 》，来实现iOS 和 安卓端，模型创建，编辑，以及绘制风格化形象的功能。在客户端接入过程中，涉及到的所有接口的详细调用方式，可以参见《Contorller 说明文档》。
