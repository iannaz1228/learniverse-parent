import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String versionName;
  final int versionCode;
  final String downloadUrl;
  final double fileSizeMb;
  final String releaseNotes;
  final bool isForce;

  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    required this.fileSizeMb,
    required this.releaseNotes,
    required this.isForce,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
        versionName: json['version_name'] as String,
        versionCode: json['version_code'] as int,
        downloadUrl: json['download_url'] as String,
        fileSizeMb: (json['file_size_mb'] as num?)?.toDouble() ?? 0,
        releaseNotes: json['release_notes'] as String? ?? '',
        isForce: json['is_force'] as bool? ?? false,
      );
}

class UpdateService {
  static Future<AppUpdateInfo?> checkForUpdate({String app = 'parent'}) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 1;

      final data = await Supabase.instance.client
          .from('app_versions')
          .select()
          .eq('app', app)
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      final remoteCode = data['version_code'] as int;
      if (remoteCode <= currentCode) return null;

      return AppUpdateInfo.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Future<void> openDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
