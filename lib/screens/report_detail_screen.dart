import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.reportId,
  });

  final int reportId;

  @override
  State<ReportDetailScreen> createState() =>
      _ReportDetailScreenState();
}

class _ReportDetailScreenState
    extends State<ReportDetailScreen> {
final AdminApiService _apiService =
AdminApiService();

final TextEditingController
_adminNoteController =
TextEditingController();

bool _isLoading = true;
bool _isSaving = false;

bool _removeNote = false;
bool _deleteReview = false;

String? _errorMessage;

Map<String, dynamic>? _report;

String _selectedStatus =
'reviewing';

@override
void initState() {
super.initState();

_loadReport();
}

@override
void dispose() {
_adminNoteController.dispose();

super.dispose();
}

Future<void> _loadReport() async {
if (!mounted) {
return;
}

setState(() {
_isLoading = true;
_errorMessage = null;
});

final Map<String, dynamic> result =
await _apiService.getReportDetail(
widget.reportId,
);

if (!mounted) {
return;
}

if (
result['success'] != true ||
result['report'] is! Map
) {
setState(() {
_isLoading = false;

_errorMessage =
result['error']
?.toString() ??
'Şikâyet getirilemedi.';
});

return;
}

final Map<String, dynamic> report =
Map<String, dynamic>.from(
result['report'] as Map,
);

setState(() {
_isLoading = false;

_report = report;

_selectedStatus =
report['status']
?.toString() ??
'reviewing';

_adminNoteController.text =
report['admin_note']
?.toString() ??
'';

_removeNote = false;
_deleteReview = false;
});
}

Future<void> _save() async {
if (
_isSaving ||
_report == null
) {
return;
}

setState(() {
_isSaving = true;
});

final Map<String, dynamic> result =
await _apiService
.updateReportStatus(
reportId:
widget.reportId,

status:
_selectedStatus,

adminNote:
_adminNoteController.text,

removeNote:
_removeNote,

deleteReview:
_deleteReview,
);

if (!mounted) {
return;
}

setState(() {
_isSaving = false;
});

if (result['success'] != true) {
_showMessage(
result['error']
?.toString() ??
'İşlem gerçekleştirilemedi.',
success: false,
);

return;
}

_showMessage(
result['message']
?.toString() ??
'Şikâyet güncellendi.',
success: true,
);

await _loadReport();
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
content:
Text(message),
backgroundColor:
success
? AdminColors.success
: AdminColors.error,
),
);
}

String _reasonLabel(
String value,
) {
const Map<String, String> labels =
<String, String>{
'incorrect_content':
'Yanlış içerik',

'incomplete_content':
'Eksik içerik',

'copyright':
'Telif hakkı',

'inappropriate_content':
'Uygunsuz içerik',

'spam':
'Spam',

'other':
'Diğer',
};

return labels[value] ??
(value.isEmpty
? 'Belirtilmemiş'
: value);
}
@override
Widget build(
BuildContext context,
) {
return Scaffold(
backgroundColor:
AdminColors.background,
appBar: AppBar(
title: Text(
'Şikâyet #${widget.reportId}',
),
),
body: _buildBody(),
);
}

Widget _buildBody() {
if (_isLoading) {
return const Center(
child:
CircularProgressIndicator(),
);
}

if (_errorMessage != null) {
return Center(
child: Padding(
padding:
const EdgeInsets.all(
24,
),
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
const Icon(
Icons
.error_outline_rounded,
color:
AdminColors.error,
size: 54,
),
const SizedBox(
height: 14,
),
Text(
_errorMessage!,
textAlign:
TextAlign.center,
style:
const TextStyle(
color: AdminColors
.textSecondary,
fontSize: 13,
),
),
const SizedBox(
height: 16,
),
FilledButton.icon(
onPressed:
_loadReport,
icon: const Icon(
Icons.refresh_rounded,
),
label: const Text(
'Tekrar Dene',
),
),
],
),
),
);
}

final Map<String, dynamic> report =
_report!;

final String reportType =
report['report_type']
?.toString() ??
'';

return ListView(
padding:
const EdgeInsets.all(
18,
),
children: [
_section(
title:
'Şikâyet Bilgileri',
children: [
_row(
'Tür',
reportType == 'note'
? 'Not'
: 'Yorum',
),
_row(
'Durum',
_statusLabel(
report['status']
?.toString() ??
'',
),
),
_row(
'Şikâyet Eden',
report['user_id']
?.toString() ??
'-',
),
_row(
'Neden',
_reasonLabel(
report['reason']
?.toString() ??
'',
),
),
_row(
'Oluşturulma',
report['created_at']
?.toString() ??
'-',
),
_row(
'Son Güncelleme',
report['updated_at']
?.toString() ??
'-',
),
],
),

const SizedBox(
height: 14,
),

_buildReportedContent(
report,
reportType,
),

const SizedBox(
height: 14,
),

_section(
title:
'Kullanıcı Açıklaması',
children: [
Text(
report['description']
?.toString() ??
'Açıklama yazılmamış.',
style:
const TextStyle(
color: AdminColors
.textSecondary,
fontSize: 13,
height: 1.5,
),
),
],
),

const SizedBox(
height: 14,
),

_buildAdminAction(
reportType,
),
],
);
}

Widget _buildReportedContent(
Map<String, dynamic> report,
String reportType,
) {
if (reportType == 'note') {
return _section(
title:
'Şikâyet Edilen Not',
children: [
_row(
'Not ID',
report['note_id']
?.toString() ??
'-',
),
_row(
'Başlık',
report['note_title']
?.toString() ??
'Not bulunamadı',
),
_row(
'Not Sahibi',
report['note_owner_id']
?.toString() ??
'-',
),
_row(
'Not Durumu',
report['note_status']
?.toString() ??
'-',
),
_row(
'Fiyat',
report['note_price'] == null
? '-'
: '${report['note_price']} TL',
),
const SizedBox(
height: 8,
),
Text(
report['note_description']
?.toString() ??
'Not açıklaması bulunmuyor.',
style:
const TextStyle(
color: AdminColors
.textSecondary,
fontSize: 13,
height: 1.5,
),
),
],
);
}

return _section(
title:
'Şikâyet Edilen Yorum',
children: [
_row(
'Yorum ID',
report['review_id']
?.toString() ??
'-',
),
_row(
'İlgili Not',
report['related_note_title']
?.toString() ??
'-',
),
_row(
'Yorum Sahibi',
report['review_user_id']
?.toString() ??
'-',
),
_row(
'Puan',
report['review_rating']
?.toString() ??
'-',
),
const SizedBox(
height: 8,
),
Text(
report['review_comment']
?.toString() ??
'Yorum bulunamadı.',
style:
const TextStyle(
color: AdminColors
.textSecondary,
fontSize: 13,
height: 1.5,
),
),
],
);
}

String _statusLabel(
String status,
) {
switch (status) {
case 'pending':
return 'Bekliyor';

case 'reviewing':
return 'İnceleniyor';

case 'resolved':
return 'Çözüldü';

case 'rejected':
return 'Reddedildi';

default:
return status.isEmpty
? 'Bilinmiyor'
: status;
}
}
Widget _buildAdminAction(
String reportType,
) {
return _section(
title: 'Admin İşlemi',
children: [
DropdownButtonFormField<String>(
value: _selectedStatus,
decoration: const InputDecoration(
labelText: 'Şikâyet Durumu',
),
items: const [
DropdownMenuItem<String>(
value: 'pending',
child: Text('Bekliyor'),
),
DropdownMenuItem<String>(
value: 'reviewing',
child: Text('İnceleniyor'),
),
DropdownMenuItem<String>(
value: 'resolved',
child: Text('Çözüldü'),
),
DropdownMenuItem<String>(
value: 'rejected',
child: Text('Reddedildi'),
),
],
onChanged: _isSaving
? null
: (String? value) {
if (value == null) {
return;
}

setState(() {
_selectedStatus =
value;
});
},
),

const SizedBox(
height: 14,
),

TextField(
controller:
_adminNoteController,
enabled: !_isSaving,
maxLines: 5,
maxLength: 3000,
decoration:
const InputDecoration(
labelText:
'Admin Notu',
hintText:
'İnceleme sonucu veya açıklama yazın.',
alignLabelWithHint:
true,
),
),

const SizedBox(
height: 8,
),

if (reportType == 'note')
SwitchListTile(
contentPadding:
EdgeInsets.zero,
value: _removeNote,
onChanged: _isSaving
? null
: (bool value) {
setState(() {
_removeNote =
value;
});
},
title: const Text(
'Notu yayından kaldır',
style: TextStyle(
color: AdminColors
.textPrimary,
fontWeight:
FontWeight.w700,
),
),
subtitle: const Text(
'Not durumu rejected olarak değiştirilir ve not sahibine bildirim gönderilir.',
style: TextStyle(
color: AdminColors
.textSecondary,
fontSize: 11,
height: 1.4,
),
),
activeThumbColor:
AdminColors.error,
),

if (reportType == 'review')
SwitchListTile(
contentPadding:
EdgeInsets.zero,
value: _deleteReview,
onChanged: _isSaving
? null
: (bool value) {
setState(() {
_deleteReview =
value;
});
},
title: const Text(
'Yorumu sil',
style: TextStyle(
color: AdminColors
.textPrimary,
fontWeight:
FontWeight.w700,
),
),
subtitle: const Text(
'Şikâyet edilen yorum kalıcı olarak silinir ve yorum sahibine bildirim gönderilir.',
style: TextStyle(
color: AdminColors
.textSecondary,
fontSize: 11,
height: 1.4,
),
),
activeThumbColor:
AdminColors.error,
),

const SizedBox(
height: 14,
),

if (_removeNote ||
_deleteReview)
Container(
width: double.infinity,
margin:
const EdgeInsets.only(
bottom: 14,
),
padding:
const EdgeInsets.all(
14,
),
decoration:
BoxDecoration(
color: AdminColors.error
.withValues(
alpha: 0.09,
),
borderRadius:
BorderRadius.circular(
14,
),
border: Border.all(
color: AdminColors.error
.withValues(
alpha: 0.28,
),
),
),
child: const Row(
crossAxisAlignment:
CrossAxisAlignment
.start,
children: [
Icon(
Icons
.warning_amber_rounded,
color:
AdminColors.error,
size: 21,
),
SizedBox(
width: 10,
),
Expanded(
child: Text(
'Bu işlem içerik üzerinde moderasyon işlemi gerçekleştirir. Kaydetmeden önce seçiminizi kontrol edin.',
style: TextStyle(
color: AdminColors
.textSecondary,
fontSize: 11,
height: 1.45,
),
),
),
],
),
),

SizedBox(
width: double.infinity,
child:
FilledButton.icon(
onPressed:
_isSaving
? null
: _confirmAndSave,
icon: _isSaving
? const SizedBox(
width: 18,
height: 18,
child:
CircularProgressIndicator(
strokeWidth: 2,
color:
Colors.white,
),
)
: const Icon(
Icons.save_rounded,
),
label: Text(
_isSaving
? 'Kaydediliyor...'
: 'İşlemi Kaydet',
),
),
),
],
);
}

Future<void>
_confirmAndSave() async {
if (_isSaving) {
return;
}

if (
!_removeNote &&
!_deleteReview
) {
await _save();
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
'İşlemi Onayla',
),
content: Text(
_removeNote
? 'Şikâyet edilen not yayından kaldırılacak. Devam etmek istiyor musunuz?'
: 'Şikâyet edilen yorum kalıcı olarak silinecek. Devam etmek istiyor musunuz?',
style: const TextStyle(
color: AdminColors
.textSecondary,
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
style:
FilledButton.styleFrom(
backgroundColor:
AdminColors.error,
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

if (
confirmed == true &&
mounted
) {
await _save();
}
}
Widget _section({
  required String title,
  required List<Widget> children,
}) {
  return Container(
    width: double.infinity,
    padding:
    const EdgeInsets.all(
      18,
    ),
    decoration:
    BoxDecoration(
      color:
      AdminColors.surface,
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      border: Border.all(
        color:
        AdminColors.border,
      ),
    ),
    child: Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
          const TextStyle(
            color: AdminColors
                .textPrimary,
            fontSize: 16,
            fontWeight:
            FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        ...children,
      ],
    ),
  );
}

Widget _row(
    String label,
    String value,
    ) {
  return Padding(
    padding:
    const EdgeInsets.only(
      bottom: 9,
    ),
    child: Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style:
            const TextStyle(
              color: AdminColors
                  .textMuted,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Text(
            value,
            style:
            const TextStyle(
              color: AdminColors
                  .textPrimary,
              fontSize: 13,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
}