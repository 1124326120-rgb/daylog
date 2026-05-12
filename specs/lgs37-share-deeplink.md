# LGS-37 设计文档：分享生成应用链接代替纯文本

## 需求概述

当前详情页有分享按钮，分享内容为纯文本。需在分享文本末尾附加 `daylog://diary/{id}` 格式的应用链接，接收方点击链接可跳转回 App 打开对应日记。

## 改动文件清单

| 文件 | 改动类型 | 说明 |
|------|---------|------|
| `lib/pages/diary_detail_page.dart` | 修改 | 分享文本追加 `daylog://diary/{id}` |
| `lib/main.dart` | 修改 | 新增 `onGenerateRoute` 处理 `daylog://` URI |
| `lib/database/database_helper.dart` | 修改 | 新增 `getById(int id)` 查询方法 |
| `lib/pages/share_page.dart` | 修改 | 周报/月报分享文本包含 `daylog://diary/report` |
| `android/app/src/main/AndroidManifest.xml` | 新增 | 注册 `daylog://` 深链接 intent-filter |

## 详细设计

### 1. 分享文本格式

在 `diary_detail_page.dart` 的 `_share()` 方法中：

```
{mood_emoji} {date}
{content_summary}

daylog://diary/{id}
```

- 使用小写 `daylog://`（Android scheme 大小写敏感，统一小写）
- 不修改 `Share.share()` 调用方式，仅修改文本内容，兼容 share_plus

### 2. 深链接解析

在 `main.dart` 中：

```dart
// 在 MaterialApp 中添加 onGenerateRoute
onGenerateRoute: (settings) {
  if (settings.name != null && settings.name!.startsWith('daylog://diary/')) {
    final idStr = settings.name!.split('/').last;
    final id = int.tryParse(idStr);
    if (id != null) {
      return MaterialPageRoute(
        builder: (_) => DiaryDeepLinkPage(diaryId: id),
      );
    }
  }
  return null;
},
```

或沿用现有 `_onGenerateRoute` 方法。

### 3. DiaryDeepLinkPage 组件

新增临时页面（可在 main.dart 内嵌或单独文件）：

- 接收 `diaryId` 参数
- `initState` 中调用 `DatabaseHelper().getById(diaryId)`
- 加载完成后 `Navigator.pushReplacement` 到 `DiaryDetailPage`
- 处理加载中、未找到等状态

### 4. 数据库查询

在 `database_helper.dart` 中新增：

```dart
Future<DiaryEntry?> getById(int id) async {
  final db = await database;
  final result = await db.query('diaries', where: 'id = ?', whereArgs: [id]);
  if (result.isEmpty) return null;
  return DiaryEntry.fromMap(result.first);
}
```

### 5. AndroidManifest 配置

首次运行需生成 `android/` 目录：

```bash
flutter create --platforms=android .
```

然后在 `android/app/src/main/AndroidManifest.xml` 的 `<activity>` 内添加：

```xml
<!-- 在 <activity> 内部添加 -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="daylog" android:host="diary" />
</intent-filter>
```

### 6. 周报/月报分享链接

在 `share_page.dart` 中，图片分享附带的文本修改为：

```
"My moments on DayLog\n\ndaylog://diary/report"
```

## 兼容性说明

- share_plus 包调用方式不变，仅修改文本内容
- 未安装 App 时，点击 `daylog://` 链接不会跳转（系统级行为）
- 旧版本 App 打开 `daylog://` 链接无反应（需升级）
- 数据库查询 `getById` 对 main 分支的 diaries 表有效
