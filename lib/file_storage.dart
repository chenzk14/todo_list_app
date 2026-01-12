import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'event_model.dart';

class FileStorage {
  static const String _fileName = 'todo_data.json';
  static const String _backupFileName = 'todo_data_backup.json';

  // 获取外部存储根目录
  static Future<Directory> get _storageDirectory async {
    try {
      // 优先使用外部存储目录
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // 从外部存储目录路径中提取根目录
        // 例如：/storage/emulated/0/Android/data/com.example.app/files -> /storage/emulated/0
        final path = externalDir.path;
        print('外部存储目录路径: $path');
        
        // 查找 'Android' 目录的位置
        final androidIndex = path.indexOf('/Android');
        if (androidIndex > 0) {
          final rootPath = path.substring(0, androidIndex);
          final rootDir = Directory(rootPath);
          print('提取的根目录路径: $rootPath');
          
          // 检查目录是否存在（根目录应该总是存在的）
          if (await rootDir.exists()) {
            return rootDir;
          } else {
            print('警告: 根目录不存在: $rootPath');
          }
        }
        
        // 如果找不到 Android 目录，尝试其他方法
        // 查找 'emulated' 或 'sdcard'
        final pathParts = path.split('/');
        for (int i = 0; i < pathParts.length; i++) {
          if (pathParts[i] == 'emulated' && i + 1 < pathParts.length) {
            final rootPath = '/' + pathParts.sublist(0, i + 2).join('/');
            final rootDir = Directory(rootPath);
            if (await rootDir.exists()) {
              print('通过 emulated 找到根目录: $rootPath');
              return rootDir;
            }
          } else if (pathParts[i] == 'sdcard') {
            final rootPath = '/' + pathParts.sublist(0, i + 1).join('/');
            final rootDir = Directory(rootPath);
            if (await rootDir.exists()) {
              print('通过 sdcard 找到根目录: $rootPath');
              return rootDir;
            }
          }
        }
        
        // 如果都找不到，直接使用外部存储目录
        print('使用外部存储目录作为根目录: ${externalDir.path}');
        return externalDir;
      }
    } catch (e) {
      print('获取外部存储目录失败: $e');
    }
    // 如果外部存储不可用，使用应用文档目录
    final appDir = await getApplicationDocumentsDirectory();
    print('回退到应用文档目录: ${appDir.path}');
    return appDir;
  }

  // 获取数据文件路径
  static Future<File> get _dataFile async {
    final directory = await _storageDirectory;
    return File('${directory.path}/$_fileName');
  }

  // 获取备份文件路径
  static Future<File> get _backupFile async {
    final directory = await _storageDirectory;
    return File('${directory.path}/$_backupFileName');
  }

  // 保存事件列表到文件
  static Future<void> saveEventsToFile(List<Event> events) async {
    try {
      final directory = await _storageDirectory;
      // 确保目录存在
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final file = await _dataFile;
      final eventList = events.map((event) => event.toJson()).toList();
      final jsonData = json.encode({
        'version': '1.0',
        'createdAt': DateTime.now().toIso8601String(),
        'events': eventList,
      });
      
      print('保存文件到: ${file.path}');
      await file.writeAsString(jsonData);
      print('文件保存成功，文件大小: ${await file.length()} 字节');
      
      // 同时创建备份
      try {
        final backupFile = await _backupFile;
        await backupFile.writeAsString(jsonData);
        print('备份文件保存成功: ${backupFile.path}');
      } catch (e) {
        print('备份文件保存失败（非致命）: $e');
      }
    } catch (e, stackTrace) {
      print('保存文件失败: $e');
      print('堆栈跟踪: $stackTrace');
      // 如果保存到根目录失败，尝试保存到应用文档目录
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fallbackFile = File('${appDir.path}/$_fileName');
        final eventList = events.map((event) => event.toJson()).toList();
        final jsonData = json.encode({
          'version': '1.0',
          'createdAt': DateTime.now().toIso8601String(),
          'events': eventList,
        });
        await fallbackFile.writeAsString(jsonData);
        print('已回退保存到应用文档目录: ${fallbackFile.path}');
      } catch (fallbackError) {
        print('回退保存也失败: $fallbackError');
        throw Exception('保存数据失败: $e');
      }
    }
  }

  // 从文件加载事件列表
  static Future<List<Event>> loadEventsFromFile() async {
    try {
      // 首先尝试从根目录加载
      final file = await _dataFile;
      if (await file.exists()) {
        print('从根目录加载文件: ${file.path}');
        final contents = await file.readAsString();
        final jsonData = json.decode(contents) as Map<String, dynamic>;
        final eventList = jsonData['events'] as List<dynamic>;
        return eventList.map((eventJson) => Event.fromJson(eventJson)).toList();
      }
      
      // 如果根目录文件不存在，尝试从应用文档目录加载（回退位置）
      final appDir = await getApplicationDocumentsDirectory();
      final fallbackFile = File('${appDir.path}/$_fileName');
      if (await fallbackFile.exists()) {
        print('从应用文档目录加载文件: ${fallbackFile.path}');
        final contents = await fallbackFile.readAsString();
        final jsonData = json.decode(contents) as Map<String, dynamic>;
        final eventList = jsonData['events'] as List<dynamic>;
        return eventList.map((eventJson) => Event.fromJson(eventJson)).toList();
      }
      
      return [];
    } catch (e) {
      print('读取文件失败: $e');
      // 尝试从备份文件恢复
      return await _restoreFromBackup();
    }
  }

  // 从备份文件恢复数据
  static Future<List<Event>> _restoreFromBackup() async {
    try {
      final backupFile = await _backupFile;
      if (await backupFile.exists()) {
        final contents = await backupFile.readAsString();
        final jsonData = json.decode(contents) as Map<String, dynamic>;
        final eventList = jsonData['events'] as List<dynamic>;
        return eventList.map((eventJson) => Event.fromJson(eventJson)).toList();
      }
      return [];
    } catch (e) {
      print('从备份恢复失败: $e');
      return [];
    }
  }

  // 导出数据到指定文件（用于分享或备份）
  static Future<File> exportData(List<Event> events) async {
    try {
      final directory = await _storageDirectory;
      final exportFile = File('${directory.path}/todo_data_export_${DateTime.now().millisecondsSinceEpoch}.json');
      
      final eventList = events.map((event) => event.toJson()).toList();
      final jsonData = json.encode({
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'totalEvents': events.length,
        'events': eventList,
      });
      
      await exportFile.writeAsString(jsonData);
      return exportFile;
    } catch (e) {
      print('导出数据失败: $e');
      throw Exception('导出数据失败');
    }
  }

  // 从外部文件导入数据
  static Future<List<Event>> importData(File file) async {
    try {
      final contents = await file.readAsString();
      final jsonData = json.decode(contents) as Map<String, dynamic>;
      final eventList = jsonData['events'] as List<dynamic>;
      final events = eventList.map((eventJson) => Event.fromJson(eventJson)).toList();
      
      // 保存导入的数据
      await saveEventsToFile(events);
      return events;
    } catch (e) {
      print('导入数据失败: $e');
      throw Exception('导入数据失败: 文件格式不正确');
    }
  }

  // 检查文件是否存在
  static Future<bool> dataFileExists() async {
    final file = await _dataFile;
    return await file.exists();
  }

  // 获取文件信息
  static Future<Map<String, dynamic>> getFileInfo() async {
    final file = await _dataFile;
    if (await file.exists()) {
      final stat = await file.stat();
      return {
        'exists': true,
        'path': file.path,
        'size': stat.size,
        'modified': stat.modified,
      };
    }
    return {'exists': false};
  }

  // 删除数据文件（谨慎使用）
  static Future<void> deleteDataFile() async {
    try {
      final file = await _dataFile;
      if (await file.exists()) {
        await file.delete();
      }
      final backupFile = await _backupFile;
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      print('删除文件失败: $e');
    }
  }
}
