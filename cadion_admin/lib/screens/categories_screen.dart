import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<CategoriesScreen> createState() =>
      _CategoriesScreenState();
}

class _CategoriesScreenState
    extends State<CategoriesScreen> {
final AdminApiService _apiService =
AdminApiService();

final TextEditingController
_searchController =
TextEditingController();

bool _isLoading = true;
bool _isProcessing = false;

String? _errorMessage;

List<Map<String, dynamic>>
_categories =
<Map<String, dynamic>>[];

List<Map<String, dynamic>>
_filteredCategories =
<Map<String, dynamic>>[];

@override
void initState() {
super.initState();

_searchController.addListener(
_filterCategories,
);

_loadCategories();
}

@override
void dispose() {
_searchController
.removeListener(
_filterCategories,
);

_searchController.dispose();

super.dispose();
}

Future<void>
_loadCategories() async {
if (!mounted) {
return;
}

setState(() {
_isLoading = true;
_errorMessage = null;
});

final Map<String, dynamic> result =
await _apiService.getCategories();

if (!mounted) {
return;
}

if (result['success'] != true) {
setState(() {
_isLoading = false;

_errorMessage =
result['error']
?.toString() ??
'Kategoriler getirilemedi.';
});

return;
}

final List<Map<String, dynamic>>
parsedCategories =
<Map<String, dynamic>>[];

final dynamic categoriesValue =
result['categories'];

if (categoriesValue is List) {
for (
final dynamic item
in categoriesValue
) {
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

_categories =
parsedCategories;

_filteredCategories =
List<Map<String, dynamic>>.from(
parsedCategories,
);
});

_filterCategories();
}

void _filterCategories() {
final String search =
_searchController.text
.trim()
.toLowerCase();

if (!mounted) {
return;
}

setState(() {
if (search.isEmpty) {
_filteredCategories =
List<Map<String, dynamic>>.from(
_categories,
);

return;
}

_filteredCategories =
_categories.where(
(
Map<String, dynamic>
category,
) {
final String name =
category['name']
?.toString()
.toLowerCase() ??
'';

return name.contains(
search,
);
},
).toList();
});
}

Future<void> _showCategoryDialog({
Map<String, dynamic>? category,
}) async {
if (_isProcessing) {
return;
}

final bool isEditing =
category != null;

final TextEditingController
nameController =
TextEditingController(
text: category?['name']
?.toString() ??
'',
);

final bool? shouldSave =
await showDialog<bool>(
context: context,
barrierDismissible: false,
builder: (
BuildContext dialogContext,
) {
return AlertDialog(
backgroundColor:
AdminColors.surface,
title: Text(
isEditing
? 'Kategoriyi Düzenle'
: 'Yeni Kategori',
),
content: TextField(
controller:
nameController,
autofocus: true,
maxLength: 100,
textCapitalization:
TextCapitalization.words,
decoration:
const InputDecoration(
labelText:
'Kategori adı',
hintText:
'Örneğin: Yazılım',
prefixIcon: Icon(
Icons.category_outlined,
),
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
onPressed: () {
final String name =
nameController.text
.trim();

if (name.length < 2) {
return;
}

Navigator.of(
dialogContext,
).pop(true);
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

final String name =
nameController.text.trim();

nameController.dispose();

if (
shouldSave != true ||
!mounted
) {
return;
}

if (
name.length < 2 ||
name.length > 100
) {
_showMessage(
'Kategori adı 2-100 karakter arasında olmalıdır.',
success: false,
);

return;
}

setState(() {
_isProcessing = true;
});

final Map<String, dynamic> result;

if (isEditing) {
final int? categoryId =
int.tryParse(
category['id']?.toString() ??
'',
);

if (categoryId == null) {
setState(() {
_isProcessing = false;
});

_showMessage(
'Kategori kimliği alınamadı.',
success: false,
);

return;
}

result =
await _apiService
.updateCategory(
categoryId: categoryId,
name: name,
);
} else {
result =
await _apiService
.addCategory(
name,
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
result['error']
?.toString() ??
'Kategori kaydedilemedi.',
success: false,
);

return;
}

_showMessage(
result['message']
?.toString() ??
'Kategori kaydedildi.',
success: true,
);

await _loadCategories();
}
Future<void> _deleteCategory(
Map<String, dynamic> category,
) async {
if (_isProcessing) {
return;
}

final int? categoryId =
int.tryParse(
category['id']?.toString() ?? '',
);

if (categoryId == null) {
_showMessage(
'Kategori kimliği alınamadı.',
success: false,
);
return;
}

final String categoryName =
category['name']?.toString() ??
'Kategori';

final int noteCount =
int.tryParse(
category['note_count']?.toString() ??
'0',
) ??
0;

if (noteCount > 0) {
_showMessage(
'Bu kategoriye bağlı $noteCount not bulunduğu için silinemez.',
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
'Kategoriyi Sil',
),
content: Text(
'"$categoryName" kategorisini kalıcı olarak silmek istediğinize emin misiniz?',
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

if (
confirmed != true ||
!mounted
) {
return;
}

setState(() {
_isProcessing = true;
});

final Map<String, dynamic> result =
await _apiService.deleteCategory(
categoryId,
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
'Kategori silinemedi.',
success: false,
);
return;
}

_showMessage(
result['message']?.toString() ??
'Kategori silindi.',
success: true,
);

await _loadCategories();
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
onRefresh: _loadCategories,
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
padding:
EdgeInsets.all(70),
child: Center(
child:
CircularProgressIndicator(),
),
)
else if (_errorMessage != null)
_buildError()
else if (
_filteredCategories.isEmpty
)
_buildEmpty()
else
..._filteredCategories.map(
_buildCategoryCard,
),
],
),
);
}

Widget _buildHeader() {
final int totalNoteCount =
_categories.fold<int>(
0,
(
int total,
Map<String, dynamic> category,
) {
final int noteCount =
int.tryParse(
category['note_count']
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
Icons.category_rounded,
color:
AdminColors.primary,
size: 28,
),
),

const SizedBox(width: 14),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'${_categories.length} kategori',
style:
const TextStyle(
color: AdminColors
.textPrimary,
fontSize: 18,
fontWeight:
FontWeight.w800,
),
),
const SizedBox(height: 4),
Text(
'Toplam $totalNoteCount not kategorilere bağlı.',
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
onPressed:
_isProcessing
? null
: () {
_showCategoryDialog();
},
icon: const Icon(
Icons.add_rounded,
),
label: const Text(
'Yeni Kategori',
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
'Kategori ara...',
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
Widget _buildCategoryCard(
    Map<String, dynamic> category,
    ) {
  final String name =
      category['name']?.toString() ??
          'İsimsiz kategori';

  final int noteCount =
      int.tryParse(
        category['note_count']?.toString() ??
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
          width: 46,
          height: 46,
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
            Icons.category_rounded,
            color:
            AdminColors.primary,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style:
                const TextStyle(
                  color: AdminColors
                      .textPrimary,
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                '$noteCount bağlı not',
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

        IconButton(
          tooltip: 'Düzenle',
          onPressed:
          _isProcessing
              ? null
              : () {
            _showCategoryDialog(
              category:
              category,
            );
          },
          icon: const Icon(
            Icons.edit_rounded,
            color:
            AdminColors.primary,
          ),
        ),

        IconButton(
          tooltip: 'Sil',
          onPressed:
          _isProcessing
              ? null
              : () {
            _deleteCategory(
              category,
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
            Icons.error_outline_rounded,
            color:
            AdminColors.error,
            size: 52,
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

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed:
            _loadCategories,
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
          Icons.category_outlined,
          color:
          AdminColors.textMuted,
          size: 52,
        ),

        SizedBox(height: 12),

        Text(
          'Gösterilecek kategori bulunamadı.',
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