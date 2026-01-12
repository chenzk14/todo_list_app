# Todo List App (一键打卡)

一个简洁美观的 Flutter 打卡应用，采用 Apple 风格的 UI 设计。

## 功能特性

- ✅ **一键打卡** - 快速记录打卡事件
- 📊 **数据统计** - 年度/月度统计图表，详细数据查看
- 💾 **数据管理** - 数据备份、导出、导入功能
- 🎨 **Apple 风格 UI** - 科技蓝配色，简洁优雅的设计

## 技术栈

- Flutter 3.0+
- Dart 3.0+
- Syncfusion Flutter Charts - 图表展示
- Table Calendar - 日历组件
- Path Provider - 文件路径管理
- File Picker - 文件选择

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── home_page.dart            # 首页（打卡页面）
├── statistics_page.dart      # 统计页面
├── data_management_page.dart # 数据管理页面
├── event_model.dart          # 事件数据模型
├── local_storage.dart        # 本地存储管理
└── file_storage.dart         # 文件存储管理
```

## 安装运行

1. 确保已安装 Flutter SDK
2. 克隆项目：
```bash
git clone <your-repo-url>
cd todo_list_app
```

3. 安装依赖：
```bash
flutter pub get
```

4. 运行应用：
```bash
flutter run
```

## 主要功能说明

### 打卡功能
- 点击浮动按钮快速打卡
- 支持选择日期打卡
- 日历视图显示打卡记录

### 统计功能
- 年度/月度统计切换
- 可视化图表展示
- 详细的年月日统计信息

### 数据管理
- 数据备份到本地文件
- 导出数据为 JSON 格式
- 从文件导入数据
- 文件保存到外部存储根目录

## 许可证

MIT License
