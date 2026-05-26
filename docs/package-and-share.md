# PasteEcho 打包与微信分享指南

本文档说明如何把 PasteEcho 打包成可运行的 macOS App，并通过微信发送给另一台 Mac 解压使用。

## 适用场景

- 你已经可以在 Xcode 中成功运行 PasteEcho。
- 你想把软件发给另一台 Mac 使用。
- 你不准备上架 App Store，只是自己测试或分享给熟人使用。

## 打包前检查

如果项目使用 `project.yml` 生成 Xcode 工程，请先在项目根目录执行：

```bash
xcodegen generate
```

然后重新打开：

```text
PasteEcho.xcodeproj
```

在 Xcode 中确认 `Resources` 已经加入项目，并且 Target 的 `Copy Bundle Resources` 中包含：

```text
Assets.xcassets
AppIcon.icns
```

导出的 App 包内应存在：

```text
PasteEcho.app
└── Contents
    ├── Info.plist
    ├── MacOS
    │   └── PasteEcho
    └── Resources
        └── AppIcon.icns
```

如果没有 `Contents/Resources/AppIcon.icns`，导出的 App 可能不会显示图标。

## 使用 Xcode 导出 App

1. 打开 `PasteEcho.xcodeproj`
2. 选择菜单：

```text
Product > Clean Build Folder
```

3. 选择菜单：

```text
Product > Archive
```

4. Archive 完成后，Xcode 会打开 Organizer。
5. 选择最新的 PasteEcho archive。
6. 点击：

```text
Distribute App
```

7. 选择导出 App 的方式。

如果只是自己使用或通过微信发给另一台 Mac，一般选择：

```text
Copy App
```

或在部分 Xcode 版本中选择：

```text
Custom > Copy App
```

最终目标是得到一个：

```text
PasteEcho.app
```

## 压缩 App

推荐使用 macOS 终端执行以下命令，能更好地保留 App 包结构：

```bash
ditto -c -k --sequesterRsrc --keepParent PasteEcho.app PasteEcho.zip
```

如果你不熟悉终端，也可以右键 `PasteEcho.app`，选择：

```text
压缩 "PasteEcho"
```

最终得到：

```text
PasteEcho.zip
```

## 通过微信发送

把 `PasteEcho.zip` 发送给另一台 Mac。

不要直接发送 `PasteEcho.app` 文件夹，也不要发送源码目录。微信更适合传压缩包。

## 在另一台 Mac 解压使用

1. 下载 `PasteEcho.zip`
2. 双击解压
3. 把 `PasteEcho.app` 拖到：

```text
应用程序
```

4. 第一次打开时，建议右键 App，然后选择：

```text
打开
```

如果系统提示无法验证开发者，再点击一次：

```text
打开
```

## 处理无法打开的问题

如果 macOS 阻止打开，可以在终端执行：

```bash
xattr -dr com.apple.quarantine /Applications/PasteEcho.app
```

然后重新打开 App。

如果仍然无法打开，请检查：

- App 是否完整解压
- 是否被放在 `/Applications`
- 是否存在 `Contents/MacOS/PasteEcho`
- 是否存在 `Contents/Resources/AppIcon.icns`

## 常见问题

### 为什么导出后没有图标？

通常是资源没有进入 App 包。请检查：

```text
PasteEcho.app/Contents/Resources/AppIcon.icns
```

如果没有这个文件，需要重新生成 Xcode 工程，或手动把资源加入 `Copy Bundle Resources`。

### 为什么微信收到后打不开？

macOS 会给从网络下载的 App 加上隔离标记。可以右键打开，或使用：

```bash
xattr -dr com.apple.quarantine /Applications/PasteEcho.app
```

### 可以直接发源码吗？

不推荐。源码需要 Xcode 编译，普通用户无法直接使用。分享给别人使用时，应发送 `PasteEcho.zip`。
