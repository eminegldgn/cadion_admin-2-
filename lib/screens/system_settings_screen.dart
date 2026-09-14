import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class SystemSettingsScreen
    extends StatefulWidget {
  const SystemSettingsScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<SystemSettingsScreen> createState() =>
      _SystemSettingsScreenState();
}

class _SystemSettingsScreenState
    extends State<SystemSettingsScreen> {
  late final AdminApiService _apiService;

  final TextEditingController
  _commissionController =
  TextEditingController();

  final TextEditingController
  _minPriceController =
  TextEditingController();

  final TextEditingController
  _maxPriceController =
  TextEditingController();

  final TextEditingController
  _maxPdfSizeController =
  TextEditingController();

  bool _registrationEnabled = true;
  bool _noteApprovalRequired = true;
  bool _notificationsEnabled = true;
  bool _maintenanceMode = false;

  bool _isLoading = true;
  bool _isSaving = false;

  String? _errorMessage;
  String? _updatedAt;

  @override
  void initState() {
    super.initState();

    _apiService = AdminApiService(
      adminId: widget.adminId,
    );

    _loadSettings();
  }

  @override
  void dispose() {
    _commissionController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _maxPdfSizeController.dispose();

    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final Map<String, dynamic> result =
    await _apiService
        .getSystemSettings();

    if (!mounted) {
      return;
    }

    if (result['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            result['error']?.toString() ??
                'Sistem ayarları alınamadı.';
      });

      return;
    }

    final dynamic settingsValue =
    result['settings'];

    if (settingsValue is! Map) {
      setState(() {
        _isLoading = false;
        _errorMessage =
        'Sistem ayarları geçersiz döndü.';
      });

      return;
    }

    final Map<String, dynamic> settings =
    Map<String, dynamic>.from(
      settingsValue,
    );

    _commissionController.text =
        _numberText(
          settings['commission_rate'],
        );

    _minPriceController.text =
        _numberText(
          settings['min_note_price'],
        );

    _maxPriceController.text =
        _numberText(
          settings['max_note_price'],
        );

    _maxPdfSizeController.text =
        settings['max_pdf_size_mb']
            ?.toString() ??
            '50';

    setState(() {
      _registrationEnabled =
          _boolValue(
            settings['registration_enabled'],
          );

      _noteApprovalRequired =
          _boolValue(
            settings[
            'note_approval_required'],
          );

      _notificationsEnabled =
          _boolValue(
            settings[
            'notifications_enabled'],
          );

      _maintenanceMode =
          _boolValue(
            settings['maintenance_mode'],
          );

      _updatedAt =
          settings['updated_at']?.toString();

      _isLoading = false;
    });
  }

  bool _boolValue(dynamic value) {
    return value == true ||
        value == 1 ||
        value?.toString() == '1';
  }

  String _numberText(dynamic value) {
    final double number =
        double.tryParse(
          value?.toString() ?? '',
        ) ??
            0;

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(2);
  }

  double? _parseDouble(
      TextEditingController controller,
      ) {
    return double.tryParse(
      controller.text
          .trim()
          .replaceAll(',', '.'),
    );
  }

  int? _parseInteger(
      TextEditingController controller,
      ) {
    return int.tryParse(
      controller.text.trim(),
    );
  }

  Future<void> _saveSettings() async {
    if (_isSaving) {
      return;
    }

    final double? commissionRate =
    _parseDouble(
      _commissionController,
    );

    final double? minNotePrice =
    _parseDouble(
      _minPriceController,
    );

    final double? maxNotePrice =
    _parseDouble(
      _maxPriceController,
    );

    final int? maxPdfSizeMb =
    _parseInteger(
      _maxPdfSizeController,
    );

    if (
    commissionRate == null ||
        commissionRate < 0 ||
        commissionRate > 100
    ) {
      _showMessage(
        'Komisyon oranı 0 ile 100 arasında olmalıdır.',
        success: false,
      );

      return;
    }

    if (
    minNotePrice == null ||
        minNotePrice < 0
    ) {
      _showMessage(
        'Minimum not fiyatı geçersiz.',
        success: false,
      );

      return;
    }

    if (
    maxNotePrice == null ||
        maxNotePrice <= 0 ||
        maxNotePrice < minNotePrice
    ) {
      _showMessage(
        'Maksimum fiyat minimum fiyattan küçük olamaz.',
        success: false,
      );

      return;
    }

    if (
    maxPdfSizeMb == null ||
        maxPdfSizeMb < 1 ||
        maxPdfSizeMb > 500
    ) {
      _showMessage(
        'PDF boyutu 1 ile 500 MB arasında olmalıdır.',
        success: false,
      );

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
            'Ayarları Kaydet',
          ),
          content: const Text(
            'Sistem ayarları güncellenecek. Devam edilsin mi?',
            style: TextStyle(
              color:
              AdminColors.textSecondary,
              height: 1.45,
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
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Kaydet',
              ),
            ),
          ],
        );
      },
    );

    if (
    confirmed != true ||
        !mounted
    ) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final Map<String, dynamic> result =
    await _apiService
        .updateSystemSettings(
      commissionRate: commissionRate,
      minNotePrice: minNotePrice,
      maxNotePrice: maxNotePrice,
      maxPdfSizeMb: maxPdfSizeMb,
      registrationEnabled:
      _registrationEnabled,
      noteApprovalRequired:
      _noteApprovalRequired,
      notificationsEnabled:
      _notificationsEnabled,
      maintenanceMode:
      _maintenanceMode,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (result['success'] != true) {
      _showMessage(
        result['error']?.toString() ??
            'Sistem ayarları kaydedilemedi.',
        success: false,
      );

      return;
    }

    _showMessage(
      result['message']?.toString() ??
          'Sistem ayarları kaydedildi.',
    );

    await _loadSettings();
  }

  void _showMessage(
      String message, {
        bool success = true,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? AdminColors.success
            : AdminColors.error,
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final DateTime? parsed =
    DateTime.tryParse(
      value.toString(),
    );

    if (parsed == null) {
      return value.toString();
    }

    final DateTime date =
    parsed.toLocal();

    final String day =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final String month =
    date.month.toString().padLeft(
      2,
      '0',
    );

    final String hour =
    date.hour.toString().padLeft(
      2,
      '0',
    );

    final String minute =
    date.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day.$month.${date.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      onRefresh: _loadSettings,
      color: AdminColors.primaryLight,
      backgroundColor:
      AdminColors.surface,
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
          _buildHeader(),

          const SizedBox(height: 18),

          _buildSection(
            title: 'Finans Ayarları',
            icon:
            Icons.payments_rounded,
            children: [
              _buildNumberField(
                controller:
                _commissionController,
                label:
                'Komisyon Oranı',
                suffixText: '%',
                icon:
                Icons.percent_rounded,
                decimal: true,
              ),

              const SizedBox(height: 13),

              _buildNumberField(
                controller:
                _minPriceController,
                label:
                'Minimum Not Fiyatı',
                suffixText: 'TL',
                icon:
                Icons.south_rounded,
                decimal: true,
              ),

              const SizedBox(height: 13),

              _buildNumberField(
                controller:
                _maxPriceController,
                label:
                'Maksimum Not Fiyatı',
                suffixText: 'TL',
                icon:
                Icons.north_rounded,
                decimal: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSection(
            title: 'Dosya Ayarları',
            icon:
            Icons.picture_as_pdf_rounded,
            children: [
              _buildNumberField(
                controller:
                _maxPdfSizeController,
                label:
                'Maksimum PDF Boyutu',
                suffixText: 'MB',
                icon:
                Icons.file_present_rounded,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSection(
            title: 'Uygulama Ayarları',
            icon:
            Icons.tune_rounded,
            children: [
              _buildSwitchTile(
                title:
                'Yeni Kayıtlar Açık',
                description:
                'Kullanıcılar yeni hesap oluşturabilir.',
                icon:
                Icons.person_add_rounded,
                value:
                _registrationEnabled,
                onChanged: (
                    bool value,
                    ) {
                  setState(() {
                    _registrationEnabled =
                        value;
                  });
                },
              ),

              _buildDivider(),

              _buildSwitchTile(
                title:
                'Not Onayı Zorunlu',
                description:
                'Yüklenen notlar admin onayından geçer.',
                icon:
                Icons.verified_rounded,
                value:
                _noteApprovalRequired,
                onChanged: (
                    bool value,
                    ) {
                  setState(() {
                    _noteApprovalRequired =
                        value;
                  });
                },
              ),

              _buildDivider(),

              _buildSwitchTile(
                title:
                'Bildirim Sistemi Açık',
                description:
                'Sistem bildirimleri kullanıcılara gönderilir.',
                icon:
                Icons.notifications_active_rounded,
                value:
                _notificationsEnabled,
                onChanged: (
                    bool value,
                    ) {
                  setState(() {
                    _notificationsEnabled =
                        value;
                  });
                },
              ),

              _buildDivider(),

              _buildSwitchTile(
                title:
                'Bakım Modu',
                description:
                'Açıldığında kullanıcı uygulaması geçici olarak kapatılır.',
                icon:
                Icons.build_circle_rounded,
                value:
                _maintenanceMode,
                warning: true,
                onChanged: (
                    bool value,
                    ) {
                  setState(() {
                    _maintenanceMode =
                        value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoCard(),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isSaving
                  ? null
                  : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                width: 19,
                height: 19,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(
                Icons.save_rounded,
              ),
              label: Text(
                _isSaving
                    ? 'Kaydediliyor...'
                    : 'Ayarları Kaydet',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: AdminColors.surface,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: AdminColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration:
            BoxDecoration(
              color: AdminColors.primary
                  .withValues(
                alpha: 0.13,
              ),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color:
              AdminColors.primaryLight,
              size: 27,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistem Ayarları',
                  style: TextStyle(
                    color: AdminColors
                        .textPrimary,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Uygulama kurallarını ve finans ayarlarını yönetin.',
                  style: TextStyle(
                    color: AdminColors
                        .textMuted,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: _loadSettings,
            tooltip: 'Yenile',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: AdminColors.surface,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AdminColors
                    .primaryLight,
              ),

              const SizedBox(width: 9),

              Text(
                title,
                style:
                const TextStyle(
                  color: AdminColors
                      .textPrimary,
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController
    controller,
    required String label,
    required String suffixText,
    required IconData icon,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
      TextInputType.numberWithOptions(
        decimal: decimal,
      ),
      decoration:
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffixText,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>
    onChanged,
    bool warning = false,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        width: 42,
        height: 42,
        decoration:
        BoxDecoration(
          color: (
              warning
                  ? AdminColors.warning
                  : AdminColors.primary
          ).withValues(
            alpha: 0.12,
          ),
          borderRadius:
          BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          size: 21,
          color: warning
              ? AdminColors.warning
              : AdminColors.primaryLight,
        ),
      ),
      title: Text(
        title,
        style:
        const TextStyle(
          color:
          AdminColors.textPrimary,
          fontSize: 13,
          fontWeight:
          FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding:
        const EdgeInsets.only(
          top: 3,
        ),
        child: Text(
          description,
          style:
          const TextStyle(
            color:
            AdminColors.textMuted,
            fontSize: 10,
            height: 1.35,
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 18,
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding:
      const EdgeInsets.all(15),
      decoration:
      BoxDecoration(
        color: AdminColors.primary
            .withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: AdminColors.primary
              .withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color:
            AdminColors.primaryLight,
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              'Son güncelleme: ${_formatDate(_updatedAt)}',
              style:
              const TextStyle(
                color: AdminColors
                    .textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return RefreshIndicator(
      onRefresh: _loadSettings,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 150),

          const Icon(
            Icons.settings_backup_restore_rounded,
            color: AdminColors.error,
            size: 58,
          ),

          const SizedBox(height: 16),

          const Text(
            'Sistem ayarları yüklenemedi',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              AdminColors.textPrimary,
              fontSize: 18,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _errorMessage ??
                'Bir hata oluştu.',
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color: AdminColors
                  .textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _loadSettings,
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