<div align="center">

# 拾光 Studio

Windows 本地图片工作台 · 调色、人像、抠图与创作排版

![Windows](https://img.shields.io/badge/Windows-0078d4?style=flat-square) ![Electron](https://img.shields.io/badge/Electron-47848f?style=flat-square) ![本地处理](https://img.shields.io/badge/%E6%9C%AC%E5%9C%B0%E5%A4%84%E7%90%86-16a34a?style=flat-square)

</div>

---

<p align="center"><a href="./使用说明.txt">操作指南</a> · <a href="./功能说明.md">完整功能与实现边界</a> · <a href="./third-party-notices">第三方声明</a></p>

## 界面预览

<p align="center"><img src="https://github.com/user-attachments/assets/b25f3c86-7a4f-41d8-985d-11ab95cd0309" alt="拾光 Studio 现有项目界面截图" width="1100"></p>

## 功能概览

| 工作区 | 可以做什么 |
| --- | --- |
| 调整与滤镜 | 调色、裁剪、旋转、尺寸与透视调整 |
| 人像修饰 | 离线人脸辅助框选、局部修饰与手动塑形 |
| 抠图与背景 | 离线人像分割、主体框选、边缘修补与换背景 |
| 画笔与设计 | 涂鸦、修复、马赛克、文字与图片贴纸 |
| 拼图与证件照 | 网格、长图、海报与常用证件规格排版 |
| 批量处理 | 尺寸、格式、调色、抠图与文字水印 |
| 工具箱 | Windows OCR、PDF 与图片转换、GIF 和切图 |
| 项目保存 | `.sgproj` 编辑历史、撤销与重做 |

功能依据仓库随附说明整理；详细适用范围见 [功能说明](./功能说明.md)。

## 开始使用

完整 Windows 发行包无需另行安装 Python 或 Node.js，本地功能不需要 API 密钥。

1. 导入照片，或从示例照片开始。
2. 选择左侧工具，预览并应用操作。
3. 导出图片用于分享，保存 `.sgproj` 用于恢复编辑历史。

**当前仓库内容：** 这里主要存放打包后的 Electron 运行依赖、图像引擎与说明，不是可用 `npm install` 启动的源码工程。当前分支未包含操作指南中所述的桌面主程序 `拾光 Studio.exe` 或 `Shiguang-Studio-2.0.1-Windows.exe`；需要取得完整发行包后才能按说明启动。不能用图像引擎 EXE 代替桌面入口。

## 画布快捷操作

| 操作 | 方式 |
| --- | --- |
| 缩放 | 滚轮，以鼠标位置为中心 |
| 平移 | 拖拽模式左键，或中键 / 右键拖动 |
| 复位视野 | 拖拽模式双击 |
| 导入 / 粘贴 | Ctrl+O / Ctrl+V |
| 撤销 / 重做 | Ctrl+Z / Ctrl+Y |
| 导出图片 | Ctrl+S |
| 保存项目 | Ctrl+Shift+S |

## 实现与限制

- YuNet 提供离线人脸辅助检测，PPHumanSeg 提供离线人像分割；低分辨率分割不能保证精细发丝。
- 局部美颜与塑形需要检查选区和处理结果，具体功能范围见完整说明。
- OCR 与 PDF 渲染依赖 Windows 系统组件，OCR 可用语言取决于系统安装情况。
- 项目最多保存 30 个历史版本、128 MB 图像数据；不保存独立图层和未应用笔画。
- 当前功能范围为本地图片处理，云端生成、换装、视频编辑等未实现。

## 第三方组件

Electron、Chromium 与图像处理组件的许可和声明随仓库保留。YuNet 使用 MIT 许可，PPHumanSeg 使用 Apache-2.0 许可；详见 [third-party-notices](./third-party-notices)、[Electron 许可](./LICENSE.electron.txt) 和 [Chromium 声明](./LICENSES.chromium.html)。
