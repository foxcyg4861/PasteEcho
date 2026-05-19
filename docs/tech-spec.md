# PasteEcho — 技术规格文档

## 技术选型

| 项目 | 选择 | 理由 |
|------|------|------|
| 开发语言 | Swift 5.9+ | macOS 原生开发首选 |
| UI 框架 | SwiftUI | 声明式 UI，代码简洁，系统原生支持 |
| 最低系统 | macOS 13 (Ventura) | SMAppService 需要 macOS 13+ |
| 数据存储 | JSON + 文件系统 | 轻量、零依赖、200条内性能足够 |
| 剪贴板访问 | NSPasteboard | 系统原生 API |
| 全局快捷键 | Carbon EventHotKey | 无需辅助功能权限 |
| 开机启动 | SMAppService.mainApp | macOS 13+ 官方推荐方案 |
| 依赖管理 | 无 | 零第三方依赖 |

## 架构设计

### 分层架构

```
┌─────────────────────────┐
│     Views (SwiftUI)      │  ← 用户界面层
├─────────────────────────┤
│    ViewModels            │  ← 状态管理层
├─────────────────────────┤
│     Services             │  ← 业务逻辑层
├─────────────────────────┤
│     Models               │  ← 数据模型层
└─────────────────────────┘
```

### 组件关系

```
PasteEchoApp (@main)
  └── AppDelegate (NSApplicationDelegate)
        ├── NSStatusItem (菜单栏图标)
        ├── NSPopover (弹出面板)
        │     └── NSHostingView(rootView: PopoverRootView)
        │           └── environmentObject(appViewModel)
        ├── ClipboardMonitor → newItemPublisher
        ├── DataStore (@MainActor, ObservableObject)
        ├── AppViewModel (@MainActor, ObservableObject)
        ├── HotkeyManager (Carbon)
        └── AutoLaunchManager (SMAppService)
```

### 数据流

```
复制操作 → NSPasteboard.changeCount 变化
  → ClipboardMonitor.poll()
    → 读取 .string / .tiff / .png
    → 去重检查
    → 图片: ThumbnailGenerator.generate() + 写文件
    → DataStore.add(item)
      → insert + cleanupExpired + enforceMaxCount
      → @Published items 更新
      → debounce 0.3s → saveItems() → items.json
```

## 数据模型

### ClipboardItem

```swift
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let contentType: ContentType       // .text | .image
    var textContent: String?           // 文字内容
    var imageFileName: String?         // Images/ 下的文件名
    var thumbnailData: Data?           // 48×48 JPEG 缩略图 (内联)
    let timestamp: Date
    var isPinned: Bool
    var contentHash: String?           // SHA256 前16位，用于去重
}
```

### ContentType

```swift
enum ContentType: String, Codable, CaseIterable {
    case text
    case image
}
```

### Settings

```swift
struct Settings: Codable {
    var maxItemCount: Int = 200
    var retentionDays: RetentionPeriod = .threeDays
    var launchAtLogin: Bool = true
}

enum RetentionPeriod: String, Codable, CaseIterable, Identifiable {
    case oneDay, threeDays, fiveDays
    var days: Int { switch self {
        case .oneDay: return 1
        case .threeDays: return 3
        case .fiveDays: return 5
    }}
}
```

## 存储规范

### 路径

```
~/Library/Application Support/PasteEcho/
├── items.json       # ClipboardItem 数组 (图片仅存文件名+缩略图)
├── settings.json    # Settings 单例
└── Images/          # 原始图片文件
    └── {uuid}.png
```

### 读写策略

- **读取**：应用启动时一次性加载 `items.json` 到内存
- **写入**：`$items` 发布者 `.debounce(0.3s)` 后全量写入
- **原子写入**：先写临时文件，再 `FileManager.replaceItemAt` 替换，防止写入中断损坏数据
- **图片**：保存条目时同步写入 Images/ 目录，删除条目时同步删除对应文件

## 关键技术方案

### 剪贴板轮询

```swift
// 每0.5秒对比 changeCount，变化则读取
Timer.publish(every: 0.5, on: .main, in: .common)
    .autoconnect()
    .sink { [weak self] _ in self?.poll() }
```

macOS 不支持跨进程剪贴板通知，轮询是唯一可靠方案。

### 去重

- 文字：与 `items.first?.textContent` 字符串对比
- 图片：SHA256 哈希前 16 位与 `items.first?.contentHash` 对比
- 仅与最新一条对比（性能考虑，连续复制相同内容通常相邻）

### 全局快捷键

```swift
// Carbon API, 无需辅助功能权限
RegisterEventHotKey(
    kVK_ANSI_V,           // V 键
    cmdKey | shiftKey,    // Cmd+Shift
    hotKeyID,
    GetEventDispatcherTarget(),
    0,
    &eventHotKeyRef
)
```

### 缩略图

- 目标尺寸：48×48 点（96×96 像素 @2x）
- 格式：JPEG，压缩质量 0.5
- 生成方式：aspect-fill 裁剪 → 缩放 → JPEG 编码
- 存储位置：内联在 ClipboardItem.thumbnailData 中

### 弹出面板

- 容器：`NSPopover`，固定尺寸 380×520
- 行为：`.transient`（点击外部自动关闭）
- 内容：`NSHostingView` 包装 SwiftUI 视图
- 环境对象注入：`.environmentObject(appViewModel)`

## 线程安全

- `DataStore` 标记 `@MainActor`，所有数据操作在主线程
- `AppViewModel` 标记 `@MainActor`
- `ClipboardMonitor` 的 Timer 运行在 `.main` RunLoop
- 剪贴板读取在主线程（NSPasteboard 要求）
- 缩略图生成可用 `Task.detached` 异步处理

## 错误处理策略

- 剪贴板读取失败：静默跳过，不崩溃
- JSON 解析失败：使用空数组/默认设置，备份损坏文件
- 图片文件丢失：卡片显示占位图标，不崩溃
- 磁盘空间不足：捕获错误，不崩溃，记录日志
- 快捷键注册失败：应用仍可正常使用（菜单栏点击），打印日志
