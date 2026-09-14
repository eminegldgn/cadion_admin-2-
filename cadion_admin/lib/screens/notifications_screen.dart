import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../services/admin_api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
final AdminApiService _apiService =
AdminApiService();

final TextEditingController
_searchController =
TextEditingController();

final TextEditingController
_userIdController =
TextEditingController();

final TextEditingController
_titleController =
TextEditingController();

final TextEditingController
_messageController =
TextEditingController();

bool _isLoading = true;
bool _isSending = false;
bool _isDeleting = false;
bool _sendToAll = true;

String? _errorMessage;

List<Map<String, dynamic>>
_notifications =
<Map<String, dynamic>>[];

@override
void initState() {
super.initState();

_searchController.addListener(
_filterLocally,
);

_loadNotifications();
}

@override
void dispose() {
_searchController.removeListener(
_filterLocally,
);

_searchController.dispose();
_userIdController.dispose();
_titleController.dispose();
_messageController.dispose();

super.dispose();
}

Future<void>
_loadNotifications() async {
if (!mounted) {
return;
}

setState(() {
_isLoading = true;
_errorMessage = null;
});

final Map<String, dynamic> result =
await _apiService
.getAdminNotifications(
search:
_searchController.text.trim(),
page: 1,
limit: 100,
);

if (!mounted) {
return;
}

if (result['success'] != true) {
setState(() {
_isLoading = false;

_errorMessage =
result['error']
?.toString() ??
'Bildirim geçmişi getirilemedi.';
});

return;
}

final List<Map<String, dynamic>>
parsedNotifications =
<Map<String, dynamic>>[];

final dynamic notificationsValue =
result['notifications'];

if (notificationsValue is List) {
for (
final dynamic item
in notificationsValue
) {
if (item is Map) {
parsedNotifications.add(
Map<String, dynamic>.from(
item,
),
);
}
}
}

setState(() {
_isLoading = false;

_notifications =
parsedNotifications;
});
}

void _filterLocally() {
if (!mounted) {
return;
}

setState(() {});
}

List<Map<String, dynamic>>
get _filteredNotifications {
final String search =
_searchController.text
.trim()
.toLowerCase();

if (search.isEmpty) {
return _notifications;
}

return _notifications.where(
(
Map<String, dynamic>
notification,
) {
final String userId =
notification['user_id']
?.toString()
.toLowerCase() ??
'';

final String title =
notification['title']
?.toString()
.toLowerCase() ??
'';

final String message =
notification['message']
?.toString()
.toLowerCase() ??
'';

return userId.contains(search) ||
title.contains(search) ||
message.contains(search);
},
).toList();
}

Future<void> _sendNotification() async {
if (_isSending) {
return;
}

final String userId =
_userIdController.text.trim();

final String title =
_titleController.text.trim();

final String message =
_messageController.text.trim();

if (!_sendToAll && userId.isEmpty) {
_showMessage(
'Kullanıcı kimliği zorunludur.',
success: false,
);

return;
}

if (
title.length < 2 ||
title.length > 150
) {
_showMessage(
'Başlık 2-150 karakter arasında olmalıdır.',
success: false,
);

return;
}

if (
message.length < 2 ||
message.length > 3000
) {
_showMessage(
'Mesaj 2-3000 karakter arasında olmalıdır.',
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
title: Text(
_sendToAll
? 'Toplu Bildirim Gönder'
: 'Kullanıcıya Bildirim Gönder',
),
content: Text(
_sendToAll
? 'Bu bildirim tüm kullanıcılara gönderilecek. Devam edilsin mi?'
: '$userId kullanıcısına bildirim gönderilecek. Devam edilsin mi?',
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
onPressed: () {
Navigator.of(
dialogContext,
).pop(true);
},
child: const Text(
'Gönder',
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
_isSending = true;
});

final Map<String, dynamic> result;

if (_sendToAll) {
result =
await _apiService
.sendNotificationToAll(
title: title,
message: message,
);
} else {
result =
await _apiService
.sendNotificationToUser(
userId: userId,
title: title,
message: message,
);
}

if (!mounted) {
return;
}

setState(() {
_isSending = false;
});

if (result['success'] != true) {
_showMessage(
result['error']
?.toString() ??
'Bildirim gönderilemedi.',
success: false,
);

return;
}

_titleController.clear();
_messageController.clear();

if (!_sendToAll) {
_userIdController.clear();
}

_showMessage(
result['message']
?.toString() ??
'Bildirim gönderildi.',
success: true,
);

await _loadNotifications();
}
Future<void> _deleteNotification(
int notificationId,
) async {
if (_isDeleting) {
return;
}

final bool? confirmed =
await showDialog<bool>(
context: context,
builder: (context) {
return AlertDialog(
backgroundColor:
AdminColors.surface,
title: const Text(
'Bildirimi Sil',
),
content: const Text(
'Bu bildirim kalıcı olarak silinecek.',
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(
context,
false,
);
},
child: const Text(
'Vazgeç',
),
),
FilledButton(
onPressed: () {
Navigator.pop(
context,
true,
);
},
child: const Text(
'Sil',
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
_isDeleting = true;
});

final result =
await _apiService
.deleteAdminNotification(
notificationId,
);

if (!mounted) {
return;
}

setState(() {
_isDeleting = false;
});

if (result['success'] != true) {
_showMessage(
result['error'] ??
'Bildirim silinemedi.',
success: false,
);
return;
}

_showMessage(
'Bildirim silindi.',
);

_loadNotifications();
}

void _showMessage(
String text, {
bool success = true,
}) {
ScaffoldMessenger.of(context)
.showSnackBar(
SnackBar(
content: Text(text),
backgroundColor: success
? Colors.green
: Colors.red,
),
);
}
@override
Widget build(
BuildContext context,
) {
return RefreshIndicator(
onRefresh:
_loadNotifications,
child: ListView(
padding:
const EdgeInsets.all(18),
children: [

_buildSendCard(),

const SizedBox(
height: 18,
),

_buildSearch(),

const SizedBox(
height: 18,
),

if (_isLoading)
const Center(
child:
CircularProgressIndicator(),
)
else if (_errorMessage !=
null)
Center(
child: Text(
_errorMessage!,
),
)
else
..._filteredNotifications
.map(
_buildNotificationCard,
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
const InputDecoration(
hintText:
'Bildirim ara...',
prefixIcon:
Icon(Icons.search),
),
);
}

Widget _buildSendCard() {
return Card(
child: Padding(
padding:
const EdgeInsets.all(16),
child: Column(
children: [

SwitchListTile(
value: _sendToAll,
title: const Text(
'Tüm Kullanıcılara Gönder',
),
onChanged: (value) {
setState(() {
_sendToAll =
value;
});
},
),

if (!_sendToAll)
TextField(
controller:
_userIdController,
decoration:
const InputDecoration(
labelText:
'Kullanıcı ID',
),
),

const SizedBox(
height: 12,
),

TextField(
controller:
_titleController,
decoration:
const InputDecoration(
labelText:
'Başlık',
),
),

const SizedBox(
height: 12,
),

TextField(
controller:
_messageController,
maxLines: 5,
decoration:
const InputDecoration(
labelText:
'Mesaj',
),
),

const SizedBox(
height: 18,
),

FilledButton.icon(
onPressed: _isSending
? null
: _sendNotification,
icon:
const Icon(Icons.send),
label: Text(
_sendToAll
? 'Tümüne Gönder'
: 'Gönder',
),
),
],
),
),
);
}

Widget _buildNotificationCard(
Map<String, dynamic>
notification,
) {
return Card(
margin:
const EdgeInsets.only(
bottom: 12,
),
child: ListTile(
title: Text(
notification['title']
?.toString() ??
'',
),
subtitle: Text(
notification['message']
?.toString() ??
'',
),
trailing: IconButton(
icon: const Icon(
Icons.delete,
color: Colors.red,
),
onPressed: () {
_deleteNotification(
int.parse(
notification['id']
.toString(),
),
);
},
),
),
);
}
}