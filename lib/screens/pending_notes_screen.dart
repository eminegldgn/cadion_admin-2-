import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class PendingNotesScreen extends StatefulWidget {
  const PendingNotesScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<PendingNotesScreen> createState() =>
      _PendingNotesScreenState();
}

class _PendingNotesScreenState
    extends State<PendingNotesScreen> {
  late final AdminApiService _apiService;

  bool _isLoading = true;
  bool _hasError = false;

  List<Map<String, dynamic>> _notes =
  <Map<String, dynamic>>[];

  final Set<int> _processingNoteIds =
  <int>{};

  @override
  void initState() {
    super.initState();

    _apiService = AdminApiService(
      adminId: widget.adminId,
    );

    _loadPendingNotes();
  }

  Future<void> _loadPendingNotes() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final Map<String, dynamic> result =
    await _apiService.getPendingNotes();

    if (!mounted) {
      return;
    }

    if (result['success'] != true) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      _showMessage(
        result['error']?.toString() ??
            'Bekleyen notlar alınamadı.',
        success: false,
      );

      return;
    }

    final dynamic rawNotes =
    result['notes'];

    final List<Map<String, dynamic>> notes =
    rawNotes is List
        ? rawNotes
        .whereType<Map>()
        .map(
          (Map item) =>
      Map<String, dynamic>.from(
        item,
      ),
    )
        .toList()
        : <Map<String, dynamic>>[];

    setState(() {
      _notes = notes;
      _isLoading = false;
      _hasError = false;
    });
  }

  int _noteId(
      Map<String, dynamic> note,
      ) {
    return int.tryParse(
      note['id']?.toString() ?? '',
    ) ??
        0;
  }

  String _text(
      Map<String, dynamic> note,
      String key, {
        String fallback = '-',
      }) {
    final String value =
        note[key]?.toString().trim() ?? '';

    return value.isEmpty
        ? fallback
        : value;
  }

  String _formatMoney(dynamic value) {
    final double amount =
        double.tryParse(
          value?.toString() ?? '',
        ) ??
            0;

    final String fixed =
    amount.toStringAsFixed(2);

    final List<String> parts =
    fixed.split('.');

    final String integerPart =
        parts.first;

    final String decimalPart =
        parts.last;

    final StringBuffer result =
    StringBuffer();

    for (
    int index = 0;
    index < integerPart.length;
    index++
    ) {
      final int remaining =
          integerPart.length - index;

      result.write(
        integerPart[index],
      );

      if (
      remaining > 1 &&
          remaining % 3 == 1
      ) {
        result.write('.');
      }
    }

    return '${result.toString()},$decimalPart TL';
  }

  String _formatDate(dynamic value) {
    final DateTime? parsed =
    DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (parsed == null) {
      return '-';
    }

    final DateTime date =
    parsed.toLocal();

    final String day =
    date.day
        .toString()
        .padLeft(2, '0');

    final String month =
    date.month
        .toString()
        .padLeft(2, '0');

    final String hour =
    date.hour
        .toString()
        .padLeft(2, '0');

    final String minute =
    date.minute
        .toString()
        .padLeft(2, '0');

    return '$day.$month.${date.year} • $hour:$minute';
  }

  Future<void> _openPdf(
      Map<String, dynamic> note,
      ) async {
    final String filePath =
    _text(
      note,
      'file_path',
      fallback: '',
    );

    if (filePath.isEmpty) {
      _showMessage(
        'Bu nota ait PDF dosyası bulunamadı.',
        success: false,
      );
      return;
    }

    final Uri uri = Uri.parse(
      '${AdminApiService.baseUrl}/uploads/$filePath',
    );

    final bool opened =
    await launchUrl(
      uri,
      mode:
      LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showMessage(
        'PDF dosyası açılamadı.',
        success: false,
      );
    }
  }

  Future<void> _approveNote(
      Map<String, dynamic> note,
      ) async {
    final int noteId =
    _noteId(note);

    if (noteId <= 0) {
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          AdminColors.surface,
          title: const Text(
            'Not onaylansın mı?',
          ),
          content: Text(
            '"${_text(note, 'title')}" yayına alınacak.',
            style: const TextStyle(
              color:
              AdminColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Vazgeç',
              ),
            ),
            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                AdminColors.success,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Onayla',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _processingNoteIds.add(
        noteId,
      );
    });

    final Map<String, dynamic> result =
    await _apiService.approveNote(
      noteId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _processingNoteIds.remove(
        noteId,
      );
    });

    if (result['success'] == true) {
      setState(() {
        _notes.removeWhere(
              (
              Map<String, dynamic> item,
              ) =>
          _noteId(item) == noteId,
        );
      });

      _showMessage(
        result['message']?.toString() ??
            'Not onaylandı.',
        success: true,
      );

      return;
    }

    _showMessage(
      result['error']?.toString() ??
          'Not onaylanamadı.',
      success: false,
    );
  }

  Future<void> _rejectNote(
      Map<String, dynamic> note,
      ) async {
    final int noteId =
    _noteId(note);

    if (noteId <= 0) {
      return;
    }

    final TextEditingController reasonController =
    TextEditingController();

    final String? reason =
    await showDialog<String>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          AdminColors.surface,
          title: const Text(
            'Notu Reddet',
          ),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                '"${_text(note, 'title')}" reddedilecek.',
                style: const TextStyle(
                  color:
                  AdminColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller:
                reasonController,
                maxLines: 4,
                decoration:
                const InputDecoration(
                  labelText:
                  'Red nedeni',
                  hintText:
                  'Eksik, uygunsuz veya hatalı içerik...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Vazgeç',
              ),
            ),
            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                AdminColors.error,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  reasonController.text
                      .trim(),
                );
              },
              child: const Text(
                'Reddet',
              ),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null) {
      return;
    }

    setState(() {
      _processingNoteIds.add(
        noteId,
      );
    });

    final Map<String, dynamic> result =
    await _apiService.rejectNote(
      noteId,
      reason: reason,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _processingNoteIds.remove(
        noteId,
      );
    });

    if (result['success'] == true) {
      setState(() {
        _notes.removeWhere(
              (
              Map<String, dynamic> item,
              ) =>
          _noteId(item) == noteId,
        );
      });

      _showMessage(
        result['message']?.toString() ??
            'Not reddedildi.',
        success: true,
      );

      return;
    }

    _showMessage(
      result['error']?.toString() ??
          'Not reddedilemedi.',
      success: false,
    );
  }

  void _showMessage(
      String message, {
        required bool success,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success
                  ? Icons
                  .check_circle_rounded
                  : Icons
                  .error_outline_rounded,
              color: success
                  ? AdminColors.success
                  : AdminColors.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      color:
      AdminColors.primaryLight,
      backgroundColor:
      AdminColors.surface,
      onRefresh:
      _loadPendingNotes,
      child: _notes.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32,
        ),
        itemCount:
        _notes.length,
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          return _buildNoteCard(
            _notes[index],
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(
      Map<String, dynamic> note,
      ) {
    final int noteId =
    _noteId(note);

    final bool processing =
    _processingNoteIds.contains(
      noteId,
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color:
        AdminColors.surface,
        borderRadius:
        BorderRadius.circular(21),
        border: Border.all(
          color:
          AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                BoxDecoration(
                  color: AdminColors
                      .warning
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),
                child: const Icon(
                  Icons
                      .pending_actions_rounded,
                  color:
                  AdminColors.warning,
                  size: 25,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      _text(
                        note,
                        'title',
                        fallback:
                        'Başlıksız not',
                      ),
                      style:
                      const TextStyle(
                        color: AdminColors
                            .textPrimary,
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      _text(
                        note,
                        'user_id',
                      ),
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color: AdminColors
                            .textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color: AdminColors
                      .success
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Text(
                  _formatMoney(
                    note['price'],
                  ),
                  style:
                  const TextStyle(
                    color: AdminColors
                        .success,
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            _text(
              note,
              'description',
              fallback:
              'Açıklama bulunmuyor.',
            ),
            maxLines: 4,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors
                  .textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 15),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons
                    .category_outlined,
                _text(
                  note,
                  'category_name',
                ),
              ),
              _buildInfoChip(
                Icons
                    .school_outlined,
                _text(
                  note,
                  'university_name',
                ),
              ),
              _buildInfoChip(
                Icons
                    .menu_book_outlined,
                _text(
                  note,
                  'course_name',
                ),
              ),
              _buildInfoChip(
                Icons
                    .workspace_premium_outlined,
                _text(
                  note,
                  'education_type',
                ),
              ),
              _buildInfoChip(
                Icons
                    .format_list_numbered_rounded,
                _text(
                  note,
                  'grade_level',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons
                    .schedule_rounded,
                color:
                AdminColors.textMuted,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(
                  note['created_at'],
                ),
                style:
                const TextStyle(
                  color:
                  AdminColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child:
                OutlinedButton.icon(
                  onPressed: processing
                      ? null
                      : () {
                    _openPdf(
                      note,
                    );
                  },
                  icon: const Icon(
                    Icons
                        .picture_as_pdf_rounded,
                  ),
                  label: const Text(
                    'PDF',
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child:
                OutlinedButton.icon(
                  style:
                  OutlinedButton
                      .styleFrom(
                    foregroundColor:
                    AdminColors.error,
                    side:
                    const BorderSide(
                      color:
                      AdminColors.error,
                    ),
                  ),
                  onPressed: processing
                      ? null
                      : () {
                    _rejectNote(
                      note,
                    );
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                  label: const Text(
                    'Reddet',
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child:
                FilledButton.icon(
                  style:
                  FilledButton
                      .styleFrom(
                    backgroundColor:
                    AdminColors.success,
                  ),
                  onPressed: processing
                      ? null
                      : () {
                    _approveNote(
                      note,
                    );
                  },
                  icon: processing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons
                        .check_rounded,
                  ),
                  label: Text(
                    processing
                        ? 'İşleniyor'
                        : 'Onayla',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon,
      String text,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AdminColors
            .surfaceSecondary,
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AdminColors
                .primaryLight,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AdminColors
                  .textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 150),
        const Icon(
          Icons
              .task_alt_rounded,
          color:
          AdminColors.success,
          size: 64,
        ),
        const SizedBox(height: 18),
        const Text(
          'Bekleyen not bulunmuyor',
          textAlign:
          TextAlign.center,
          style: TextStyle(
            color:
            AdminColors.textPrimary,
            fontSize: 19,
            fontWeight:
            FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Yeni yüklenen notlar burada görünecek.',
          textAlign:
          TextAlign.center,
          style: TextStyle(
            color:
            AdminColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return RefreshIndicator(
      color:
      AdminColors.primaryLight,
      backgroundColor:
      AdminColors.surface,
      onRefresh:
      _loadPendingNotes,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 150),
          const Icon(
            Icons
                .cloud_off_rounded,
            color:
            AdminColors.error,
            size: 60,
          ),
          const SizedBox(height: 18),
          const Text(
            'Notlar yüklenemedi',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              AdminColors.textPrimary,
              fontSize: 19,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed:
            _loadPendingNotes,
            icon: const Icon(
              Icons
                  .refresh_rounded,
            ),
            label: const Text(
              'Tekrar Dene',
            ),
          ),
        ],
      ),
    );
  }
}