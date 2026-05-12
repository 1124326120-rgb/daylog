# LGS-38 设计文档：漂流瓶点赞/取消点赞 + 每人限点一次

## 需求概述

1. 已点赞的漂流瓶再次点击可取消点赞
2. 同一用户对同一漂流瓶最多点一次赞（不能重复累加）
3. 需记录点赞关系

## 改动文件清单

| 文件 | 改动类型 | 说明 |
|------|---------|------|
| `lib/database/database_helper.dart` | 修改 | DB v3→v4 迁移，新增 `likes` 表 |
| `lib/services/local_bottle_service.dart` | 修改 | 新增 `toggleLike()`, `isLiked()` 方法 |
| `lib/pages/bottle_page.dart` | 修改 | 点赞 UI 状态切换（实心/空心） |

## 详细设计

### 1. 数据库迁移

DB 版本从 v3→v4，新增 `likes` 表：

```sql
CREATE TABLE IF NOT EXISTS likes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bottle_id INTEGER NOT NULL,
  user_device_id TEXT NOT NULL,
  UNIQUE(bottle_id, user_device_id)
);
```

`onUpgrade` 处理：

```dart
if (oldVersion < 4) {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS likes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bottle_id INTEGER NOT NULL,
      user_device_id TEXT NOT NULL,
      UNIQUE(bottle_id, user_device_id)
    )
  ''');
}
```

### 2. 设备 ID 方案

在 `LocalBottleService` 中：

- `_getDeviceId()`：首次调用时生成 UUID，存入 SharedPreferences
- 后续调用直接返回已存储的 ID
- 不关联用户信息（漂流瓶匿名原则）

```dart
Future<String> _getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  const key = 'device_user_id';
  String? id = prefs.getString(key);
  if (id == null) {
    id = DateTime.now().microsecondsSinceEpoch.toString(); // 简单伪 UUID
    await prefs.setString(key, id);
  }
  return id;
}
```

### 3. LocalBottleService 新增方法

**`toggleLike(int bottleId)`**：
- 获取当前设备 ID
- 查询 `likes` 表是否有该 bottle_id + device_id 记录
- 有记录 → DELETE（取消点赞）→ `UPDATE bottles SET likes_count = MAX(0, likes_count - 1)`
- 无记录 → INSERT（点赞）→ `UPDATE bottles SET likes_count = likes_count + 1`
- 返回新的点赞状态（bool）

**`isLiked(int bottleId)`**：
- 查询 `likes` 表，返回是否有匹配记录

**`pickRandomBottle()` 修改**：
- 返回的 bottle 对象新增 `isLiked` 字段（查询 likes 表填充）
- 前端根据 `isLiked` 决定初始图标状态

### 4. UI 状态切换

在 `bottle_page.dart` 中：

- 使用 `isLiked` 局部状态变量
- 图标：`isLiked ? Icons.favorite : Icons.favorite_border`
- 颜色：已点赞红色 `Colors.red`，未点赞灰色 `Colors.grey`
- 点击调用 `toggleLike()` → 更新局部状态 + 刷新计数

### 5. BottleLimitService 注意事项

- 点赞/取消点赞**不计入每日捞取次数**
- `_remainingPicks` 初始值应为 3（确认不受点赞操作影响）

## 兼容性说明

- DB v3→v4 迁移向前兼容（旧数据无 likes 表，自动创建）
- 旧用户首次点赞时自动生成设备 ID
- `likes_count` 使用 `MAX(0, likes_count - 1)` 防止负数
- BottleModel 新增 `isLiked` 字段（nullable，默认 false）
