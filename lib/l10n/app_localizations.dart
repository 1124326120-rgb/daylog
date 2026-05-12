import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isChinese => locale.languageCode == 'zh';

  // ---- General ----
  String get appName => isChinese ? 'DayLog 日记' : 'DayLog';
  String get save => isChinese ? '保存' : 'Save';
  String get saved => isChinese ? '已保存！' : 'Saved!';
  String get cancel => isChinese ? '取消' : 'Cancel';
  String get delete => isChinese ? '删除' : 'Delete';
  String get share => isChinese ? '分享' : 'Share';
  String get edit => isChinese ? '编辑' : 'Edit';
  String get loading => isChinese ? '加载中...' : 'Loading...';
  String get failed => isChinese ? '失败' : 'Failed';
  String get confirm => isChinese ? '确认' : 'Confirm';
  String get ok => isChinese ? '确定' : 'OK';

  // ---- Home ----
  String get home => isChinese ? '首页' : 'Home';
  String get write => isChinese ? '写日记' : 'Write';
  String get bottle => isChinese ? '漂流瓶' : 'Bottle';
  String get profile => isChinese ? '我的' : 'Profile';
  String get newDiary => isChinese ? '写日记' : 'New Diary';
  String get noEntries => isChinese ? '还没有日记' : 'No diary entries yet';
  String get noEntriesHint => isChinese ? '点击下方按钮开始写第一篇日记吧！' : 'Tap the button below to write your first diary entry!';
  String get calendar => isChinese ? '日历' : 'Calendar';
  String get meaningful => isChinese ? '有意义的' : 'Meaningful';

  // ---- Edit Diary ----
  String get newDiaryTitle => isChinese ? '写日记' : 'New Diary';
  String get editDiaryTitle => isChinese ? '编辑日记' : 'Edit Diary';
  String get diaryContent => isChinese ? '日记内容' : 'Diary Content';
  String get writeThoughts => isChinese ? '写下你的想法...' : 'Write your thoughts here...';
  String get pleaseWriteSomething => isChinese ? '请写点什么' : 'Please write something';
  String get titleLabel => isChinese ? '标题' : 'Title';
  String get titleHint => isChinese ? '给日记起个标题...' : 'Give your diary a title...';
  String get howAreYouFeeling => isChinese ? '你现在感觉如何？' : 'How are you feeling?';
  String get addPhoto => isChinese ? '添加照片' : 'Add Photo';
  String get photoSelected => isChinese ? '已选择照片' : 'Photo selected';
  String get photoGallery => isChinese ? '相册' : 'Photo Gallery';
  String get camera => isChinese ? '相机' : 'Camera';
  String get alsoThrowBottle => isChinese ? '同时扔进大海' : 'Also throw into the sea';
  String get bottleSubtitle => isChinese ? '匿名分享这条日记作为漂流瓶' : 'Share this diary entry anonymously as a bottle';
  String get bottleOnlyNew => isChinese ? '漂流瓶分享仅对新日记可用。' : 'Bottle sharing is only available for new diary entries.';

  // ---- Diary Detail ----
  String get deleteDiary => isChinese ? '删除日记' : 'Delete Diary';
  String get deleteConfirm => isChinese ? '确定要删除这篇日记吗？' : 'Are you sure you want to delete this diary entry?';

  // ---- Bottle ----
  String get pick => isChinese ? '捞取' : 'Pick';
  String get throwBottleLabel => isChinese ? '投放' : 'Throw';
  String get pickBottle => isChinese ? '捞一个漂流瓶' : 'Pick a Bottle';
  String get fishing => isChinese ? '打捞中...' : 'Fishing...';
  String get searchingSea => isChinese ? '在海中搜索...' : 'Searching the sea...';
  String get throwIntoSea => isChinese ? '投入大海' : 'Throw into the Sea';
  String get throwing => isChinese ? '投放中...' : 'Throwing...';
  String get picksRemaining => isChinese ? '今日剩余打捞次数' : 'Picks remaining today';
  String get throwsRemaining => isChinese ? '今日剩余投放次数' : 'Throws remaining today';
  String get writeBottleMsg => isChinese ? '写一条瓶子里的消息...' : 'Write a message to put in your bottle...';
  String get bottleMsgLength => isChinese ? '消息（最多280字）' : 'Message (max 280 chars)';
  String get pleaseWriteBottle => isChinese ? '请写点什么放入瓶子' : 'Please write something in your bottle';
  String get pickLimitReached => isChinese ? '已达每日上限！每天只能捞取3个瓶子。' : 'Daily limit reached! You can only pick 3 bottles per day.';
  String get throwLimitReached => isChinese ? '已达每日上限！每天只能投放3个瓶子。' : 'Daily limit reached! You can only throw 3 bottles per day.';
  String get bottleThrown => isChinese ? '瓶子已投入大海！' : 'Bottle thrown into the sea!';
  String get noBottles => isChinese ? '海里还没有瓶子，成为第一个投放的人吧！' : 'No bottles in the sea yet. Be the first to throw one!';
  String get liked => isChinese ? '已点赞！' : 'Liked!';
  String get failedLike => isChinese ? '点赞失败' : 'Failed to like';
  String get messageInBottle => isChinese ? '瓶子里的消息' : 'A Message in a Bottle';
  String get driftedIn => isChinese ? '漂流时间' : 'Drifted in';
  String get yourMood => isChinese ? '你的心情' : 'Your Mood';

  // ---- Review ----
  String get review => isChinese ? '回顾' : 'Review';
  String get weekly => isChinese ? '周报' : 'Weekly';
  String get monthly => isChinese ? '月报' : 'Monthly';
  String get weeklyReview => isChinese ? '周回顾' : 'Weekly Review';
  String get monthlyReview => isChinese ? '月回顾' : 'Monthly Review';
  String get entriesCount => isChinese ? '篇日记' : 'entries';
  String get moodDistribution => isChinese ? '心情分布' : 'Mood Distribution';
  String get topKeywords => isChinese ? '关键词' : 'Top Keywords';
  String get longestStreak => isChinese ? '最长连续' : 'Longest Streak';
  String get consecutiveDays => isChinese ? '天连续' : 'consecutive days';
  String get moodTrend => isChinese ? '心情趋势' : 'Mood Trend';
  String get week => isChinese ? '周' : 'Week';
  String get mostMeaningful => isChinese ? '最有意义' : 'Most Meaningful';
  String get shareReport => isChinese ? '分享报告' : 'Share this report';
  String get noEntriesWeek => isChinese ? '本周暂无日记' : 'No entries this week';
  String get noEntriesWeekHint => isChinese ? '写几篇日记来看看你的周回顾吧！' : 'Write some diary entries to see your weekly review!';
  String get noEntriesMonth => isChinese ? '本月暂无日记' : 'No entries this month';

  // ---- Settings / Profile ----
  String get dailyReminder => isChinese ? '每日提醒' : 'Daily Reminder';
  String get enableReminder => isChinese ? '启用每日提醒' : 'Enable daily reminder';
  String get reminderSubtitle => isChinese ? '提醒你写日记' : 'Get reminded to write your diary';
  String get reminderTime => isChinese ? '提醒时间' : 'Reminder time';
  String get previewNotification => isChinese ? '通知预览' : 'Preview notification text';
  String get notificationPreviewText => isChinese ? '今天有什么值得记录的吗？' : 'Today has something worth remembering?';
  String get about => isChinese ? '关于' : 'About';
  String get version => isChinese ? '版本' : 'Version';
  String get language => isChinese ? '语言' : 'Language';
  String get chinese => isChinese ? '中文' : 'Chinese';
  String get english => isChinese ? '英文' : 'English';
  String get languageButtonLabel => isChinese ? '中文' : 'ENGLISH';
  String get languageStatus => isChinese ? '当前语言：中文' : 'Current: English';

  // ---- This Day Last Year ----
  String get thisDayLastYear => isChinese ? '去年的今天' : 'This Day Last Year';
  String get noEntryLastYear => isChinese ? '去年今天没有日记' : 'No entry from last year';
  String get noEntryLastYearHint => isChinese ? '去年今天还没有日记。坚持每天记录吧！' : 'There is no diary entry for this day last year. Keep writing every day!';
  String get fromOneYearAgo => isChinese ? '来自一年前' : 'From 1 year ago';
  String get oneYearAgo => isChinese ? '一年前的今天' : 'One year ago today';
  String get tapToViewFull => isChinese ? '点击卡片查看详情' : 'Tap the card to view full details';

  // ---- Report Card ----
  String get myWeekOnDayLog => isChinese ? '我在DayLog的这一周' : 'My Week on DayLog';
  String get myMonthOnDayLog => isChinese ? '我在DayLog的这一月' : 'My Month on DayLog';
  String get madeWithDayLog => isChinese ? '使用 DayLog 记录 — 每一天都有意义' : 'Made with DayLog - Every Day Matters';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'zh';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      Future.value(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
