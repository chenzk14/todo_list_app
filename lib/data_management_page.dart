import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'event_model.dart';
import 'file_storage.dart';
import 'local_storage.dart';
import 'toast_util.dart';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  DataManagementPageState createState() => DataManagementPageState();
}

class DataManagementPageState extends State<DataManagementPage> {
  Map<String, dynamic> _fileInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadFileInfo();
  }

  Future<void> loadFileInfo() async {
    final info = await FileStorage.getFileInfo();
    setState(() {
      _fileInfo = info;
    });
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      showToast(context, '存储权限已授权');
    } else {
      showToast(context, '需要存储权限才能进行文件操作');
    }
  }

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await LocalStorage.loadEvents();
      if (events.isEmpty) {
        showToast(context, '没有数据可以导出');
        return;
      }

      final exportFile = await FileStorage.exportData(events);
      showToast(context, '数据已导出到: ${exportFile.path}');
    } catch (e) {
      showToast(context, '导出失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.path != null) {
          if (!file.path!.toLowerCase().endsWith('.json')) {
            showToast(context, '请选择 JSON 格式的文件');
            return;
          }

          final fileObj = File(file.path!);
          final events = await FileStorage.importData(fileObj);

          await LocalStorage.saveEvents(events);

          showToast(context, '成功导入 ${events.length} 条数据');

          loadFileInfo();
        } else {
          if (file.bytes != null) {
            if (!file.name.toLowerCase().endsWith('.json')) {
              showToast(context, '请选择 JSON 格式的文件');
              return;
            }

            final data = utf8.decode(file.bytes!);
            final jsonData = jsonDecode(data) as Map<String, dynamic>;
            List<Event> events;
            
            if (jsonData.containsKey('events')) {
              final eventList = jsonData['events'] as List<dynamic>;
              events = eventList.map((e) => Event.fromJson(e)).toList();
            } else if (jsonData is List) {
              events = (jsonData as List).map((e) => Event.fromJson(e)).toList();
            } else {
              events = [Event.fromJson(jsonData)];
            }

            await LocalStorage.saveEvents(events);

            showToast(context, '成功导入 ${events.length} 条数据');

            loadFileInfo();
          } else {
            showToast(context, '无法读取文件内容');
          }
        }
      }
    } catch (e) {
      showToast(context, '导入失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _backupData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await LocalStorage.loadEvents();
      await FileStorage.saveEventsToFile(events);
      showToast(context, '数据备份成功');
      loadFileInfo();
    } catch (e) {
      showToast(context, '备份失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 16),
                    _buildFileInfoCard(),
                    SizedBox(height: 16),
                    _buildActionGrid(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据管理',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            SizedBox(height: 4),
            Text(
              '备份、导出、导入您的数据',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9A9AB0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF4A7CF7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF4A7CF7),
                ),
              ),
              SizedBox(width: 10),
              Text(
                '数据文件信息',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_fileInfo['exists'] == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('文件路径', '${_fileInfo['path']}'),
                SizedBox(height: 8),
                _buildInfoRow('文件大小', '${_fileInfo['size']} bytes'),
                SizedBox(height: 8),
                _buildInfoRow('修改时间', '${_fileInfo['modified']}'),
              ],
            )
          else
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '暂无数据文件',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A9AB0),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9A9AB0),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '功能操作',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.backup,
                title: '备份数据',
                subtitle: '备份到本地文件',
                onTap: _backupData,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.import_export,
                title: '导出数据',
                subtitle: '导出用于分享',
                onTap: _exportData,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.file_download,
                title: '导入数据',
                subtitle: '从文件导入',
                onTap: _importData,
                color: Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.security,
                title: '权限管理',
                subtitle: '管理存储权限',
                onTap: _requestPermissions,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF9A9AB0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}