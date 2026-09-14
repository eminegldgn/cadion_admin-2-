import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<CoursesScreen> createState() =>
      _CoursesScreenState();
}

class _CoursesScreenState
    extends State<CoursesScreen> {
final AdminApiService _apiService =
AdminApiService();

final TextEditingController
_searchController =
TextEditingController();

bool _isLoading = true;
bool _isProcessing = false;

String? _errorMessage;

int? _selectedCategoryId;

List<Map<String, dynamic>> _courses =
<Map<String, dynamic>>[];

List<Map<String, dynamic>>
_filteredCourses =
<Map<String, dynamic>>[];

List<Map<String, dynamic>> _categories =
<Map<String, dynamic>>[];

@override
void initState() {
super.initState();

_searchController.addListener(
_filterCourses,
);

_loadInitialData();
}

@override
void dispose() {
_searchController.removeListener(
_filterCourses,
);

_searchController.dispose();

super.dispose();
}

Future<void> _loadInitialData() async {
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
_apiService.getCourses(),
  _apiService.getUniversities()
],
);

if (!mounted) {
return;
}

final Map<String, dynamic>
coursesResult =
Map<String, dynamic>.from(
results[0] as Map,
);

final Map<String, dynamic>
categoriesResult =
Map<String, dynamic>.from(
results[1] as Map,
);

if (coursesResult['success'] != true) {
setState(() {
_isLoading = false;

_errorMessage =
coursesResult['error']
?.toString() ??
'Dersler getirilemedi.';
});

return;
}

if (
categoriesResult['success'] != true
) {
setState(() {
_isLoading = false;

_errorMessage =
categoriesResult['error']
?.toString() ??
'Kategoriler getirilemedi.';
});

return;
}

final List<Map<String, dynamic>>
parsedCourses =
<Map<String, dynamic>>[];

final dynamic coursesValue =
coursesResult['courses'];

if (coursesValue is List) {
for (final dynamic item
in coursesValue) {
if (item is Map) {
parsedCourses.add(
Map<String, dynamic>.from(
item,
),
);
}
}
}

final List<Map<String, dynamic>>
parsedCategories =
<Map<String, dynamic>>[];

final dynamic categoriesValue =
categoriesResult['universities'];

if (categoriesValue is List) {
for (final dynamic item
in categoriesValue) {
if (item is Map) {
parsedCategories.add(
Map<String, dynamic>.from(
item,
),
);
}
}
}

setState(() {
_isLoading = false;

_courses = parsedCourses;

_filteredCourses =
List<Map<String, dynamic>>.from(
parsedCourses,
);

_categories =
parsedCategories;
});

_filterCourses();
}

Future<void> _reloadCourses() async {
final Map<String, dynamic> result =
await _apiService.getCourses();

if (!mounted) {
return;
}

if (result['success'] != true) {
_showMessage(
result['error']?.toString() ??
'Dersler yenilenemedi.',
success: false,
);

return;
}

final List<Map<String, dynamic>>
parsedCourses =
<Map<String, dynamic>>[];

final dynamic coursesValue =
result['courses'];

if (coursesValue is List) {
for (final dynamic item
in coursesValue) {
if (item is Map) {
parsedCourses.add(
Map<String, dynamic>.from(
item,
),
);
}
}
}

setState(() {
_courses = parsedCourses;
});

_filterCourses();
}

void _filterCourses() {
if (!mounted) {
return;
}

final String search =
_searchController.text
.trim()
.toLowerCase();

setState(() {
_filteredCourses =
_courses.where(
(
Map<String, dynamic> course,
) {
final String courseName =
course['name']
?.toString()
.toLowerCase() ??
'';

final String categoryName =
    course['university_name']
?.toString()
.toLowerCase() ??
'';

final int? categoryId =
int.tryParse(
  course['university_id']
?.toString() ??
'',
);

final bool matchesSearch =
search.isEmpty ||
courseName.contains(
search,
) ||
categoryName.contains(
search,
);

final bool matchesCategory =
_selectedCategoryId == null ||
categoryId ==
_selectedCategoryId;

return matchesSearch &&
matchesCategory;
},
).toList();
});
}
Future<void> _showCourseDialog({
Map<String, dynamic>? course,
}) async {
if (_isProcessing) {
return;
}

if (_categories.isEmpty) {
_showMessage(
'Önce en az bir kategori oluşturmalısınız.',
success: false,
);

return;
}

final bool isEditing =
course != null;

final TextEditingController
nameController =
TextEditingController(
text: course?['name']?.toString() ??
'',
);

int? selectedCategoryId =
int.tryParse(
course?['category_id']
?.toString() ??
'',
);

selectedCategoryId ??=
int.tryParse(
_categories.first['id']
?.toString() ??
'',
);

final Map<String, dynamic>? formData =
await showDialog<
Map<String, dynamic>>(
context: context,
barrierDismissible: false,
builder: (
BuildContext dialogContext,
) {
return StatefulBuilder(
builder: (
BuildContext context,
StateSetter dialogSetState,
) {
return AlertDialog(
backgroundColor:
AdminColors.surface,
title: Text(
isEditing
? 'Dersi Düzenle'
: 'Yeni Ders',
),
content: SizedBox(
width: 430,
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
TextField(
controller:
nameController,
autofocus: true,
maxLength: 150,
textCapitalization:
TextCapitalization
.words,
decoration:
const InputDecoration(
labelText:
'Ders adı',
hintText:
'Örneğin: Veri Yapıları',
prefixIcon: Icon(
Icons
.menu_book_outlined,
),
),
),

const SizedBox(
height: 12,
),

DropdownButtonFormField<
int>(
initialValue:
selectedCategoryId,
isExpanded: true,
decoration:
const InputDecoration(
  labelText: 'Üniversite',
prefixIcon: Icon(
Icons
.category_outlined,
),
),
items: _categories
.map(
(
Map<String,
dynamic>
category,
) {
final int? id =
int.tryParse(
category['id']
?.toString() ??
'',
);

if (id == null) {
return null;
}

return DropdownMenuItem<
int>(
value: id,
child: Text(
category['name']
?.toString() ??
    'Üniversite',
maxLines: 1,
overflow:
TextOverflow
.ellipsis,
),
);
},
)
.whereType<
DropdownMenuItem<
int>>()
.toList(),
onChanged: (
int? value,
) {
dialogSetState(() {
selectedCategoryId =
value;
});
},
),
],
),
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

FilledButton.icon(
onPressed: () {
final String name =
nameController.text
.trim();

if (name.length < 2 ||
selectedCategoryId ==
null) {
return;
}

Navigator.of(dialogContext).pop(
  <String, dynamic>{
    'name': name,
    'university_id': selectedCategoryId,
  },
);
},
icon: Icon(
isEditing
? Icons.save_rounded
: Icons.add_rounded,
),
label: Text(
isEditing
? 'Kaydet'
: 'Ekle',
),
),
],
);
},
);
},
);


if (formData == null || !mounted) {
return;
}

final String name =
formData['name']?.toString() ??
'';

final int? categoryId = int.tryParse(
  formData['university_id']?.toString() ?? '',
);

if (
name.length < 2 ||
name.length > 150
) {
_showMessage(
'Ders adı 2-150 karakter arasında olmalıdır.',
success: false,
);

return;
}

if (categoryId == null) {
_showMessage(
  'Geçerli bir üniversite seçin.',
success: false,
);

return;
}

setState(() {
_isProcessing = true;
});

final Map<String, dynamic> result;

if (isEditing) {
final int? courseId =
int.tryParse(
course['id']?.toString() ?? '',
);

if (courseId == null) {
setState(() {
_isProcessing = false;
});

_showMessage(
'Ders kimliği alınamadı.',
success: false,
);

return;
}

result =
await _apiService.updateCourse(
courseId: courseId,
name: name,
  universityId: categoryId,
);
} else {
result =
await _apiService.addCourse(
name: name,
  universityId: categoryId,
);
}

if (!mounted) {
return;
}

setState(() {
_isProcessing = false;
});

if (result['success'] != true) {
_showMessage(
result['error']?.toString() ??
'Ders kaydedilemedi.',
success: false,
);

return;
}

_showMessage(
result['message']?.toString() ??
'Ders kaydedildi.',
success: true,
);

await _reloadCourses();
}
Future<void> _deleteCourse(
Map<String, dynamic> course,
) async {
if (_isProcessing) {
return;
}

final int? courseId =
int.tryParse(
course['id']?.toString() ?? '',
);

if (courseId == null) {
_showMessage(
'Ders kimliği alınamadı.',
success: false,
);

return;
}

final String courseName =
course['name']?.toString() ??
'Ders';

final int noteCount =
int.tryParse(
course['note_count']?.toString() ??
'0',
) ??
0;

if (noteCount > 0) {
_showMessage(
'Bu derse bağlı $noteCount not bulunduğu için ders silinemez.',
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
'Dersi Sil',
),
content: Text(
'"$courseName" dersini kalıcı olarak silmek istediğinize emin misiniz?',
style: const TextStyle(
color: AdminColors
.textSecondary,
height: 1.5,
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

FilledButton.icon(
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
icon: const Icon(
Icons.delete_rounded,
),
label: const Text(
'Sil',
),
),
],
);
},
);

if (confirmed != true || !mounted) {
return;
}

setState(() {
_isProcessing = true;
});

final Map<String, dynamic> result =
await _apiService.deleteCourse(
courseId,
);

if (!mounted) {
return;
}

setState(() {
_isProcessing = false;
});

if (result['success'] != true) {
_showMessage(
result['error']?.toString() ??
'Ders silinemedi.',
success: false,
);

return;
}

_showMessage(
result['message']?.toString() ??
'Ders silindi.',
success: true,
);

await _reloadCourses();
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
backgroundColor: success
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
onRefresh: _loadInitialData,
child: ListView(
physics:
const AlwaysScrollableScrollPhysics(),
padding:
const EdgeInsets.all(18),
children: [
_buildHeader(),

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
EdgeInsets.all(70),
child: Center(
child:
CircularProgressIndicator(),
),
)
else if (_errorMessage != null)
_buildError()
else if (_filteredCourses.isEmpty)
_buildEmpty()
else
..._filteredCourses.map(
_buildCourseCard,
),
],
),
);
}
Widget _buildHeader() {
final int totalNoteCount =
_courses.fold<int>(
0,
(
int total,
Map<String, dynamic> course,
) {
final int noteCount =
int.tryParse(
course['note_count']
?.toString() ??
'0',
) ??
0;

return total + noteCount;
},
);

return Container(
padding:
const EdgeInsets.all(18),
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
width: 54,
height: 54,
decoration:
BoxDecoration(
color: AdminColors.primary
.withValues(
alpha: 0.14,
),
borderRadius:
BorderRadius.circular(
16,
),
),
child: const Icon(
Icons.menu_book_rounded,
color:
AdminColors.primary,
size: 28,
),
),

const SizedBox(
width: 14,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'${_courses.length} ders',
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
'Toplam $totalNoteCount not derslere bağlı.',
style:
const TextStyle(
color: AdminColors
.textSecondary,
fontSize: 11,
),
),
],
),
),

FilledButton.icon(
onPressed: _isProcessing
? null
: () {
_showCourseDialog();
},
icon: const Icon(
Icons.add_rounded,
),
label: const Text(
'Yeni Ders',
),
),
],
),
);
}

Widget _buildFilters() {
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
child: Column(
children: [
TextField(
controller:
_searchController,
decoration:
InputDecoration(
hintText:
'Ders veya üniversite ara...',
prefixIcon:
const Icon(
Icons.search_rounded,
),
suffixIcon:
_searchController
.text.isEmpty
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
),

const SizedBox(
height: 12,
),

DropdownButtonFormField<int?>(
initialValue:
_selectedCategoryId,
isExpanded: true,
decoration:
const InputDecoration(
labelText:
'Üniversite Filtresi',
prefixIcon: Icon(
Icons.category_outlined,
),
),
items: <DropdownMenuItem<
int?>>[
const DropdownMenuItem<
int?>(
value: null,
child: Text(
    'Tüm Üniversiteler',
),
),
..._categories
.map(
(
Map<String, dynamic>
category,
) {
final int? id =
int.tryParse(
category['id']
?.toString() ??
'',
);

if (id == null) {
return null;
}

return DropdownMenuItem<
int?>(
value: id,
child: Text(
category['name']
?.toString() ??
    'Üniversite',
),
);
},
)
.whereType<
DropdownMenuItem<
int?>>(),
],
onChanged: (
int? value,
) {
setState(() {
_selectedCategoryId =
value;
});

_filterCourses();
},
),
],
),
);
}
Widget _buildCourseCard(
Map<String, dynamic> course,
) {
final String courseName =
course['name']?.toString() ??
'İsimsiz ders';

final String categoryName =
    course['university_name']
?.toString() ??
        'Üniversite bulunamadı';

final int noteCount =
int.tryParse(
course['note_count']?.toString() ??
'0',
) ??
0;

return Container(
margin:
const EdgeInsets.only(
bottom: 11,
),
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
width: 48,
height: 48,
decoration:
BoxDecoration(
color: AdminColors.primary
.withValues(
alpha: 0.12,
),
borderRadius:
BorderRadius.circular(
14,
),
),
child: const Icon(
Icons.menu_book_rounded,
color:
AdminColors.primary,
),
),

const SizedBox(
width: 13,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
courseName,
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
height: 6,
),

Wrap(
spacing: 8,
runSpacing: 6,
children: [
_buildInfoChip(
categoryName,
Icons.category_rounded,
),
_buildInfoChip(
'$noteCount bağlı not',
Icons
.description_rounded,
),
],
),
],
),
),

IconButton(
tooltip: 'Düzenle',
onPressed: _isProcessing
? null
: () {
_showCourseDialog(
course: course,
);
},
icon: const Icon(
Icons.edit_rounded,
color:
AdminColors.primary,
),
),

IconButton(
tooltip: noteCount > 0
? 'Bağlı not bulunduğu için silinemez'
: 'Sil',
onPressed: _isProcessing
? null
: () {
_deleteCourse(
course,
);
},
icon: Icon(
Icons.delete_outline_rounded,
color: noteCount > 0
? AdminColors.textMuted
: AdminColors.error,
),
),
],
),
);
}

Widget _buildInfoChip(
String label,
IconData icon,
) {
return Container(
padding:
const EdgeInsets.symmetric(
horizontal: 9,
vertical: 5,
),
decoration:
BoxDecoration(
color:
AdminColors.surfaceSecondary,
borderRadius:
BorderRadius.circular(10),
),
child: Row(
mainAxisSize:
MainAxisSize.min,
children: [
Icon(
icon,
size: 13,
color:
AdminColors.textMuted,
),

const SizedBox(
width: 5,
),

Text(
label,
style:
const TextStyle(
color: AdminColors
.textSecondary,
fontSize: 10,
fontWeight:
FontWeight.w600,
),
),
],
),
);
}
Widget _buildError() {
  return Center(
    child: Padding(
      padding:
      const EdgeInsets.all(40),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color:
            AdminColors.error,
            size: 52,
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
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          FilledButton.icon(
            onPressed:
            _loadInitialData,
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
    EdgeInsets.all(55),
    child: Column(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Icon(
          Icons.menu_book_outlined,
          color:
          AdminColors.textMuted,
          size: 52,
        ),

        SizedBox(
          height: 12,
        ),

        Text(
          'Gösterilecek ders bulunamadı.',
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