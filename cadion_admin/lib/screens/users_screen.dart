import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late final AdminApiService _apiService;

  final TextEditingController _searchController =
  TextEditingController();

  bool _isLoading = true;
  bool _hasError = false;

  List<Map<String, dynamic>> _users =
  <Map<String, dynamic>>[];

  final Set<String> _processingUserIds = <String>{};

  @override
  void initState() {
    super.initState();

    _apiService = AdminApiService(
      adminId: widget.adminId,
    );

    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final Map<String, dynamic> result =
    await _apiService.getUsers(
      page: 1,
      limit: 100,
    );

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
            'Kullanıcılar alınamadı.',
        success: false,
      );

      return;
    }

    final dynamic rawUsers = result['users'];

    final List<Map<String, dynamic>> users =
    rawUsers is List
        ? rawUsers
        .whereType<Map>()
        .map(
          (Map item) =>
      Map<String, dynamic>.from(item),
    )
        .toList()
        : <Map<String, dynamic>>[];

    setState(() {
      _users = users;
      _isLoading = false;
      _hasError = false;
    });
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final String search =
    _searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return _users;
    }

    return _users.where(
          (Map<String, dynamic> user) {
        final String id =
            user['id']?.toString().toLowerCase() ?? '';

        final String role =
            user['role']?.toString().toLowerCase() ?? '';

        return id.contains(search) ||
            role.contains(search);
      },
    ).toList();
  }

  bool _isBanned(Map<String, dynamic> user) {
    return int.tryParse(
      user['is_banned']?.toString() ?? '',
    ) ==
        1;
  }

  String _formatMoney(dynamic value) {
    final double amount =
        double.tryParse(
          value?.toString() ?? '',
        ) ??
            0;

    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} TL';
  }

  Future<void> _toggleBan(
      Map<String, dynamic> user,
      ) async {
    final String userId =
        user['id']?.toString().trim() ?? '';

    if (userId.isEmpty) {
      return;
    }

    final bool currentlyBanned =
    _isBanned(user);

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AdminColors.surface,
          title: Text(
            currentlyBanned
                ? 'Engel kaldırılsın mı?'
                : 'Kullanıcı engellensin mi?',
          ),
          content: Text(
            currentlyBanned
                ? '$userId kullanıcısının engeli kaldırılacak.'
                : '$userId kullanıcısı uygulamaya erişemeyecek.',
            style: const TextStyle(
              color: AdminColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: currentlyBanned
                    ? AdminColors.success
                    : AdminColors.error,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                currentlyBanned
                    ? 'Engeli Kaldır'
                    : 'Engelle',
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
      _processingUserIds.add(userId);
    });

    final Map<String, dynamic> result =
    currentlyBanned
        ? await _apiService.unbanUser(userId)
        : await _apiService.banUser(userId);

    if (!mounted) {
      return;
    }

    setState(() {
      _processingUserIds.remove(userId);
    });

    if (result['success'] == true) {
      setState(() {
        user['is_banned'] = currentlyBanned ? 0 : 1;
      });

      _showMessage(
        result['message']?.toString() ??
            'Kullanıcı durumu güncellendi.',
        success: true,
      );

      return;
    }

    _showMessage(
      result['error']?.toString() ??
          'Kullanıcı durumu güncellenemedi.',
      success: false,
    );
  }

  void _showMessage(
      String message, {
        required bool success,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
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
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return _buildErrorView();
    }

    final List<Map<String, dynamic>> users =
        _filteredUsers;

    return RefreshIndicator(
      color: AdminColors.primaryLight,
      backgroundColor: AdminColors.surface,
      onRefresh: _loadUsers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32,
        ),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: const InputDecoration(
              hintText: 'Kullanıcı veya rol ara...',
              prefixIcon: Icon(
                Icons.search_rounded,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kullanıcılar',
                  style: TextStyle(
                    color: AdminColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${users.length} kayıt',
                style: const TextStyle(
                  color: AdminColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (users.isEmpty)
            _buildEmptyView()
          else
            ...users.map(_buildUserCard),
        ],
      ),
    );
  }

  Widget _buildUserCard(
      Map<String, dynamic> user,
      ) {
    final String userId =
        user['id']?.toString() ?? '-';

    final String role =
        user['role']?.toString() ?? 'user';

    final bool banned = _isBanned(user);

    final bool processing =
    _processingUserIds.contains(userId);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: banned
              ? AdminColors.error.withValues(alpha: 0.45)
              : AdminColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: banned
                      ? AdminColors.error.withValues(
                    alpha: 0.12,
                  )
                      : AdminColors.primary.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  banned
                      ? Icons.block_rounded
                      : Icons.person_rounded,
                  color: banned
                      ? AdminColors.error
                      : AdminColors.primaryLight,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      userId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      role,
                      style: TextStyle(
                        color: role == 'admin'
                            ? AdminColors.warning
                            : AdminColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: banned
                      ? AdminColors.error.withValues(
                    alpha: 0.12,
                  )
                      : AdminColors.success.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  banned ? 'Engelli' : 'Aktif',
                  style: TextStyle(
                    color: banned
                        ? AdminColors.error
                        : AdminColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Bakiye',
                  _formatMoney(user['balance']),
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Yüklenen Not',
                  '${user['uploaded_note_count'] ?? 0}',
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Satın Alma',
                  '${user['purchase_count'] ?? 0}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: banned
                    ? AdminColors.success
                    : AdminColors.error,
                side: BorderSide(
                  color: banned
                      ? AdminColors.success
                      : AdminColors.error,
                ),
              ),
              onPressed: processing
                  ? null
                  : () {
                _toggleBan(user);
              },
              icon: processing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : Icon(
                banned
                    ? Icons.lock_open_rounded
                    : Icons.block_rounded,
              ),
              label: Text(
                processing
                    ? 'İşleniyor...'
                    : banned
                    ? 'Engeli Kaldır'
                    : 'Kullanıcıyı Engelle',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
      String title,
      String value,
      ) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AdminColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AdminColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 36,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AdminColors.border,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.person_search_rounded,
            color: AdminColors.textMuted,
            size: 48,
          ),
          SizedBox(height: 14),
          Text(
            'Kullanıcı bulunamadı.',
            style: TextStyle(
              color: AdminColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return RefreshIndicator(
      color: AdminColors.primaryLight,
      backgroundColor: AdminColors.surface,
      onRefresh: _loadUsers,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 150),
          const Icon(
            Icons.cloud_off_rounded,
            color: AdminColors.error,
            size: 60,
          ),
          const SizedBox(height: 18),
          const Text(
            'Kullanıcılar yüklenemedi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AdminColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadUsers,
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
}