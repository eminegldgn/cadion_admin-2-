import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

class UniversitiesScreen
    extends StatefulWidget {
  const UniversitiesScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<UniversitiesScreen>
  createState() =>
      _UniversitiesScreenState();
}

class _UniversitiesScreenState
    extends State<UniversitiesScreen> {
final AdminApiService _apiService =
AdminApiService();

final TextEditingController
_searchController =
TextEditingController();

bool _isLoading = true;
bool _isProcessing = false;

String? _errorMessage;

List<Map<String, dynamic>>
_universities =
<Map<String, dynamic>>[];

List<Map<String, dynamic>>
_filteredUniversities =
<Map<String, dynamic>>[];

@override
void initState() {
super.initState();

_searchController.addListener(
_filterUniversities,
);

_loadUniversities();
}

@override
void dispose() {
_searchController.removeListener(
_filterUniversities,
);

_searchController.dispose();

super.dispose();
}

Future<void>
_loadUniversities() async {
if (!mounted) {
return;
}

setState(() {
_isLoading = true;
_errorMessage = null;
});

final Map<String, dynamic> result =
await _apiService
.getUniversities();

if (!mounted) {
return;
}

if (result['success'] != true) {
setState(() {
_isLoading = false;

_errorMessage =
result['error']
?.toString() ??
'Üniversiteler getirilemedi.';
});

return;
}

final List<Map<String, dynamic>>
parsedUniversities =
<Map<String, dynamic>>[];

final dynamic universitiesValue =
result['universities'];

if (universitiesValue is List) {
for (
final dynamic item
in universitiesValue
) {
if (item is Map) {
parsedUniversities.add(
Map<String, dynamic>.from(
item,
),
);
}
}
}

setState(() {
_isLoading = false;

_universities =
parsedUniversities;

_filteredUniversities =
List<Map<String, dynamic>>.from(
parsedUniversities,
);
});

_filterUniversities();
}

void _filterUniversities() {
final String search =
_searchController.text
.trim()
.toLowerCase();

if (!mounted) {
return;
}

setState(() {
if (search.isEmpty) {
_filteredUniversities =
List<Map<String, dynamic>>.from(
_universities,
);

return;
}

_filteredUniversities =
_universities.where(
(
Map<String, dynamic>
university,
) {
final String name =
university['name']
?.toString()
.toLowerCase() ??
'';

final String city =
university['city']
?.toString()
.toLowerCase() ??
'';

final String district =
university['district']
?.toString()
.toLowerCase() ??
'';

return name.contains(search) ||
city.contains(search) ||
district.contains(search);
},
).toList();
});
}

Future<void>
_showUniversityDialog({
Map<String, dynamic>? university,
}) async {
if (_isProcessing) {
return;
}

final bool isEditing =
university != null;

final TextEditingController
nameController =
TextEditingController(
text: university?['name']
?.toString() ??
'',
);

final TextEditingController
cityController =
TextEditingController(
text: university?['city']
?.toString() ??
'',
);

final TextEditingController
districtController =
TextEditingController(
text: university?['district']
?.toString() ??
'',
);

String selectedType =
university?['type']
?.toString() ??
'';

if (![
'',
'state',
'private',
'foundation',
'other',
].contains(selectedType)) {
selectedType = '';
}

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
? 'Üniversiteyi Düzenle'
: 'Yeni Üniversite',
),
content:
SingleChildScrollView(
child: SizedBox(
width: 440,
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
TextField(
controller:
nameController,
autofocus: true,
maxLength: 200,
textCapitalization:
TextCapitalization
.words,
decoration:
const InputDecoration(
labelText:
'Üniversite adı',
hintText:
'Örneğin: Mersin Üniversitesi',
prefixIcon: Icon(
Icons
.account_balance_outlined,
),
),
),

const SizedBox(
height: 10,
),

TextField(
controller:
cityController,
maxLength: 100,
textCapitalization:
TextCapitalization
.words,
decoration:
const InputDecoration(
labelText:
'Şehir',
hintText:
'Örneğin: Mersin',
prefixIcon: Icon(
Icons
.location_city_outlined,
),
),
),

const SizedBox(
height: 10,
),

TextField(
controller:
districtController,
maxLength: 100,
textCapitalization:
TextCapitalization
.words,
decoration:
const InputDecoration(
labelText:
'İlçe',
hintText:
'Örneğin: Yenişehir',
prefixIcon: Icon(
Icons
.place_outlined,
),
),
),

const SizedBox(
height: 10,
),

DropdownButtonFormField<
String>(
initialValue:
selectedType,
decoration:
const InputDecoration(
labelText:
'Üniversite türü',
prefixIcon: Icon(
Icons
.school_outlined,
),
),
items: const [
DropdownMenuItem<
String>(
value: '',
child: Text(
'Belirtilmedi',
),
),
DropdownMenuItem<
String>(
value: 'state',
child: Text(
'Devlet',
),
),
DropdownMenuItem<
String>(
value: 'private',
child: Text(
'Özel',
),
),
DropdownMenuItem<
String>(
value:
'foundation',
child: Text(
'Vakıf',
),
),
DropdownMenuItem<
String>(
value: 'other',
child: Text(
'Diğer',
),
),
],
onChanged: (
String? value,
) {
dialogSetState(() {
selectedType =
value ?? '';
});
},
),
],
),
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

final String city =
cityController.text
.trim();

if (name.length < 2 ||
city.length < 2) {
return;
}

Navigator.of(
dialogContext,
).pop(
<String, dynamic>{
'name': name,
'city': city,
'district':
districtController
.text
.trim(),
'type':
selectedType,
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

nameController.dispose();
cityController.dispose();
districtController.dispose();

if (
formData == null ||
!mounted
) {
return;
}

final String name =
formData['name']?.toString() ??
'';

final String city =
formData['city']?.toString() ??
'';

final String district =
formData['district']
?.toString() ??
'';

final String type =
formData['type']?.toString() ??
'';

if (
name.length < 2 ||
name.length > 200
) {
_showMessage(
'Üniversite adı 2-200 karakter arasında olmalıdır.',
success: false,
);

return;
}

if (
city.length < 2 ||
city.length > 100
) {
_showMessage(
'Şehir bilgisi 2-100 karakter arasında olmalıdır.',
success: false,
);

return;
}

if (district.length > 100) {
_showMessage(
'İlçe bilgisi en fazla 100 karakter olabilir.',
success: false,
);

return;
}

setState(() {
_isProcessing = true;
});

final Map<String, dynamic> result;

if (isEditing) {
final int? universityId =
int.tryParse(
university['id']?.toString() ??
'',
);

if (universityId == null) {
setState(() {
_isProcessing = false;
});

_showMessage(
'Üniversite kimliği alınamadı.',
success: false,
);

return;
}

result =
await _apiService
.updateUniversity(
universityId: universityId,
name: name,
city: city,
district: district,
type: type,
);
} else {
result =
await _apiService
.addUniversity(
name: name,
city: city,
district: district,
type: type,
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
'Üniversite kaydedilemedi.',
success: false,
);

return;
}

_showMessage(
result['message']
?.toString() ??
'Üniversite kaydedildi.',
success: true,
);

await _loadUniversities();
}
Future<void> _deleteUniversity(
Map<String, dynamic> university,
) async {
if (_isProcessing) {
return;
}

final int? universityId =
int.tryParse(
university['id']?.toString() ?? '',
);

if (universityId == null) {
_showMessage(
'Üniversite kimliği alınamadı.',
success: false,
);
return;
}

final String universityName =
university['name']?.toString() ??
'Üniversite';

final int noteCount =
int.tryParse(
university['note_count']
?.toString() ??
'0',
) ??
0;

if (noteCount > 0) {
_showMessage(
'Bu üniversiteye bağlı $noteCount not bulunduğu için silinemez.',
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
'Üniversiteyi Sil',
),
content: Text(
'"$universityName" kaydını kalıcı olarak silmek istediğinize emin misiniz?',
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
await _apiService
.deleteUniversity(
universityId,
);

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
'Üniversite silinemedi.',
success: false,
);
return;
}

_showMessage(
result['message']
?.toString() ??
'Üniversite silindi.',
success: true,
);

await _loadUniversities();
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
onRefresh: _loadUniversities,
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
_filteredUniversities.isEmpty
)
_buildEmpty()
else
..._filteredUniversities.map(
_buildUniversityCard,
),
],
),
);
}

Widget _buildHeader() {
final int totalNoteCount =
_universities.fold<int>(
0,
(
int total,
Map<String, dynamic> university,
) {
final int noteCount =
int.tryParse(
university['note_count']
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
Icons
.account_balance_rounded,
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
'${_universities.length} üniversite',
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
'Toplam $totalNoteCount not üniversitelere bağlı.',
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
_showUniversityDialog();
},
icon: const Icon(
Icons.add_rounded,
),
label: const Text(
'Yeni Üniversite',
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
'Üniversite, şehir veya ilçe ara...',
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
Widget _buildUniversityCard(
    Map<String, dynamic> university,
    ) {
  final String name =
      university['name']
          ?.toString() ??
          'İsimsiz üniversite';

  final String city =
      university['city']
          ?.toString() ??
          '-';

  final String district =
      university['district']
          ?.toString() ??
          '';

  final String type =
      university['type']
          ?.toString() ??
          '';

  final int noteCount =
      int.tryParse(
        university['note_count']
            ?.toString() ??
            '0',
      ) ??
          0;

  return Container(
    margin:
    const EdgeInsets.only(
      bottom: 11,
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
        color:
        AdminColors.border,
      ),
    ),
    child: Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
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
            Icons
                .account_balance_rounded,
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

              const SizedBox(
                height: 6,
              ),

              Text(
                district.isEmpty
                    ? city
                    : '$district / $city',
                style:
                const TextStyle(
                  color: AdminColors
                      .textSecondary,
                  fontSize: 11,
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
                    _typeLabel(type),
                    Icons.school_rounded,
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
          onPressed:
          _isProcessing
              ? null
              : () {
            _showUniversityDialog(
              university:
              university,
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
            _deleteUniversity(
              university,
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
      color: AdminColors
          .surfaceSecondary,
      borderRadius:
      BorderRadius.circular(
        10,
      ),
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

String _typeLabel(
    String type,
    ) {
  switch (type) {
    case 'state':
      return 'Devlet';

    case 'private':
      return 'Özel';

    case 'foundation':
      return 'Vakıf';

    case 'other':
      return 'Diğer';

    default:
      return 'Belirtilmedi';
  }
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
            _loadUniversities,
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
          Icons
              .account_balance_outlined,
          color:
          AdminColors.textMuted,
          size: 52,
        ),

        SizedBox(
          height: 12,
        ),

        Text(
          'Gösterilecek üniversite bulunamadı.',
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