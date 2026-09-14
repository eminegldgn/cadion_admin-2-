import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';
import '../widgets/dashboard_stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AdminApiService _apiService;

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  Map<String, dynamic> _dashboard = <String, dynamic>{};

  @override
  void initState() {
    super.initState();

    _apiService = AdminApiService(
      adminId: widget.adminId,
    );

    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    final Map<String, dynamic> result =
    await _apiService.getDashboard();

    if (!mounted) {
      return;
    }

    if (result['success'] != true) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage =
            result['error']?.toString() ??
                'Dashboard bilgileri alınamadı.';
      });

      return;
    }

    setState(() {
      _dashboard = result;
      _isLoading = false;
      _hasError = false;
    });
  }

  Map<String, dynamic> _mapValue(String key) {
    final dynamic value = _dashboard[key];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listValue(String key) {
    final dynamic value = _dashboard[key];

    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (Map item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  int _intValue(
      Map<String, dynamic> map,
      String key,
      ) {
    return int.tryParse(
      map[key]?.toString() ?? '',
    ) ??
        0;
  }

  String _formatMoney(dynamic value) {
    final double amount =
        double.tryParse(
          value?.toString() ?? '',
        ) ??
            0;

    return '${amount.toStringAsFixed(2)} TL';
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final DateTime? parsed =
    DateTime.tryParse(value.toString());

    if (parsed == null) {
      return value.toString();
    }

    final DateTime date = parsed.toLocal();

    final String day =
    date.day.toString().padLeft(2, '0');
    final String month =
    date.month.toString().padLeft(2, '0');
    final String hour =
    date.hour.toString().padLeft(2, '0');
    final String minute =
    date.minute.toString().padLeft(2, '0');

    return '$day.$month.${date.year} • $hour:$minute';
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

    final Map<String, dynamic> users =
    _mapValue('users');
    final Map<String, dynamic> courses =
    _mapValue('courses');
    final Map<String, dynamic> notes =
    _mapValue('notes');
    final Map<String, dynamic> purchases =
    _mapValue('purchases');
    final Map<String, dynamic> withdrawals =
    _mapValue('withdrawals');
    final Map<String, dynamic> wallets =
    _mapValue('wallets');
    final Map<String, dynamic> sales =
    _mapValue('sales');
    final Map<String, dynamic> notifications =
    _mapValue('notifications');

    final List<Map<String, dynamic>> topNotes =
    _listValue('top_notes');
    final List<Map<String, dynamic>> latestPurchases =
    _listValue('latest_purchases');
    final List<Map<String, dynamic>> latestAdminLogs =
    _listValue('latest_admin_logs');

    return RefreshIndicator(
      color: AdminColors.primaryLight,
      backgroundColor: AdminColors.surface,
      onRefresh: _loadDashboard,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32,
        ),
        children: [
          _buildWelcomeCard(),

          const SizedBox(height: 22),

          const Text(
            'Genel Bakış',
            style: TextStyle(
              color: AdminColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (
                BuildContext context,
                BoxConstraints constraints,
                ) {
              final bool wide =
                  constraints.maxWidth > 700;

              final double itemWidth =
              wide
                  ? (constraints.maxWidth - 28) / 3
                  : (constraints.maxWidth - 14) / 2;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _statBox(
                    width: itemWidth,
                    title: 'Toplam Kullanıcı',
                    value:
                    '${_intValue(users, 'total')}',
                    icon: Icons.people_rounded,
                    color: AdminColors.primary,
                    subtitle:
                    '${_intValue(users, 'new_today')} yeni bugün',
                  ),
                  _statBox(
                    width: itemWidth,
                    title: 'Toplam Ders',
                    value:
                    '${_intValue(courses, 'total')}',
                    icon: Icons.menu_book_rounded,
                    color: Colors.indigo,
                    subtitle: 'Sistemde kayıtlı',
                  ),
                  _statBox(
                    width: itemWidth,
                    title: 'Toplam Not',
                    value:
                    '${_intValue(notes, 'total')}',
                    icon:
                    Icons.description_rounded,
                    color:
                    AdminColors.primaryLight,
                    subtitle:
                    '${_intValue(notes, 'approved')} onaylı',
                  ),
                  _statBox(
                    width: itemWidth,
                    title: 'Bekleyen Not',
                    value:
                    '${_intValue(notes, 'pending')}',
                    icon:
                    Icons.pending_actions_rounded,
                    color: AdminColors.warning,
                    subtitle:
                    '${_intValue(notes, 'rejected')} reddedilmiş',
                  ),
                  _statBox(
                    width: itemWidth,
                    title: 'Satın Alma',
                    value:
                    '${_intValue(purchases, 'total')}',
                    icon:
                    Icons.shopping_cart_rounded,
                    color: AdminColors.success,
                    subtitle:
                    '${_intValue(purchases, 'today')} bugün',
                  ),
                  _statBox(
                    width: itemWidth,
                    title: 'Bugün Bildirim',
                    value:
                    '${_intValue(notifications, 'today')}',
                    icon:
                    Icons.notifications_active_rounded,
                    color: Colors.deepPurple,
                    subtitle: 'Gönderilen bildirim',
                  ),
                  _statBox(
                    width: itemWidth,
                    title: 'Bekleyen Çekim',
                    value:
                    '${_intValue(withdrawals, 'pending_count')}',
                    icon:
                    Icons.account_balance_wallet_rounded,
                    color: AdminColors.warning,
                    subtitle: _formatMoney(
                      withdrawals['pending_amount'],
                    ),
                  ),
                  _statBox(
                    width: itemWidth,
                    title: 'Toplam Bakiye',
                    value: _formatMoney(
                      wallets['total_balance'],
                    ),
                    icon: Icons.savings_rounded,
                    color:
                    AdminColors.primaryLight,
                    subtitle:
                    'Tüm kullanıcı cüzdanları',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 26),

          const Text(
            'Satış Özeti',
            style: TextStyle(
              color: AdminColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          _buildSalesCard(sales),

          const SizedBox(height: 26),

          _buildSectionHeader(
            title: 'En Çok İndirilen Notlar',
            count: topNotes.length,
          ),

          const SizedBox(height: 12),

          if (topNotes.isEmpty)
            _buildEmptyBox(
              icon: Icons.description_outlined,
              text:
              'Henüz öne çıkan not bulunmuyor.',
            )
          else
            ...topNotes.map(
              _buildTopNoteItem,
            ),

          const SizedBox(height: 26),

          _buildSectionHeader(
            title: 'Son Satın Almalar',
            count: latestPurchases.length,
          ),

          const SizedBox(height: 12),

          if (latestPurchases.isEmpty)
            _buildEmptyBox(
              icon:
              Icons.shopping_bag_outlined,
              text:
              'Henüz satın alma kaydı bulunmuyor.',
            )
          else
            ...latestPurchases.map(
              _buildPurchaseItem,
            ),

          const SizedBox(height: 26),

          _buildSectionHeader(
            title: 'Son Admin İşlemleri',
            count: latestAdminLogs.length,
          ),

          const SizedBox(height: 12),

          if (latestAdminLogs.isEmpty)
            _buildEmptyBox(
              icon: Icons.history_rounded,
              text:
              'Henüz admin işlem kaydı bulunmuyor.',
            )
          else
            ...latestAdminLogs.map(
              _buildAdminLogItem,
            ),
        ],
      ),
    );
  }

  Widget _statBox({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return SizedBox(
      width: width,
      child: DashboardStatCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
        subtitle: subtitle,
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A4F8D),
            Color(0xFF127EC2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
        BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons
                  .admin_panel_settings_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Yönetim Paneli',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Cadion sistemini buradan yönetebilirsiniz.',
                  style: TextStyle(
                    color:
                    Color(0xFFD2E8F6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadDashboard,
            tooltip: 'Yenile',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesCard(
      Map<String, dynamic> sales,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius:
        BorderRadius.circular(21),
        border: Border.all(
          color: AdminColors.border,
        ),
      ),
      child: Column(
        children: [
          _buildSalesRow(
            label: 'Toplam Satış',
            value:
            _formatMoney(sales['total']),
            icon:
            Icons.trending_up_rounded,
            color: AdminColors.success,
          ),
          const Divider(height: 26),
          _buildSalesRow(
            label: 'Bugünkü Satış',
            value:
            _formatMoney(sales['today']),
            icon: Icons.today_rounded,
            color:
            AdminColors.primaryLight,
          ),
          const Divider(height: 26),
          _buildSalesRow(
            label: 'Bu Ayki Satış',
            value: _formatMoney(
              sales['this_month'],
            ),
            icon:
            Icons.calendar_month_rounded,
            color: AdminColors.primary,
          ),
          const Divider(height: 26),
          _buildSalesRow(
            label: 'Tahmini Komisyon',
            value: _formatMoney(
              sales['estimated_commission'],
            ),
            icon: Icons.percent_rounded,
            color: AdminColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.12,
            ),
            borderRadius:
            BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color:
              AdminColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AdminColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color:
              AdminColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: AdminColors.primary
                .withValues(
              alpha: 0.12,
            ),
            borderRadius:
            BorderRadius.circular(20),
          ),
          child: Text(
            '$count kayıt',
            style: const TextStyle(
              color:
              AdminColors.primaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopNoteItem(
      Map<String, dynamic> note,
      ) {
    final String subtitle = <dynamic>[
      note['category_name'],
      note['university_name'],
    ]
        .where(
          (dynamic value) =>
      value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty,
    )
        .join(' • ');

    return _buildInfoCard(
      icon: Icons.description_rounded,
      iconColor:
      AdminColors.primaryLight,
      title:
      note['title']?.toString() ??
          'İsimsiz not',
      subtitle: subtitle.isEmpty
          ? 'Bilgi bulunamadı'
          : subtitle,
      trailing:
      '${_formatMoney(note['price'])}\n${note['download_count'] ?? 0} indirme',
    );
  }

  Widget _buildPurchaseItem(
      Map<String, dynamic> purchase,
      ) {
    return _buildInfoCard(
      icon:
      Icons.shopping_bag_rounded,
      iconColor: AdminColors.success,
      title: purchase['note_title']
          ?.toString() ??
          'Satın alınan not',
      subtitle:
      '${purchase['user_id'] ?? '-'}\n${_formatDate(purchase['created_at'])}',
      trailing:
      _formatMoney(purchase['price']),
    );
  }

  Widget _buildAdminLogItem(
      Map<String, dynamic> log,
      ) {
    final String description =
        log['description']
            ?.toString()
            .trim() ??
            '';

    return _buildInfoCard(
      icon:
      Icons.manage_history_rounded,
      iconColor: Colors.deepPurple,
      title:
      log['action']?.toString() ??
          'İşlem',
      subtitle: description.isEmpty
          ? '${log['admin_id'] ?? '-'} • ${_formatDate(log['created_at'])}'
          : '$description\n${log['admin_id'] ?? '-'} • ${_formatDate(log['created_at'])}',
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors
                        .textPrimary,
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AdminColors
                        .textSecondary,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(
              trailing,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AdminColors.success,
                fontSize: 10,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyBox({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 34,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: AdminColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AdminColors.textMuted,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
              AdminColors.textSecondary,
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
      backgroundColor:
      AdminColors.surface,
      onRefresh: _loadDashboard,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 150),
          const Icon(
            Icons.cloud_off_rounded,
            color: AdminColors.error,
            size: 60,
          ),
          const SizedBox(height: 18),
          const Text(
            'Dashboard yüklenemedi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
              AdminColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ??
                'Node.js sunucusunun çalıştığından ve API adresinin doğru olduğundan emin olun.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:
              AdminColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _loadDashboard,
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
