import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;

import '../core/app_theme.dart';
import '../core/duration_formatting.dart';
import '../core/number_formatting.dart';
import '../services/database_service.dart';
import '../widgets/protocol_icon.dart';

class IncidentLogScreen extends StatefulWidget {
  const IncidentLogScreen({super.key});

  @override
  State<IncidentLogScreen> createState() => _IncidentLogScreenState();
}

class _IncidentLogScreenState extends State<IncidentLogScreen> {
  late Future<List<Map<String, dynamic>>> _logsFuture;
  bool _selectionMode = false;
  final Set<int> _selectedLogIds = {};

  @override
  void initState() {
    super.initState();
    _logsFuture = DatabaseService.getIncidentLog();
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = DatabaseService.getIncidentLog();
    });
  }

  void _enterSelectionMode(int logId) {
    if (logId <= 0) return;
    setState(() {
      _selectionMode = true;
      _selectedLogIds.add(logId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedLogIds.clear();
    });
  }

  void _toggleSelectedLog(int logId) {
    if (logId <= 0) return;
    setState(() {
      if (_selectedLogIds.contains(logId)) {
        _selectedLogIds.remove(logId);
      } else {
        _selectedLogIds.add(logId);
      }
    });
  }

  Future<void> _clearLogs() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerLowest,
          title: Text(l10n.incidentLogClearTitle),
          content: Text(l10n.incidentLogClearBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.settingsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.incidentLogClearAction,
                style: TextStyle(color: cs.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await DatabaseService.clearIncidentLog();
      if (!mounted) return;
      _refreshLogs();
      messenger.showSnackBar(SnackBar(content: Text(l10n.incidentLogCleared)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.incidentLogClearFailed)),
      );
    }
  }

  Future<void> _deleteLog(int logId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerLowest,
          title: Text(l10n.incidentLogDeleteTitle),
          content: Text(l10n.incidentLogDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.settingsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.incidentLogDeleteAction,
                style: TextStyle(color: cs.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await DatabaseService.deleteIncidentLog(logId);
      if (!mounted) return;
      _refreshLogs();
      messenger.showSnackBar(SnackBar(content: Text(l10n.incidentLogDeleted)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.incidentLogDeleteFailed)),
      );
    }
  }

  Future<void> _deleteSelectedLogs() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedLogIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.incidentLogDeleteSelectedEmpty)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerLowest,
          title: Text(l10n.incidentLogDeleteSelectedTitle),
          content: Text(l10n.incidentLogDeleteSelectedBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.settingsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.incidentLogDeleteAction,
                style: TextStyle(color: cs.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await DatabaseService.deleteIncidentLogs(_selectedLogIds.toList());
      if (!mounted) return;
      _exitSelectionMode();
      _refreshLogs();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.incidentLogSelectedDeleted)),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.incidentLogDeleteFailed)),
      );
    }
  }

  String _emergencyTitle(AppLocalizations l10n, String emergencyType) {
    switch (emergencyType) {
      case 'choking':
        return l10n.emergencyChoking;
      case 'choking_infant':
        return l10n.emergencyChokingInfant;
      case 'cpr':
        return l10n.emergencyCPR;
      case 'cpr_infant':
        return l10n.emergencyCPRInfant;
      case 'burns':
        return l10n.emergencyBurns;
      case 'bleeding':
        return l10n.emergencyBleeding;
      case 'fractures':
        return l10n.emergencyFractures;
      case 'seizures':
        return l10n.emergencySeizures;
      default:
        return emergencyType;
    }
  }

  Color _emergencyColor(String emergencyType) {
    switch (emergencyType) {
      case 'choking':
      case 'choking_infant':
        return AppColors.chokingBlue;
      case 'cpr':
      case 'cpr_infant':
        return AppColors.cprRed;
      case 'burns':
        return AppColors.burnOrange;
      case 'bleeding':
        return AppColors.bleedingCrimson;
      case 'fractures':
        return AppColors.fracturePurple;
      case 'seizures':
        return AppColors.seizureAmber;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatTimestamp(BuildContext context, String rawTimestamp) {
    final parsed = DateTime.tryParse(rawTimestamp);
    if (parsed == null) return rawTimestamp;

    final locale = Localizations.localeOf(context);
    final pattern = locale.languageCode == 'he'
        ? 'd בMMMM y, HH:mm'
        : 'd MMMM y, HH:mm';
    return useWesternDigits(
      intl.DateFormat(pattern, locale.toLanguageTag()).format(parsed.toLocal()),
    );
  }

  List<int> _stepDurations(Map<String, dynamic> log) {
    final raw = log['step_durations_json'] as String?;
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((value) => value is int ? value : int.tryParse('$value') ?? 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<MapEntry<int, int>> _visibleStepDurations(List<int> stepDurations) {
    final parts = <MapEntry<int, int>>[];
    for (var i = 0; i < stepDurations.length; i++) {
      final seconds = stepDurations[i];
      if (seconds <= 0) continue;
      parts.add(MapEntry(i + 1, seconds));
    }

    return parts;
  }

  int _displayElapsedSeconds(
    int storedElapsedSeconds,
    List<int> stepDurations,
  ) {
    final stepTotal = stepDurations.fold<int>(
      0,
      (sum, seconds) => sum + seconds,
    );
    return stepTotal > 0 ? stepTotal : storedElapsedSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          _selectionMode
              ? l10n.incidentLogSelectionTitle(_selectedLogIds.length)
              : l10n.incidentLogTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
        actions: _selectionMode
            ? [
                TextButton(
                  onPressed: _exitSelectionMode,
                  child: Text(l10n.settingsCancel),
                ),
                IconButton(
                  tooltip: l10n.incidentLogDeleteAction,
                  onPressed: _selectedLogIds.isEmpty
                      ? null
                      : _deleteSelectedLogs,
                  icon: const Icon(Icons.delete_outline),
                ),
              ]
            : [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectionMode = true;
                    });
                  },
                  child: Text(l10n.incidentLogSelectAction),
                ),
                IconButton(
                  tooltip: l10n.incidentLogClearAction,
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _EmptyLogState(
              icon: Icons.error_outline,
              title: l10n.incidentLogLoadFailed,
              body: l10n.incidentLogLoadFailedBody,
            );
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return _EmptyLogState(
              icon: Icons.history,
              title: l10n.incidentLogEmptyTitle,
              body: l10n.incidentLogEmptyBody,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshLogs();
              try {
                await _logsFuture;
              } catch (_) {}
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = logs[index];
                final logId = log['log_id'] as int? ?? 0;
                final emergencyType = log['emergency_type'] as String? ?? '';
                final timestamp = log['timestamp'] as String? ?? '';
                final completedSteps = log['completed_steps'] as int? ?? 0;
                final totalSteps = log['total_steps'] as int? ?? 0;
                final isCompleted = (log['is_completed'] as int? ?? 0) == 1;
                final elapsedSeconds = log['elapsed_seconds'] as int? ?? 0;
                final stepDurations = _stepDurations(log);
                final displayElapsedSeconds = _displayElapsedSeconds(
                  elapsedSeconds,
                  stepDurations,
                );
                final title = _emergencyTitle(l10n, emergencyType);
                final emergencyColor = _emergencyColor(emergencyType);
                final status = isCompleted
                    ? l10n.incidentLogCompleted
                    : l10n.incidentLogProgress(completedSteps, totalSteps);
                final visibleStepDurations = _visibleStepDurations(
                  stepDurations,
                );
                final hasTimingDetails =
                    displayElapsedSeconds > 0 ||
                    visibleStepDurations.isNotEmpty;
                final isSelected = _selectedLogIds.contains(logId);

                return GestureDetector(
                  onTap: _selectionMode
                      ? () => _toggleSelectedLog(logId)
                      : null,
                  onLongPress: logId > 0
                      ? () {
                          if (_selectionMode) {
                            _toggleSelectedLog(logId);
                          } else {
                            _enterSelectionMode(logId);
                          }
                        }
                      : null,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary.withValues(alpha: 0.08)
                          : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.55)
                            : cs.outlineVariant.withValues(alpha: 0.14),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        leading: _selectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelectedLog(logId),
                                shape: const CircleBorder(),
                                side: BorderSide(color: cs.outline, width: 1.6),
                              )
                            : Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: emergencyColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                                child: ProtocolIcon(
                                  emergencyId: emergencyType,
                                  color: emergencyColor,
                                  size: 30,
                                ),
                              ),
                        title: Text(
                          l10n.incidentLogEntry(title),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (totalSteps > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                status,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isCompleted ? cs.tertiary : cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(context, timestamp),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          if (hasTimingDetails)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(
                                  alpha: 0.35,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (displayElapsedSeconds > 0) ...[
                                    _LogDetailRow(
                                      icon: Icons.timer_outlined,
                                      label: l10n.incidentLogTotalTime(
                                        formatLocalizedDuration(
                                          context,
                                          displayElapsedSeconds,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (visibleStepDurations.isNotEmpty) ...[
                                    if (displayElapsedSeconds > 0)
                                      const SizedBox(height: 10),
                                    _LogDetailRow(
                                      icon: Icons.format_list_numbered,
                                      label: l10n.incidentLogStepTimesTitle,
                                    ),
                                    const SizedBox(height: 8),
                                    ...visibleStepDurations.map(
                                      (entry) => Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                              start: 28,
                                              bottom: 6,
                                            ),
                                        child: _StepTimeRow(
                                          stepNumber: entry.key,
                                          duration: formatLocalizedDuration(
                                            context,
                                            entry.value,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                l10n.incidentLogNoTimingDetails,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          if (logId > 0 && !_selectionMode) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton.icon(
                                onPressed: () => _deleteLog(logId),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(l10n.incidentLogDeleteAction),
                                style: TextButton.styleFrom(
                                  foregroundColor: cs.error,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LogDetailRow extends StatelessWidget {
  const _LogDetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepTimeRow extends StatelessWidget {
  const _StepTimeRow({required this.stepNumber, required this.duration});

  final int stepNumber;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.incidentLogStepTimeLabel(stepNumber),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          duration,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyLogState extends StatelessWidget {
  const _EmptyLogState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
