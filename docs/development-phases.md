# PasteEcho — 分阶段开发计划

## 开发原则

- 每个阶段独立可验证，不依赖后续阶段的代码
- 每完成一个阶段做一次完整的编译测试
- 代码提交以阶段为单位，便于回退
- 遇到阻塞问题优先解决，不在阻塞状态下继续开发

---

## Phase 1: 项目骨架

**目标**：Xcode 项目跑起来，数据模型就位

**任务**：
1. 在 Xcode 中创建 macOS App 项目（SwiftUI + Swift）
2. 配置 Info.plist，添加 `LSUIElement = YES`
3. 创建目录结构（Models / Services / ViewModels / Views / Extensions / Resources）
4. 实现 `ContentType.swift` 枚举
5. 实现 `ClipboardItem.swift` 数据模型
6. 实现 `Settings.swift` 设置模型
7. 编译通过，零错误零警告

**验证**：`Cmd+B` 编译成功

---

## Phase 2: 数据层

**目标**：数据可以安全地存取，清理逻辑正确

**任务**：
1. 实现 `DataStore.swift`：
   - `init()`：创建存储目录，加载 items.json 和 settings.json
   - `add(item:)`：添加条目到数组头部
   - `remove(id:)`：删除条目及关联图片文件
   - `cleanupExpired()`：按保留天数清理非置顶条目
   - `enforceMaxCount()`：按最大条数清理最旧非置顶条目
   - `saveItems()` / `loadItems()`：JSON 序列化/反序列化（含原子写入）
   - `saveSettings()` / `loadSettings()`
   - `$items` debounce 自动保存
2. 实现 `ThumbnailGenerator.swift`：48×48 JPEG 缩略图生成
3. 实现 `Date+Relative.swift`：相对时间格式化
4. 编译通过

**验证**：可写简单测试代码验证数据存取和清理逻辑

---

## Phase 3: 剪贴板监控

**目标**：App 能自动捕获剪贴板变化

**任务**：
1. 实现 `ClipboardMonitor.swift`：
   - Timer 0.5s 间隔轮询 `NSPasteboard.general.changeCount`
   - 检测变化后读取 `.string`（文字）或 `.tiff`/`.png`（图片）
   - 去重逻辑（文字对比内容，图片对比 hash）
   - 通过 `PassthroughSubject` 发布新条目
   - `start()` / `stop()` 控制方法
2. 在 AppDelegate 中集成 Monitor 和 DataStore
3. 编译通过

**验证**：运行 App，在任意 App 中复制文字/图片，通过断点或 print 确认捕获成功

---

## Phase 4: 菜单栏 + 弹出面板框架

**目标**：菜单栏出现图标，点击弹出空面板

**任务**：
1. 实现 `PasteEchoApp.swift`（@main 入口 + 设置窗口场景）
2. 实现 `AppDelegate.swift`：
   - `NSStatusItem` 菜单栏图标（`clipboard.fill`）
   - `NSPopover`（380×520，`.transient` 行为）
   - 点击图标切换 popover 显示/隐藏
   - 生命周期管理（启动监控、停止监控）
3. 实现 `PopoverRootView.swift`（面板框架布局：标题栏 + 内容区占位）
4. 实现 `EmptyStateView.swift`（空状态提示）
5. 编译通过

**验证**：运行 App，菜单栏出现图标，点击弹出/关闭面板，显示空状态

---

## Phase 5: 卡片列表 UI

**目标**：面板中能看到历史记录卡片

**任务**：
1. 实现 `Color+Theme.swift`（主题色定义）
2. 实现 `ThumbnailImageView.swift`（缩略图/占位图标组件）
3. 实现 `ClipboardCard.swift`（单张卡片：缩略图 + 内容预览 + 时间）
4. 实现 `ClipboardListView.swift`（LazyVStack 列表）
5. 将 ClipboardListView 集成到 PopoverRootView
6. 编译通过

**验证**：运行 App，复制几条内容，面板中能看到卡片列表

---

## Phase 6: 交互功能

**目标**：卡片可点击粘贴、可置顶、可删除、可搜索

**任务**：
1. 实现 `AppViewModel.swift`：
   - 绑定 DataStore，提供排序后的 displayItems
   - `searchQuery` 搜索过滤
   - `pasteItem(_:)` 复制回剪贴板
   - `togglePin(_:)` 置顶/取消
   - `deleteItem(_:)` 删除
2. 实现 `SearchBar.swift`（搜索输入框）
3. 在 ClipboardCard 添加悬停操作按钮和点击粘贴
4. 添加粘贴后的视觉反馈
5. 编译通过

**验证**：完整的操作流程测试——捕获→搜索→置顶→粘贴→删除

---

## Phase 7: 设置 + 快捷键 + 开机启动

**目标**：完整的用户设置和快捷操作

**任务**：
1. 实现 `SettingsView.swift`：
   - 保留天数选择器
   - 最大条数输入
   - 开机启动开关
   - 即时保存
2. 实现 `HotkeyManager.swift`（Cmd+Shift+V 全局快捷键）
3. 实现 `AutoLaunchManager.swift`（SMAppService）
4. 编译通过

**验证**：修改设置即时生效，Cmd+Shift+V 在任意 App 中可呼出面板

---

## Phase 8: 打磨

**目标**：最终品质提升

**任务**：
1. 深色模式适配检查
2. 卡片出现/消失动画
3. 滚动性能优化
4. 端到端完整测试（参考 docs/requirements.md 验证清单）
5. 清理调试代码

**验证**：完整回归测试，所有功能正常
