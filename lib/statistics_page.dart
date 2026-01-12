import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'event_model.dart';
import 'local_storage.dart';

// Apple 科技蓝配色
class AppColors {
  static const Color techBlue = Color(0xFF007AFF);
  static const Color techBlueLight = Color(0xFF5AC8FA);
  static const Color techBlueDark = Color(0xFF0051D5);
  static const Color background = Color(0xFFF2F2F7);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
}

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with SingleTickerProviderStateMixin {
  List<Event> _events = [];
  bool _isYearly = true;
  bool _isChartExpanded = true;
  final Map<int, bool> _yearExpanded = {};
  int? _selectedYear;
  late TabController _tabController;
  List<int> _existingYears = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    if (_existingYears.isNotEmpty) {
    _tabController.dispose();
    }
    super.dispose();
  }

  // 加载事件
  Future<void> _loadEvents() async {
    final events = await LocalStorage.loadEvents();
    setState(() {
      _events = events;
      _existingYears = _getExistingYears();
      if (_existingYears.isNotEmpty) {
        _tabController = TabController(
          length: _existingYears.length,
          vsync: this,
          initialIndex: _existingYears.length - 1,
        );
      }
    });
  }

  // 获取统计数据
  List<ChartData> _getStatisticsData() {
    if (_isYearly) {
      final Map<int, int> yearlyCount = {};
      for (final event in _events) {
        final year = event.date.year;
        yearlyCount[year] = (yearlyCount[year] ?? 0) + 1;
      }
      return yearlyCount.entries
          .map((entry) => ChartData('${entry.key}年', entry.value))
          .toList();
    } else {
      final Map<int, int> monthlyCount = {};
      final selectedYear = _selectedYear ?? DateTime.now().year;
      for (final event in _events) {
        if (event.date.year == selectedYear) {
          final month = event.date.month;
          monthlyCount[month] = (monthlyCount[month] ?? 0) + 1;
        }
      }
      return List.generate(12, (index) {
        final month = index + 1;
        return ChartData('$month月', monthlyCount[month] ?? 0);
      });
    }
  }

  // 获取存在数据的年份列表
  List<int> _getExistingYears() {
    final Set<int> years = {};
    for (final event in _events) {
      years.add(event.date.year);
    }
    return years.toList()..sort();
  }

  // 获取每年每月有事件发生的日期列表
  Widget _buildYearlyMonthlyEventDays() {
    final Map<int, Map<int, Set<int>>> yearlyMonthlyEventDays = {};
    final Map<int, int> yearlyTotalCount = {};

    for (final event in _events) {
      final year = event.date.year;
      final month = event.date.month;
      final day = event.date.day;

      if (!yearlyMonthlyEventDays.containsKey(year)) {
        yearlyMonthlyEventDays[year] = {};
        yearlyTotalCount[year] = 0;
      }

      if (!yearlyMonthlyEventDays[year]!.containsKey(month)) {
        yearlyMonthlyEventDays[year]![month] = {};
      }

      yearlyMonthlyEventDays[year]![month]!.add(day);
      yearlyTotalCount[year] = (yearlyTotalCount[year] ?? 0) + 1;
    }

    final sortedYears = yearlyMonthlyEventDays.keys.toList()..sort();

    if (sortedYears.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '暂无年份数据',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // 年份Tab切换 - Apple风格
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.techBlue,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            tabs: sortedYears.map((year) {
              return Tab(
                text: '$year年',
              );
            }).toList(),
          ),
        ),

        // 详细信息内容 - 使用Expanded和SingleChildScrollView修复滚动
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: sortedYears.map((year) {
              if (!_yearExpanded.containsKey(year)) {
                _yearExpanded[year] = false;
              }

              return SingleChildScrollView(
                physics: BouncingScrollPhysics(), // Apple风格的弹性滚动
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _buildYearCard(year, yearlyMonthlyEventDays, yearlyTotalCount),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 构建年份卡片
  Widget _buildYearCard(
    int year,
    Map<int, Map<int, Set<int>>> yearlyMonthlyEventDays,
    Map<int, int> yearlyTotalCount,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: EdgeInsets.only(bottom: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.techBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppColors.techBlue,
              size: 22,
            ),
          ),
                      title: Text(
                        '$year年统计',
                        style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '总计 ${yearlyTotalCount[year]} 次打卡',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          trailing: Icon(
            _yearExpanded[year]!
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
                      initiallyExpanded: _yearExpanded[year]!,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _yearExpanded[year] = expanded;
                        });
                      },
                      children: [
                        for (int month = 1; month <= 12; month++)
              _buildMonthTile(
                month,
                yearlyMonthlyEventDays[year]?[month]?.toList() ?? [],
                month < 12,
              ),
          ],
        ),
      ),
    );
  }

  // 构建月份Tile
  Widget _buildMonthTile(int month, List<int> days, bool showDivider) {
    days.sort();
    final count = days.length;
    
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: AppColors.background,
                  width: 0.5,
                ),
              )
            : null,
      ),
                            child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
          width: 36,
          height: 36,
                                decoration: BoxDecoration(
            color: AppColors.techBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '$month',
                                    style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.techBlue,
                                    ),
                                  ),
                                ),
                              ),
        title: Text(
          '$month 月',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            days.isEmpty
                                  ? '本月无打卡记录'
                : '打卡日期: ${days.join('日, ')}日',
                                style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
                                ),
                              ),
                            ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.techBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count次',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.techBlue,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '统计',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.techBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.techBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      size: 40,
                      color: AppColors.techBlue,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    '暂无打卡记录',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '开始打卡后即可查看统计信息',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: BouncingScrollPhysics(), // Apple风格的弹性滚动
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  SizedBox(height: 20),
                  
                  // 合并的统计方式和图表Card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 统计方式选择区域
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.techBlue,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      '统计方式',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                // Apple风格的Segmented Control
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildSegmentedButton(
                                          '年统计',
                                          true,
                                          _isYearly,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildSegmentedButton(
                                          '月统计',
                                          false,
                                          !_isYearly,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isYearly && _existingYears.isNotEmpty) ...[
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.techBlue.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: _selectedYear,
                                        isExpanded: true,
                                        icon: Icon(
                                          Icons.keyboard_arrow_down,
                                          color: AppColors.techBlue,
                                        ),
                                        hint: Text(
                                          '选择年份',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 15,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        items: _existingYears.map((year) {
                                          return DropdownMenuItem<int>(
                                            value: year,
                                            child: Text('$year年'),
                                          );
                                        }).toList(),
                                        onChanged: (year) {
                                          setState(() {
                                            _selectedYear = year;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // 分隔线
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.background,
                          ),
                          
                          // 图表区域
                          Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isChartExpanded = !_isChartExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.techBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.auto_graph_rounded,
                                          color: AppColors.techBlue,
                                          size: 22,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '打卡统计图表',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 17,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              _isYearly ? '年度统计' : '月度统计',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        _isChartExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_isChartExpanded)
                                Container(
                                  height: 320,
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                                  child: SfCartesianChart(
                                    plotAreaBorderWidth: 0,
                                    primaryXAxis: CategoryAxis(
                                      title: AxisTitle(
                                        text: _isYearly ? '年份' : '月份',
                                        textStyle: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      majorGridLines: MajorGridLines(width: 0),
                                    ),
                                    primaryYAxis: NumericAxis(
                                      title: AxisTitle(
                                        text: '次数',
                                        textStyle: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      numberFormat: NumberFormat.decimalPattern(),
                                      interval: 1,
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      majorGridLines: MajorGridLines(
                                        width: 0.5,
                                        color: AppColors.background,
                                      ),
                                    ),
                                    series: <CartesianSeries<ChartData, String>>[
                                      ColumnSeries<ChartData, String>(
                                        dataSource: _getStatisticsData(),
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y,
                                        dataLabelSettings: DataLabelSettings(
                                          isVisible: true,
                                          textStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.techBlue,
                                          ),
                                        ),
                                        animationDuration: 600,
                                        color: AppColors.techBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),
                  
                  // 详细信息标题
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.techBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '详细信息',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 详细信息区域 - 使用固定高度避免滚动冲突
                  Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: _existingYears.isNotEmpty
                        ? _buildYearlyMonthlyEventDays()
                        : Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                '暂无年份数据',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                  ),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // 构建Segmented Button（Apple风格）
  Widget _buildSegmentedButton(String label, bool value, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _isYearly = value;
          if (!_isYearly && _selectedYear == null && _existingYears.isNotEmpty) {
            _selectedYear = _existingYears.last;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.techBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
                          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                ),
            ),
    );
  }
}

class ChartData {
  final String x;
  final int y;

  ChartData(this.x, this.y);
}
