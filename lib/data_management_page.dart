import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'event_model.dart';
import 'file_storage.dart';
import 'local_storage.dart';

class DataManagementPage extends StatefulWidget {
  @override
  _DataManagementPageState createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  Map<String, dynamic> _fileInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFileInfo();
  }

  Future<void> _loadFileInfo() async {
    final info = await FileStorage.getFileInfo();
    setState(() {
      _fileInfo = info;
    });
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('存储权限已授权')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('需要存储权限才能进行文件操作')),
      );
    }
  }

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await LocalStorage.loadEvents();
      if (events.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('没有数据可以导出')),
        );
        return;
      }

      final exportFile = await FileStorage.exportData(events);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据已导出到: ${exportFile.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
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
      // 使用 FileType.any 来避免扩展名过滤问题
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.path != null) {
          // 检查文件扩展名
          if (!file.path!.toLowerCase().endsWith('.json')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('请选择 JSON 格式的文件')),
            );
            return;
          }

          // 使用 File 读取文件
          final fileObj = File(file.path!);
          final events = await FileStorage.importData(fileObj);

          // 同时更新SharedPreferences
          await LocalStorage.saveEvents(events);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 ${events.length} 条数据')),
          );

          _loadFileInfo();
        } else {
          // 处理 Android 11+ 的情况（通过字节读取）
          if (file.bytes != null) {
            // 检查文件名
            if (!file.name.toLowerCase().endsWith('.json')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('请选择 JSON 格式的文件')),
              );
              return;
            }

            // 从字节读取
            final data = utf8.decode(file.bytes!);
            // 解析 JSON（支持 FileStorage 导出的格式）
            final jsonData = jsonDecode(data) as Map<String, dynamic>;
            List<Event> events;
            
            // 检查是否是 FileStorage 导出的格式（包含 'events' 字段）
            if (jsonData.containsKey('events')) {
              final eventList = jsonData['events'] as List<dynamic>;
              events = eventList.map((e) => Event.fromJson(e)).toList();
            } else if (jsonData is List) {
              // 如果是直接的事件列表
              events = (jsonData as List).map((e) => Event.fromJson(e)).toList();
            } else {
              // 尝试作为事件列表解析
              events = [Event.fromJson(jsonData)];
            }

            await LocalStorage.saveEvents(events);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('成功导入 ${events.length} 条数据')),
            );

            _loadFileInfo();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('无法读取文件内容')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据备份成功')),
      );
      _loadFileInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('备份失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('数据管理'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件信息卡片
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '数据文件信息',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          _fileInfo['exists'] == true
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('文件路径: ${_fileInfo['path']}'),
                                    Text('文件大小: ${_fileInfo['size']} bytes'),
                                    Text('修改时间: ${_fileInfo['modified']}'),
                                  ],
                                )
                              : Text('暂无数据文件'),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // 操作按钮
                  Expanded(
                    child: ListView(
                      children: [
                        _buildActionCard(
                          icon: Icons.backup,
                          title: '备份数据',
                          subtitle: '将当前数据备份到本地文件',
                          onTap: _backupData,
                          color: Colors.green,
                        ),
                        
                        _buildActionCard(
                          icon: Icons.import_export,
                          title: '导出数据',
                          subtitle: '导出数据到外部文件用于分享',
                          onTap: _exportData,
                          color: Colors.blue,
                        ),
                        
                        _buildActionCard(
                          icon: Icons.file_download,
                          title: '导入数据',
                          subtitle: '从外部文件导入数据',
                          onTap: _importData,
                          color: Colors.orange,
                        ),
                        
                        _buildActionCard(
                          icon: Icons.security,
                          title: '权限管理',
                          subtitle: '管理存储权限',
                          onTap: _requestPermissions,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
