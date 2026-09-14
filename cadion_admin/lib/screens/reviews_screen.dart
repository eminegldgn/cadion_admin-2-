import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<ReviewsScreen> createState() =>
      _ReviewsScreenState();
}

class _ReviewsScreenState
    extends State<ReviewsScreen> {
final AdminApiService _apiService =
AdminApiService();

final TextEditingController
_searchController =
TextEditingController();

bool _isLoading = true;
bool _isDeleting = false;

String? _errorMessage;

int? _selectedRating;

List<Map<String, dynamic>>
_reviews =
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
_apiService.getAdminReviews(
search:
_searchController.text.trim(),
rating: _selectedRating,
page: 1,
limit: 100,
),
_apiService
.getAdminReviewsSummary(),
],
);

if (!mounted) {
return;
}

final Map<String, dynamic>
reviewsResult =
Map<String, dynamic>.from(
results[0] as Map,
);

final Map<String, dynamic>
summaryResult =
Map<String, dynamic>.from(
results[1] as Map,
);

if (
reviewsResult['success'] !=
true
) {
setState(() {
_isLoading = false;

_errorMessage =
reviewsResult['error']
?.toString() ??
'Yorumlar getirilemedi.';
});

return;
}

final List<Map<String, dynamic>>
parsedReviews =
<Map<String, dynamic>>[];

final dynamic reviewsValue =
reviewsResult['reviews'];

if (reviewsValue is List) {
for (
final dynamic item
in reviewsValue
) {
if (item is Map) {
parsedReviews.add(
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

_reviews = parsedReviews;

_summary = parsedSummary;
});
}

Future<void> _deleteReview(
Map<String, dynamic> review,
) async {
if (_isDeleting) {
return;
}

final int? reviewId =
int.tryParse(
review['id']?.toString() ?? '',
);

if (reviewId == null) {
_showMessage(
'Yorum kimliği alınamadı.',
success: false,
);

return;
}

final TextEditingController
reasonController =
TextEditingController();

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
'Yorumu Sil',
),
content: Column(
mainAxisSize:
MainAxisSize.min,
children: [
const Text(
'Bu yorum kalıcı olarak silinecek.',
style: TextStyle(
color: AdminColors
.textSecondary,
),
),
const SizedBox(height: 14),
TextField(
controller:
reasonController,
maxLines: 4,
maxLength: 2000,
decoration:
const InputDecoration(
labelText:
'Silme nedeni',
hintText:
'Kullanıcıya gönderilecek açıklamayı yazın.',
alignLabelWithHint:
true,
),
),
],
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
'Yorumu Sil',
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
reasonController.dispose();
return;
}

final String reason =
reasonController.text.trim();

reasonController.dispose();

setState(() {
_isDeleting = true;
});

final Map<String, dynamic> result =
await _apiService
.deleteAdminReview(
reviewId: reviewId,
reason: reason,
);

if (!mounted) {
return;
}

setState(() {
_isDeleting = false;
});

if (result['success'] != true) {
_showMessage(
result['error']
?.toString() ??
'Yorum silinemedi.',
success: false,
);

return;
}

_showMessage(
result['message']
?.toString() ??
'Yorum silindi.',
success: true,
);

await _loadAll();
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
content: Text(message),
backgroundColor:
success
? AdminColors.success
: AdminColors.error,
),
);
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
else if (_reviews.isEmpty)
_buildEmpty()
else
..._reviews.map(
_buildReviewCard,
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
Icons.rate_review_rounded,
),
_summaryCard(
'Ortalama',
_summary['average_rating'],
Icons.star_rounded,
),
_summaryCard(
'Şikâyetli',
_summary[
'reported_review_count'],
Icons.flag_rounded,
),
_summaryCard(
'1 Yıldız',
_summary['one_star'],
Icons.star_border_rounded,
),
_summaryCard(
'5 Yıldız',
_summary['five_star'],
Icons.star_rounded,
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
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
.start,
children: [
Text(
value?.toString() ??
'0',
maxLines: 1,
overflow:
TextOverflow
.ellipsis,
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
'Kullanıcı, not veya yorum ara...',
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

DropdownButtonFormField<
int?>(
value: _selectedRating,
decoration:
const InputDecoration(
labelText:
'Puan Filtresi',
),
items: const [
DropdownMenuItem<int?>(
value: null,
child:
Text('Tüm Puanlar'),
),
DropdownMenuItem<int?>(
value: 1,
child:
Text('1 Yıldız'),
),
DropdownMenuItem<int?>(
value: 2,
child:
Text('2 Yıldız'),
),
DropdownMenuItem<int?>(
value: 3,
child:
Text('3 Yıldız'),
),
DropdownMenuItem<int?>(
value: 4,
child:
Text('4 Yıldız'),
),
DropdownMenuItem<int?>(
value: 5,
child:
Text('5 Yıldız'),
),
],
onChanged: (
int? value,
) {
setState(() {
_selectedRating =
value;
});

_loadAll();
},
),
],
),
);
}
Widget _buildReviewCard(
Map<String, dynamic> review,
) {
final int? reviewId =
int.tryParse(
review['id']?.toString() ?? '',
);

final int rating =
int.tryParse(
review['rating']?.toString() ?? '0',
) ??
0;

final String userId =
review['user_id']
?.toString() ??
'-';

final String noteTitle =
review['note_title']
?.toString() ??
'Not bulunamadı';

final String comment =
review['comment']
?.toString() ??
'Yorum metni bulunmuyor.';

final String createdAt =
review['created_at']
?.toString() ??
'-';

final int activeReportCount =
int.tryParse(
review['active_report_count']
?.toString() ??
'0',
) ??
0;

return Container(
margin:
const EdgeInsets.only(
bottom: 12,
),
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
color: activeReportCount > 0
? AdminColors.warning
: AdminColors.border,
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
CircleAvatar(
backgroundColor:
AdminColors.primary
.withValues(
alpha: 0.14,
),
child: const Icon(
Icons
.rate_review_rounded,
color:
AdminColors.primary,
),
),

const SizedBox(
width: 12,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
.start,
children: [
Text(
noteTitle,
maxLines: 2,
overflow:
TextOverflow
.ellipsis,
style:
const TextStyle(
color: AdminColors
.textPrimary,
fontSize: 14,
fontWeight:
FontWeight.w700,
),
),

const SizedBox(
height: 5,
),

Text(
userId,
style:
const TextStyle(
color: AdminColors
.textMuted,
fontSize: 11,
),
),
],
),
),

if (activeReportCount > 0)
Container(
padding:
const EdgeInsets
.symmetric(
horizontal: 8,
vertical: 5,
),
decoration:
BoxDecoration(
color: AdminColors
.warning
.withValues(
alpha: 0.12,
),
borderRadius:
BorderRadius
.circular(
9,
),
),
child: Row(
mainAxisSize:
MainAxisSize.min,
children: [
const Icon(
Icons
.flag_rounded,
color: AdminColors
.warning,
size: 14,
),

const SizedBox(
width: 4,
),

Text(
'$activeReportCount',
style:
const TextStyle(
color: AdminColors
.warning,
fontSize: 10,
fontWeight:
FontWeight.w700,
),
),
],
),
),
],
),

const SizedBox(
height: 13,
),

_buildStars(
rating,
),

const SizedBox(
height: 12,
),

Container(
width: double.infinity,
padding:
const EdgeInsets.all(
13,
),
decoration:
BoxDecoration(
color: AdminColors
.surfaceSecondary,
borderRadius:
BorderRadius.circular(
13,
),
),
child: Text(
comment,
style:
const TextStyle(
color: AdminColors
.textSecondary,
fontSize: 12,
height: 1.5,
),
),
),

const SizedBox(
height: 12,
),

Row(
children: [
const Icon(
Icons
.calendar_today_rounded,
color:
AdminColors.textMuted,
size: 14,
),

const SizedBox(
width: 6,
),

Expanded(
child: Text(
createdAt,
style:
const TextStyle(
color: AdminColors
.textMuted,
fontSize: 10,
),
),
),

OutlinedButton.icon(
onPressed:
_isDeleting ||
reviewId == null
? null
: () {
_deleteReview(
review,
);
},
style:
OutlinedButton.styleFrom(
foregroundColor:
AdminColors.error,
side: const BorderSide(
color:
AdminColors.error,
),
),
icon: const Icon(
Icons
.delete_outline_rounded,
size: 17,
),
label: const Text(
'Sil',
),
),
],
),
],
),
);
}

Widget _buildStars(
int rating,
) {
return Row(
children:
List<Widget>.generate(
5,
(
int index,
) {
final int starValue =
index + 1;

return Padding(
padding:
const EdgeInsets.only(
right: 2,
),
child: Icon(
starValue <= rating
? Icons.star_rounded
: Icons
.star_border_rounded,
color:
AdminColors.warning,
size: 20,
),
);
},
),
);
}
Widget _buildError() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AdminColors.error,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Bir hata oluştu.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AdminColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildEmpty() {
  return const Padding(
    padding: EdgeInsets.all(55),
    child: Column(
      children: [
        Icon(
          Icons.rate_review_outlined,
          color: AdminColors.textMuted,
          size: 52,
        ),
        SizedBox(height: 12),
        Text(
          'Gösterilecek yorum bulunamadı.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AdminColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
}