# PasteEcho — 项目文件结构

```
PasteEcho/
├── project.yml                      # XcodeGen 工程描述
├── PasteEcho.xcodeproj/             # [生成] Xcode 工程 (xcodegen generate)
├── CLAUDE.md                        # AI 助手指引文件
├── reconstruction-log.md            # 工程重构记录
├── docs/                            # 项目文档
│   ├── requirements.md              # 产品需求文档 (PRD)
│   ├── tech-spec.md                 # 技术规格文档
│   ├── design-spec.md               # UI 设计规范
│   ├── development-phases.md        # 分阶段开发计划
│   └── project-structure.md         # 本文件，项目结构说明
│
├── devlog/                          # 开发日志
│   └── YYYY-MM-DD.md               # 每日开发记录
│
├── Sources/                         # 所有 Swift 源码
│   ├── App/
│   │   ├── PasteEchoApp.swift       # @main 应用入口
│   │   └── AppDelegate.swift        # 核心协调器
│   ├── Models/
│   │   ├── ClipboardItem.swift
│   │   ├── ContentType.swift
│   │   └── Settings.swift
│   ├── Services/
│   │   ├── ClipboardMonitor.swift
│   │   ├── DataStore.swift
│   │   ├── HotkeyManager.swift
│   │   ├── ThumbnailGenerator.swift
│   │   └── AutoLaunchManager.swift
│   ├── ViewModels/
│   │   └── AppViewModel.swift
│   ├── Views/
│   │   ├── PopoverRootView.swift
│   │   ├── SearchBar.swift
│   │   ├── ClipboardListView.swift
│   │   ├── ClipboardCard.swift
│   │   ├── ThumbnailImageView.swift
│   │   ├── SettingsView.swift
│   │   └── EmptyStateView.swift
│   └── Extensions/
│       ├── Color+Theme.swift
│       └── Date+Relative.swift
│
└── Resources/
    ├── Info.plist                   # 应用配置 (LSUIElement=YES, Bundle ID 已固化)
    └── Assets.xcassets/
        ├── AppIcon.appiconset/      # App 图标
        └── AccentColor.colorset/    # 强调色 #4D99F2
```

## 分层说明

| 层级 | 目录 | 职责 |
|------|------|------|
| 视图层 | `Views/` | SwiftUI 视图组件，负责 UI 渲染和用户交互 |
| 视图模型层 | `ViewModels/` | 管理 UI 状态，桥接视图和数据层 |
| 服务层 | `Services/` | 核心业务逻辑：剪贴板、存储、快捷键、缩略图 |
| 模型层 | `Models/` | 数据结构定义 |
| 扩展层 | `Extensions/` | 系统类型的便捷扩展 |

## 调用规则

- Views 只能访问 ViewModels 和 Models（通过 `@EnvironmentObject` 和 `@ObservedObject`）
- ViewModels 只能访问 Services 和 Models
- Services 只能访问 Models，Service 之间不互相依赖
- Models 不依赖任何其他层
