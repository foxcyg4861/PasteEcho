# AGENTS.md — PasteEcho 项目指引

## 项目简介

PasteEcho 是一款 macOS 菜单栏剪贴板管理工具，使用 SwiftUI + Swift 原生开发，零第三方依赖。

## 文档索引

在开始任何开发工作前，请先阅读以下文档：

| 文档 | 路径 | 说明 |
|------|------|------|
| 产品需求 | [docs/requirements.md](docs/requirements.md) | 完整的功能和非功能需求 |
| 技术规格 | [docs/tech-spec.md](docs/tech-spec.md) | 架构设计、数据模型、关键技术方案 |
| 设计规范 | [docs/design-spec.md](docs/design-spec.md) | UI 颜色、字体、布局、图标、交互规范 |
| 开发计划 | [docs/development-phases.md](docs/development-phases.md) | 8 个阶段的详细任务拆解 |
| 项目结构 | [docs/project-structure.md](docs/project-structure.md) | 文件目录分层和调用规则 |

## 工作约定

### 开发节奏

1. **严格按阶段推进**：按照 `docs/development-phases.md` 中的 8 个阶段顺序开发
2. **每阶段独立验证**：完成一个阶段后必须编译通过（零错误零警告）并做功能验证
3. **不跨越阶段**：不提前写下一阶段的代码，避免未完成的依赖
4. **遇到问题先记录**：在 `devlog/` 中记录，不在阻塞状态下强行推进

### 开发日志

每天开始工作时：
1. 在 `devlog/` 中创建当天的日志文件 `YYYY-MM-DD.md`
2. 参考前一天的日志了解进度
3. 结束时更新今日完成和待办事项

### 代码规范

- 所有类型、方法、变量使用英文命名，遵循 Swift 官方命名规范
- SwiftUI View 使用 `struct`，ViewModel 和 Service 使用 `class` + `@MainActor` + `ObservableObject`
- 不写注释，除非逻辑非常不直观
- 不使用第三方依赖
- 错误处理：静默容错，不崩溃，关键位置用 `print` 输出日志

### 分支与提交

- 以阶段为单位提交代码
- Commit message 格式：`Phase X: 简短描述`
- 每天收工时暂存当前进度

## 快速命令

```bash
# 构建项目
cd PasteEcho && xcodebuild -project PasteEcho.xcodeproj -scheme PasteEcho build

# 运行项目
cd PasteEcho && xcodebuild -project PasteEcho.xcodeproj -scheme PasteEcho -configuration Debug run
```
