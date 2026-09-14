import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<AdminLogsScreen> createState() =>
      _AdminLogsScreenState();
}

class _AdminLogsScreenState
    extends State<AdminLogsScreen> {
  final AdminApiService _apiService =
  AdminApiService();

  final TextEditingController
  _searchController =
  TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _logs =
  <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _refreshSearch,
    );

    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _refreshSearch,
    );

    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadLogs() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final Map<String, dynamic> result =
    await _apiService.getAdminLogs();

    if (!mounted) {
      return;
    }

    if (result['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            result['error']?.toString() ??
                'Admin logları getirilemedi.';
      });

      return;
    }

    final List<Map<String, dynamic>>
    parsedLogs =
    <Map<String, dynamic>>[];

    final dynamic logsValue =
    result['logs'];

    if (logsValue is List) {
      for (final dynamic item in logsValue) {
        if (item is Map) {
          parsedLogs.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }
    }

    setState(() {
      _isLoading = false;
      _logs = parsedLogs;
    });
  }

  void _refreshSearch() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  List<Map<String, dynamic>>
  get _filteredLogs {
    final String search =
    _searchController.text
        .trim()
        .toLowerCase();

    if (search.isEmpty) {
      return _logs;
    }

    return _logs.where(
          (
          Map<String, dynamic> log,
          ) {
        final String adminId =
            log['admin_id']
                ?.toString()
                .toLowerCase() ??
                '';

        final String action =
            log['action']
                ?.toString()
                .toLowerCase() ??
                '';

        final String description =
            log['description']
                ?.toString()
                .toLowerCase() ??
                '';

        return adminId.contains(search) ||
            action.contains(search) ||
            description.contains(search);
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadLogs,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(18),
        children: [
          _buildHeader(),

          const SizedBox(height: 16),

          _buildSearch(),

          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(70),
              child: Center(
                child:
                CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            _buildError()
          else if (_filteredLogs.isEmpty)
              _buildEmpty()
            else
              ..._filteredLogs.map(
                _buildLogCard,
              ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: AdminColors.surface,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: AdminColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
            BoxDecoration(
              color: AdminColors.primary
                  .withValues(
                alpha: 0.13,
              ),
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AdminColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  '${_logs.length} işlem kaydı',
                  style:
                  const TextStyle(
                    color: AdminColors
                        .textPrimary,
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                const Text(
                  'Admin işlem geçmişi',
                  style:
                  TextStyle(
                    color: AdminColors
                        .textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: _loadLogs,
            tooltip: 'Yenile',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller:
      _searchController,
      decoration:
      InputDecoration(
        hintText:
        'Admin, işlem veya açıklama ara...',
        prefixIcon:
        const Icon(
          Icons.search_rounded,
        ),
        suffixIcon:
        _searchController.text.isEmpty
            ? null
            : IconButton(
          onPressed: () {
            _searchController
                .clear();
          },
          icon: const Icon(
            Icons.clear_rounded,
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(
      Map<String, dynamic> log,
      ) {
    final String adminId =
        log['admin_id']?.toString() ??
            '-';

    final String action =
        log['action']?.toString() ??
            'İşlem';

    final String description =
        log['description']
            ?.toString()
            .trim() ??
            '';

    final String createdAt =
        log['created_at']?.toString() ??
            '-';

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
      const EdgeInsets.all(15),
      decoration:
      BoxDecoration(
        color: AdminColors.surface,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color: AdminColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
              color: AdminColors.primary
                  .withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons.manage_history_rounded,
              color: AdminColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style:
                  const TextStyle(
                    color: AdminColors
                        .textPrimary,
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                if (description.isNotEmpty)
                  Padding(
                    padding:
                    const EdgeInsets.only(
                      top: 5,
                    ),
                    child: Text(
                      description,
                      style:
                      const TextStyle(
                        color: AdminColors
                            .textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 10,
                  runSpacing: 5,
                  children: [
                    _smallInfo(
                      Icons
                          .admin_panel_settings_rounded,
                      adminId,
                    ),
                    _smallInfo(
                      Icons.schedule_rounded,
                      createdAt,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(
      IconData icon,
      String text,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color:
          AdminColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style:
          const TextStyle(
            color:
            AdminColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding:
      const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons
                .error_outline_rounded,
            color:
            AdminColors.error,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ??
                'Bir hata oluştu.',
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color: AdminColors
                  .textSecondary,
            ),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: _loadLogs,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Tekrar Dene',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding:
      EdgeInsets.all(55),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            color:
            AdminColors.textMuted,
            size: 52,
          ),
          SizedBox(height: 12),
          Text(
            'Henüz admin işlem kaydı bulunmuyor.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color: AdminColors
                  .textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}