import 'package:flutter/material.dart';

import '../models/download_task.dart';
import '../services/download_service.dart';

class DownloadOverlay extends StatelessWidget {
  const DownloadOverlay({super.key, required this.child});

  final Widget child;

  String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final service = DownloadService.instance;
    return Stack(
      children: [
        child,
        ValueListenableBuilder<List<DownloadTask>>(
          valueListenable: service.tasks,
          builder: (context, tasks, _) {
            final active = tasks
                .where((t) => t.status == DownloadStatus.downloading)
                .toList();
            if (active.isEmpty) return const SizedBox.shrink();
            return Positioned(
              right: 16,
              bottom: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final task in active)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(task.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    if (task.remaining != null)
                                      Text(
                                        'Reste ${_format(task.remaining!)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    LinearProgressIndicator(value: task.progress),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => service.cancel(task),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
