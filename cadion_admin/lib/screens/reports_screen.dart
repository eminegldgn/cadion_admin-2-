import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<ReportsScreen> createState() =>
      _ReportsScreenState();
}

class _ReportsScreenState
    extends State<ReportsScreen> {
final AdminApiService _apiService =
AdminApiService();

final TextEditingController
_searchController =
TextEditingController();

bool _isLoading = true;

String? _errorMessage;

String _selectedStatus =
'pending';

String _selectedType = '';

List<Map<String, dynamic>>
_reports =
<Map<String, dynamic>>[];

Map<String, dynamic> _summary =
<String, dynamic>{};

@override
void initState() {
super.initState();

_loadAll();
}

@override
void dispose() {
_searchController.dispose();

super.dispose();
}

Future<void> _loadAll() async {
if (!mounted) {
return;
}

setState(() {
_isLoading = true;
_errorMessage = null;
});

final List<dynamic> results =
await Future.wait<dynamic>(
<Future<dynamic>>[
_apiService.getReports(
status: _selectedStatus,
type: _selectedType,
search:
_searchController.text.trim(),
limit: 100,
),
_apiService.getReportsSummary(),
],
);

if (!mounted) {
return;
}

final Map<String, dynamic>
reportsResult =
Map<String, dynamic>.from(
results[0] as Map,
);

final Map<String, dynamic>
summaryResult =
Map<String, dynamic>.from(
results[1] as Map,
);

if (
reportsResult['success'] !=
true
) {
setState(() {
_isLoading = false;

_errorMessage =
reportsResult['error']
?.toString() ??
'Şikâyetler getirilemedi.';
});

return;
}

final List<Map<String, dynamic>>
parsedReports =
<Map<String, dynamic>>[];

final dynamic reportsValue =
reportsResult['reports'];

if (reportsValue is List) {
for (
final dynamic item
in reportsValue
) {
if (item is Map) {
parsedReports.add(
Map<String, dynamic>.from(
item,
),
);
}
}
}

final Map<String, dynamic>
parsedSummary =
summaryResult['summary'] is Map
? Map<String, dynamic>.from(
summaryResult['summary']
as Map,
)
: <String, dynamic>{};

setState(() {
_isLoading = false;

_reports = parsedReports;

_summary = parsedSummary;
});
}

Future<void> _openReport(
int reportId,
) async {
await Navigator.of(context).push(
MaterialPageRoute<void>(
builder: (
BuildContext context,
) {
return ReportDetailScreen(
reportId: reportId,
);
},
),
);

if (mounted) {
await _loadAll();
}
}
@override
Widget build(
BuildContext context,
) {
return RefreshIndicator(
onRefresh: _loadAll,
child: ListView(
physics:
const AlwaysScrollableScrollPhysics(),
padding:
const EdgeInsets.all(
18,
),
children: [
_buildSummary(),

const SizedBox(
height: 16,
),

_buildFilters(),

const SizedBox(
height: 16,
),

if (_isLoading)
const Padding(
padding:
EdgeInsets.all(
70,
),
child: Center(
child:
CircularProgressIndicator(),
),
)
else if (_errorMessage != null)
_buildError()
else if (_reports.isEmpty)
_buildEmpty()
else
..._reports.map(
_buildReportCard,
),
],
),
);
}

Widget _buildSummary() {
return Wrap(
spacing: 10,
runSpacing: 10,
children: [
_summaryCard(
'Toplam',
_summary['total'],
Icons.flag_rounded,
),
_summaryCard(
'Bekliyor',
_summary['pending'],
Icons.schedule_rounded,
),
_summaryCard(
'İnceleniyor',
_summary['reviewing'],
Icons.search_rounded,
),
_summaryCard(
'Çözüldü',
_summary['resolved'],
Icons.check_circle_rounded,
),
_summaryCard(
'Reddedildi',
_summary['rejected'],
Icons.cancel_rounded,
),
],
);
}

Widget _summaryCard(
String title,
dynamic value,
IconData icon,
) {
return Container(
width: 145,
padding:
const EdgeInsets.all(
15,
),
decoration:
BoxDecoration(
color:
AdminColors.surface,
borderRadius:
BorderRadius.circular(
16,
),
border: Border.all(
color:
AdminColors.border,
),
),
child: Row(
children: [
Icon(
icon,
color:
AdminColors.primary,
),
const SizedBox(
width: 10,
),
Column(
crossAxisAlignment:
CrossAxisAlignment
.start,
children: [
Text(
value?.toString() ??
'0',
style:
const TextStyle(
color: AdminColors
.textPrimary,
fontSize: 18,
fontWeight:
FontWeight.w800,
),
),
Text(
title,
style:
const TextStyle(
color: AdminColors
.textMuted,
fontSize: 10,
),
),
],
),
],
),
);
}

Widget _buildFilters() {
return Container(
padding:
const EdgeInsets.all(
16,
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
children: [
TextField(
controller:
_searchController,
onSubmitted: (
String value,
) {
_loadAll();
},
decoration:
InputDecoration(
hintText:
'Kullanıcı, not veya açıklama ara...',
prefixIcon:
const Icon(
Icons.search_rounded,
),
suffixIcon:
IconButton(
onPressed:
_loadAll,
icon: const Icon(
Icons.refresh_rounded,
),
),
),
),

const SizedBox(
height: 12,
),

Row(
children: [
Expanded(
child:
DropdownButtonFormField<
String>(
value:
_selectedStatus,
decoration:
const InputDecoration(
labelText:
'Durum',
),
items: const [
DropdownMenuItem<
String>(
value: '',
child:
Text('Tümü'),
),
DropdownMenuItem<
String>(
value:
'pending',
child:
Text('Bekliyor'),
),
DropdownMenuItem<
String>(
value:
'reviewing',
child:
Text(
'İnceleniyor',
),
),
DropdownMenuItem<
String>(
value:
'resolved',
child:
Text('Çözüldü'),
),
DropdownMenuItem<
String>(
value:
'rejected',
child:
Text(
'Reddedildi',
),
),
],
onChanged: (
String? value,
) {
setState(() {
_selectedStatus =
value ?? '';
});

_loadAll();
},
),
),

const SizedBox(
width: 12,
),

Expanded(
child:
DropdownButtonFormField<
String>(
value:
_selectedType,
decoration:
const InputDecoration(
labelText:
'Tür',
),
items: const [
DropdownMenuItem<
String>(
value: '',
child:
Text('Tümü'),
),
DropdownMenuItem<
String>(
value: 'note',
child:
Text('Not'),
),
DropdownMenuItem<
String>(
value: 'review',
child:
Text('Yorum'),
),
],
onChanged: (
String? value,
) {
setState(() {
_selectedType =
value ?? '';
});

_loadAll();
},
),
),
],
),
],
),
);
}
Widget _buildReportCard(
Map<String, dynamic> report,
) {
final int? reportId =
int.tryParse(
report['id']?.toString() ?? '',
);

final String reportType =
report['report_type']
?.toString() ??
'';

final String title =
reportType == 'note'
? report['note_title']
?.toString() ??
'Silinmiş veya bulunamayan not'
: report['related_note_title']
?.toString() ??
'Yorum şikâyeti';

final String userId =
report['user_id']
?.toString() ??
'-';

final String reason =
_reasonLabel(
report['reason']?.toString() ??
'',
);

final String createdAt =
report['created_at']
?.toString() ??
'-';

final String status =
report['status']
?.toString() ??
'';

return Container(
margin:
const EdgeInsets.only(
bottom: 11,
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
child: ListTile(
onTap:
reportId == null
? null
: () {
_openReport(
reportId,
);
},
contentPadding:
const EdgeInsets.all(
15,
),
leading: CircleAvatar(
backgroundColor:
AdminColors.primary
.withValues(
alpha: 0.14,
),
child: Icon(
reportType == 'note'
? Icons
.description_rounded
: Icons
.rate_review_rounded,
color:
AdminColors.primary,
),
),
title: Text(
title,
maxLines: 2,
overflow:
TextOverflow.ellipsis,
style:
const TextStyle(
color: AdminColors
.textPrimary,
fontWeight:
FontWeight.w700,
),
),
subtitle: Padding(
padding:
const EdgeInsets.only(
top: 7,
),
child: Text(
'$userId • $reason\n$createdAt',
style:
const TextStyle(
color: AdminColors
.textSecondary,
fontSize: 11,
height: 1.4,
),
),
),
trailing: SizedBox(
width: 88,
child: Column(
mainAxisAlignment:
MainAxisAlignment
.center,
crossAxisAlignment:
CrossAxisAlignment.end,
children: [
_statusChip(
status,
),
const SizedBox(
height: 5,
),
const Icon(
Icons
.chevron_right_rounded,
color: AdminColors
.textMuted,
),
],
),
),
),
);
}

Widget _statusChip(
String status,
) {
final String label;
final Color color;

switch (status) {
case 'pending':
label = 'Bekliyor';
color =
AdminColors.warning;
break;

case 'reviewing':
label = 'İnceleniyor';
color =
AdminColors.primary;
break;

case 'resolved':
label = 'Çözüldü';
color =
AdminColors.success;
break;

case 'rejected':
label = 'Reddedildi';
color =
AdminColors.error;
break;

default:
label = status.isEmpty
? 'Bilinmiyor'
: status;

color =
AdminColors.textMuted;
}

return Container(
padding:
const EdgeInsets.symmetric(
horizontal: 8,
vertical: 4,
),
decoration:
BoxDecoration(
color: color.withValues(
alpha: 0.12,
),
borderRadius:
BorderRadius.circular(
9,
),
),
child: Text(
label,
maxLines: 1,
overflow:
TextOverflow.ellipsis,
style: TextStyle(
color: color,
fontSize: 9,
fontWeight:
FontWeight.w700,
),
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
Widget _buildError() {
  return Center(
    child: Padding(
      padding:
      const EdgeInsets.all(
        40,
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
            size: 50,
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            _errorMessage ??
                'Bir hata oluştu.',
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
            height: 14,
          ),
          FilledButton.icon(
            onPressed:
            _loadAll,
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

Widget _buildEmpty() {
  return const Padding(
    padding:
    EdgeInsets.all(
      55,
    ),
    child: Column(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Icon(
          Icons.flag_outlined,
          color:
          AdminColors.textMuted,
          size: 52,
        ),
        SizedBox(
          height: 12,
        ),
        Text(
          'Bu filtreye uygun şikâyet bulunamadı.',
          textAlign:
          TextAlign.center,
          style: TextStyle(
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