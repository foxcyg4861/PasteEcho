# PasteEcho

PasteEcho 是一款运行在 macOS 菜单栏的历史剪贴板工具。它会在本地记录最近复制过的文字和图片，方便用户随时搜索、查看、置顶、删除，并再次复制使用。

## 功能特点

- 自动记录剪贴板中的文字和图片
- 菜单栏常驻，点击图标打开历史面板
- 按时间倒序展示复制记录
- 支持搜索文字内容
- 支持置顶和删除记录
- 图片以缩略图形式展示
- 可设置记录保留时间：1 天、3 天、5 天
- 可设置最大保存条数
- 支持开机自启动
- 支持全局快捷键 `Cmd + Shift + V`
- 数据仅保存在本机，不上传网络

## 技术栈

- Swift
- SwiftUI
- AppKit
- NSPasteboard
- NSStatusItem
- NSPopover
- SMAppService
- XcodeGen

项目不使用第三方运行时依赖。

## 系统要求

- macOS 13 Ventura 或更高版本
- Xcode 16 或更高版本
- XcodeGen

## 项目结构

```text
PasteEcho
├── Sources/        # Swift 源码
├── Resources/      # Info.plist、图标、权限配置、Assets
├── docs/           # 产品、技术、设计和打包文档
├── devlog/         # 开发日志
└── project.yml     # XcodeGen 工程配置
```

## 生成 Xcode 工程

本项目通过 `project.yml` 生成 Xcode 工程。克隆后在项目根目录执行：

```bash
xcodegen generate
```

然后打开：

```text
PasteEcho.xcodeproj
```

## 构建运行

在 Xcode 中选择 `PasteEcho` scheme，然后执行：

```text
Product > Run
```

或使用命令行：

```bash
xcodebuild -project PasteEcho.xcodeproj -scheme PasteEcho build
```

## 打包分享

如果需要导出 `.app` 并通过微信等方式分享给另一台 Mac，请参考：

[docs/package-and-share.md](docs/package-and-share.md)

## 数据存储

PasteEcho 的数据存放在本机：

```text
~/Library/Application Support/PasteEcho/
```

其中包含历史记录 JSON 文件和图片文件。删除该目录会清空本地历史数据。

## 文档

- [产品需求](docs/requirements.md)
- [技术规格](docs/tech-spec.md)
- [设计规范](docs/design-spec.md)
- [开发计划](docs/development-phases.md)
- [项目结构](docs/project-structure.md)
- [打包与分享指南](docs/package-and-share.md)

## 当前状态

PasteEcho 目前处于本地开发和测试阶段，适合个人使用和内部测试。
