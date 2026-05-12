# LGS-39 设计文档：草稿自动保存

## 需求概述

写日记页面输入内容后，自动保存草稿，防止应用意外关闭导致内容丢失。

## 改动文件清单

| 文件 | 改动类型 | 说明 |
|------|---------|------|
| `lib/database/database_helper.dart` | 修改 | DB v3→v4 迁移，新增 `drafts` 表 |
| `lib/pages/edit_diary_page.dart` | 修改 | 新增 30 秒定时器、WidgetsBindingObserver、草稿恢复逻辑 |
| `lib/l10n/app_localizations.dart` | 修改 | 新增 `draftSaved`, `draftRestored` 本地化 key |

## 详细设计

### 1. 数据库迁移

DB 版本从 v3→v4（与 LGS-38 共享版本号），新增 `drafts` 表：

```sql
CREATE TABLE IF NOT EXISTS drafts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  content TEXT NOT NULL,
  mood_emoji TEXT,
  image_path TEXT,
  updated_at TEXT NOT NULL
);
```

采用**单草稿模式**：表中最多一条记录，每次保存时 UPDATE 或先 DELETE 再 INSERT。

`onUpgrade` 合并处理 LGS-38 的 likes 表 + LGS-39 的 drafts 表：

```dart
if (oldVersion < 4) {
  await db.execute('CREATE TABLE IF NOT EXISTS likes (...)');
  await db.execute('CREATE TABLE IF NOT EXISTS drafts (...)');
}
```

DatabaseHelper 新增方法：
- `saveDraft(DiaryEntry entry)` — 清空已有记录 → INSERT
- `loadDraft()` — 查询第一条记录
- `clearDrafts()` — DELETE FROM drafts

### 2. 自动保存触发时机

在 `edit_diary_page.dart` 中：

**a) 30 秒定时器**
- `initState` 中启动 `Timer.periodic(Duration(seconds: 30), _autoSaveDraft)`
- `dispose` 中 `_draftTimer?.cancel()`

**b) App 进入后台**
- 实现 `WidgetsBindingObserver` 接口
- `didChangeAppLifecycleState(AppLifecycleState state)`：
  - `state == AppLifecycleState.paused` → 立即保存草稿

**c) dispose 兜底**
- `dispose()` 中最后保存一次草稿

### 3. 触发条件

- **仅新日记**保存草稿（`widget.entry == null`）
- 编辑已有日记**不保存草稿**（已存 DB，无需额外保护）
- 表单为空时不保存（减少无意义写入）

```dart
void _autoSaveDraft(Timer timer) {
  if (widget.entry != null) return; // 编辑模式不保存草稿
  if (_titleController.text.isEmpty && _contentController.text.isEmpty) return;
  _saveDraft();
}
```

### 4. 草稿恢复

- `initState` 中（或在 `_formKey` 就绪后）调用 `_loadDraft()`
- `_loadDraft()` 异步查询 drafts 表
- 有草稿 → 填充标题/内容/mood/image 控件 + 显示 SnackBar "已恢复上次的草稿"
- 无草稿 → 不操作

### 5. 草稿清理

- 成功提交日记后（`_save()` 中 `formState.save()` 成功后）调用 `DatabaseHelper().clearDrafts()`
- 表单重置时不清除草稿（用户可能想重新编辑）

### 6. UI 提示

- 草稿保存时：显示 SnackBar "草稿已保存"（防止频繁提示，可在首次保存时显示）
- 草稿恢复时：显示 SnackBar "已恢复上次的草稿"

### 7. 国际化

在 `app_localizations.dart`（和对应的 ARB/EN 文件）中新增：

```dart
String get draftSaved => '草稿已保存';
String get draftRestored => '已恢复上次的草稿';
```

英文：
```dart
String get draftSaved => 'Draft saved';
String get draftRestored => 'Previous draft restored';
```

## 兼容性说明

- 无 `drafts` 表的旧版 DB 首次使用时自动创建
- 编辑已存日记不触发草稿，不影响正常编辑流程
- 30 秒定时器在 dispose 时取消，无内存泄漏
- 单草稿模式避免数据膨胀
