import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class WithdrawalsScreen extends StatefulWidget {
  const WithdrawalsScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<WithdrawalsScreen> createState() =>
      _WithdrawalsScreenState();
}

class _WithdrawalsScreenState
    extends State<WithdrawalsScreen> {
  late final AdminApiService _apiService;

  bool _isLoading = true;
  bool _hasError = false;

  String _selectedStatus = 'pending';

  List<Map<String, dynamic>> _withdrawals =
  <Map<String, dynamic>>[];

  final Set<int> _processingRequestIds =
  <int>{};

  @override
  void initState() {
    super.initState();

    _apiService = AdminApiService(
      adminId: widget.adminId,
    );

    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final Map<String, dynamic> result =
    await _apiService.getWithdrawals(
      status: _selectedStatus,
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
            'Para çekme talepleri alınamadı.',
        success: false,
      );

      return;
    }

    final dynamic rawWithdrawals =
    result['withdrawals'];

    final List<Map<String, dynamic>> withdrawals =
    rawWithdrawals is List
        ? rawWithdrawals
        .whereType<Map>()
        .map(
          (Map item) =>
      Map<String, dynamic>.from(item),
    )
        .toList()
        : <Map<String, dynamic>>[];

    setState(() {
      _withdrawals = withdrawals;
      _isLoading = false;
      _hasError = false;
    });
  }

  int _requestId(
      Map<String, dynamic> withdrawal,
      ) {
    return int.tryParse(
      withdrawal['id']?.toString() ?? '',
    ) ??
        0;
  }

  String _text(
      Map<String, dynamic> withdrawal,
      String key, {
        String fallback = '-',
      }) {
    final String value =
        withdrawal[key]?.toString().trim() ?? '';

    return value.isEmpty ? fallback : value;
  }

  String _formatMoney(dynamic value) {
    final double amount =
        double.tryParse(
          value?.toString() ?? '',
        ) ??
            0;

    final String fixed =
    amount.abs().toStringAsFixed(2);

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

    final String sign =
    amount < 0 ? '-' : '';

    return '$sign${result.toString()},$decimalPart TL';
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

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AdminColors.success;

      case 'rejected':
        return AdminColors.error;

      default:
        return AdminColors.warning;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Onaylandı';

      case 'rejected':
        return 'Reddedildi';

      default:
        return 'Bekliyor';
    }
  }

  Future<void> _approveWithdrawal(
      Map<String, dynamic> withdrawal,
      ) async {
    final int requestId =
    _requestId(withdrawal);

    if (requestId <= 0) {
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
            'Talep onaylansın mı?',
          ),
          content: Text(
            '${_formatMoney(withdrawal['amount'])} tutarındaki para çekme talebi onaylanacak.',
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
      _processingRequestIds.add(
        requestId,
      );
    });

    final Map<String, dynamic> result =
    await _apiService
        .approveWithdrawal(
      requestId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _processingRequestIds.remove(
        requestId,
      );
    });

    if (result['success'] == true) {
      _showMessage(
        result['message']?.toString() ??
            'Para çekme talebi onaylandı.',
        success: true,
      );

      await _loadWithdrawals();
      return;
    }

    _showMessage(
      result['error']?.toString() ??
          'Para çekme talebi onaylanamadı.',
      success: false,
    );
  }

  Future<void> _rejectWithdrawal(
      Map<String, dynamic> withdrawal,
      ) async {
    final int requestId =
    _requestId(withdrawal);

    if (requestId <= 0) {
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
            'Talebi Reddet',
          ),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatMoney(withdrawal['amount'])} tutarındaki talep reddedilecek ve bakiye kullanıcıya iade edilecek.',
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
                  'Eksik IBAN, şüpheli işlem...',
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
      _processingRequestIds.add(
        requestId,
      );
    });

    final Map<String, dynamic> result =
    await _apiService
        .rejectWithdrawal(
      requestId,
      reason: reason,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _processingRequestIds.remove(
        requestId,
      );
    });

    if (result['success'] == true) {
      _showMessage(
        result['message']?.toString() ??
            'Para çekme talebi reddedildi.',
        success: true,
      );

      await _loadWithdrawals();
      return;
    }

    _showMessage(
      result['error']?.toString() ??
          'Para çekme talebi reddedilemedi.',
      success: false,
    );
  }

  void _changeStatus(
      String status,
      ) {
    if (_selectedStatus == status) {
      return;
    }

    setState(() {
      _selectedStatus = status;
    });

    _loadWithdrawals();
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
    return Column(
      children: [
        Padding(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            10,
          ),
          child: _buildStatusFilters(),
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
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
      _loadWithdrawals,
      child: _withdrawals.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          32,
        ),
        itemCount:
        _withdrawals.length,
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          return _buildWithdrawalCard(
            _withdrawals[index],
          );
        },
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection:
        Axis.horizontal,
        children: [
          _buildFilterChip(
            label: 'Bekleyen',
            value: 'pending',
            icon:
            Icons.pending_actions_rounded,
          ),
          const SizedBox(width: 9),
          _buildFilterChip(
            label: 'Onaylanan',
            value: 'approved',
            icon:
            Icons.check_circle_outline_rounded,
          ),
          const SizedBox(width: 9),
          _buildFilterChip(
            label: 'Reddedilen',
            value: 'rejected',
            icon:
            Icons.cancel_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final bool selected =
        _selectedStatus == value;

    return InkWell(
      onTap: () {
        _changeStatus(value);
      },
      borderRadius:
      BorderRadius.circular(14),
      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 180,
        ),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AdminColors.primary
              : AdminColors.surface,
          borderRadius:
          BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AdminColors.primary
                : AdminColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? Colors.white
                  : AdminColors
                  .textSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : AdminColors
                    .textSecondary,
                fontSize: 11,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalCard(
      Map<String, dynamic> withdrawal,
      ) {
    final int requestId =
    _requestId(withdrawal);

    final String status =
    _text(
      withdrawal,
      'status',
      fallback: 'pending',
    );

    final Color statusColor =
    _statusColor(status);

    final bool processing =
    _processingRequestIds.contains(
      requestId,
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 13,
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                BoxDecoration(
                  color: statusColor
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  Icons
                      .account_balance_wallet_rounded,
                  color: statusColor,
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      _formatMoney(
                        withdrawal[
                        'amount'],
                      ),
                      style:
                      const TextStyle(
                        color: AdminColors
                            .textPrimary,
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      _text(
                        withdrawal,
                        'user_id',
                      ),
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color: AdminColors
                            .textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
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
                  color: statusColor
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Text(
                  _statusText(
                    status,
                  ),
                  style:
                  TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          _buildInfoRow(
            icon:
            Icons.account_balance_rounded,
            title: 'IBAN',
            value: _text(
              withdrawal,
              'iban',
            ),
          ),

          const SizedBox(height: 11),

          _buildInfoRow(
            icon:
            Icons.savings_outlined,
            title:
            'Mevcut Cüzdan',
            value: _formatMoney(
              withdrawal[
              'current_wallet_balance'],
            ),
          ),

          const SizedBox(height: 11),

          _buildInfoRow(
            icon:
            Icons.schedule_rounded,
            title: 'Tarih',
            value: _formatDate(
              withdrawal[
              'created_at'],
            ),
          ),

          if (
          status == 'pending'
          ) ...[
            const SizedBox(
              height: 18,
            ),

            Row(
              children: [
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
                      _rejectWithdrawal(
                        withdrawal,
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

                const SizedBox(width: 10),

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
                      _approveWithdrawal(
                        withdrawal,
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
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color:
          AdminColors.primaryLight,
          size: 18,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: const TextStyle(
              color:
              AdminColors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              color:
              AdminColors.textSecondary,
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 145),
        Icon(
          _selectedStatus ==
              'pending'
              ? Icons
              .task_alt_rounded
              : Icons
              .receipt_long_outlined,
          color: _selectedStatus ==
              'pending'
              ? AdminColors.success
              : AdminColors.textMuted,
          size: 64,
        ),
        const SizedBox(height: 18),
        Text(
          _selectedStatus ==
              'pending'
              ? 'Bekleyen talep bulunmuyor'
              : 'Bu durumda talep bulunmuyor',
          textAlign:
          TextAlign.center,
          style: const TextStyle(
            color:
            AdminColors.textPrimary,
            fontSize: 19,
            fontWeight:
            FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Para çekme talepleri burada görüntülenecek.',
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
      _loadWithdrawals,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 145),
          const Icon(
            Icons
                .cloud_off_rounded,
            color:
            AdminColors.error,
            size: 60,
          ),
          const SizedBox(height: 18),
          const Text(
            'Talepler yüklenemedi',
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
            _loadWithdrawals,
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