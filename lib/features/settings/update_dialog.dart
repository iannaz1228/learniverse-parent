import 'package:flutter/material.dart';
import 'update_service.dart';

class UpdateDialog extends StatelessWidget {
  final AppUpdateInfo info;
  const UpdateDialog({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C3AED);
    const card   = Color(0xFF1A1040);

    return PopScope(
      canPop: !info.isForce,
      child: Dialog(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Update Available',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('LearniVerse Parent v${info.versionName}',
                        style: const TextStyle(color: Color(0xFFAB8FE8), fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
                if (info.isForce)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: const Text('Required',
                        style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ]),

              // Release notes
              if (info.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text("What's new",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...info.releaseNotes
                    .split('\n')
                    .map((l) => l.trim())
                    .where((l) => l.isNotEmpty)
                    .map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('• ', style: TextStyle(color: Color(0xFFAB8FE8), fontSize: 13)),
                            Expanded(child: Text(line,
                                style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4))),
                          ]),
                        )),
              ],

              // Hint
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFAB8FE8), size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    info.fileSizeMb > 0
                        ? 'Tap below to download (${info.fileSizeMb.toStringAsFixed(0)} MB). Open the file to install.'
                        : 'Tap below to download. Open the file to install.',
                    style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                  )),
                ]),
              ),

              // Actions
              const SizedBox(height: 20),
              Row(children: [
                if (!info.isForce) ...[
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Later', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => UpdateService.openDownload(info.downloadUrl),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download & Install', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
