import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';

// PLATFORM FİNANSLARI
import 'platform_wallet_screen.dart';

import 'dashboard_screen.dart';
import 'pending_notes_screen.dart';
import 'categories_screen.dart';
import 'reports_screen.dart';
import 'reviews_screen.dart';
import 'users_screen.dart';
import 'withdrawals_screen.dart';
import 'universities_screen.dart';
import 'courses_screen.dart';
import 'sales_screen.dart';
import 'notifications_screen.dart';
import 'admin_logs_screen.dart';
import 'system_settings_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<AdminMainScreen> createState() =>
      _AdminMainScreenState();
}

class _AdminMainScreenState
    extends State<AdminMainScreen> {
final AdminApiService _apiService =
AdminApiService();

int _selectedIndex = 0;

late final List<_AdminMenuItem>
_menuItems;

@override
void initState() {
super.initState();

_menuItems = <_AdminMenuItem>[
// =====================================================
// DASHBOARD
// =====================================================

_AdminMenuItem(
title: 'Dashboard',
icon: Icons.dashboard_outlined,
selectedIcon:
Icons.dashboard_rounded,
screen: DashboardScreen(
adminId: widget.adminId,
),
),

// =====================================================
// NOT YÖNETİMİ
// =====================================================

_AdminMenuItem(
title: 'Not Yönetimi',
icon:
Icons.description_outlined,
selectedIcon:
Icons.description_rounded,
screen: PendingNotesScreen(
adminId: widget.adminId,
),
),

// =====================================================
// KULLANICILAR
// =====================================================

_AdminMenuItem(
title: 'Kullanıcılar',
icon:
Icons.people_outline_rounded,
selectedIcon:
Icons.people_rounded,
screen: UsersScreen(
adminId: widget.adminId,
),
),

// =====================================================
// KULLANICI PARA ÇEKME TALEPLERİ
// =====================================================

_AdminMenuItem(
title: 'Para Çekme',
icon: Icons
.account_balance_wallet_outlined,
selectedIcon: Icons
.account_balance_wallet_rounded,
screen: WithdrawalsScreen(
adminId: widget.adminId,
),
),

// =====================================================
// PLATFORM FİNANSLARI
// SENİN %20 KOMİSYON GELİRİN
// =====================================================

_AdminMenuItem(
title: 'Platform Finansları',
icon:
Icons.payments_outlined,
selectedIcon:
Icons.payments_rounded,
screen:
const PlatformWalletScreen(),
),

// =====================================================
// ŞİKAYETLER
// =====================================================

_AdminMenuItem(
title: 'Şikâyetler',
icon:
Icons.flag_outlined,
selectedIcon:
Icons.flag_rounded,
screen: ReportsScreen(
adminId: widget.adminId,
),
),

// =====================================================
// YORUMLAR
// =====================================================

_AdminMenuItem(
title: 'Yorumlar',
icon:
Icons.rate_review_outlined,
selectedIcon:
Icons.rate_review_rounded,
screen: ReviewsScreen(
adminId: widget.adminId,
),
),

// =====================================================
// SATIŞLAR
// =====================================================

_AdminMenuItem(
title: 'Satışlar',
icon:
Icons.shopping_cart_outlined,
selectedIcon:
Icons.shopping_cart_rounded,
screen: SalesScreen(
adminId: widget.adminId,
),
),

// =====================================================
// KATEGORİLER
// =====================================================

_AdminMenuItem(
title: 'Kategoriler',
icon:
Icons.category_outlined,
selectedIcon:
Icons.category_rounded,
screen: CategoriesScreen(
adminId: widget.adminId,
),
),

// =====================================================
// ÜNİVERSİTELER
// =====================================================

_AdminMenuItem(
title: 'Üniversiteler',
icon:
Icons.account_balance_outlined,
selectedIcon:
Icons.account_balance_rounded,
screen: UniversitiesScreen(
adminId: widget.adminId,
),
),

// =====================================================
// DERSLER
// =====================================================

_AdminMenuItem(
title: 'Dersler',
icon:
Icons.menu_book_outlined,
selectedIcon:
Icons.menu_book_rounded,
screen: CoursesScreen(
adminId: widget.adminId,
),
),

// =====================================================
// BİLDİRİMLER
// =====================================================

_AdminMenuItem(
title: 'Bildirimler',
icon:
Icons.notifications_outlined,
selectedIcon:
Icons.notifications_rounded,
screen: NotificationsScreen(
adminId: widget.adminId,
),
),

// =====================================================
// SİSTEM AYARLARI
// =====================================================

_AdminMenuItem(
title: 'Sistem Ayarları',
icon:
Icons.settings_outlined,
selectedIcon:
Icons.settings_rounded,
screen: SystemSettingsScreen(
adminId: widget.adminId,
),
),

// =====================================================
// ADMIN LOGLARI
// =====================================================

_AdminMenuItem(
title: 'Admin Logları',
icon:
Icons.history_outlined,
selectedIcon:
Icons.history_rounded,
screen: AdminLogsScreen(
adminId: widget.adminId,
),
),
];
}
String get _pageTitle {
return _menuItems[_selectedIndex]
.title;
}

void _changePage(
int index, {
bool closeDrawer = false,
}) {
if (_selectedIndex != index) {
setState(() {
_selectedIndex = index;
});
}

if (
closeDrawer &&
Navigator.of(context).canPop()
) {
Navigator.of(context).pop();
}
}

Future<void> _logout() async {
await _apiService.logout();

if (!mounted) {
return;
}

Navigator.of(context)
.pushNamedAndRemoveUntil(
'/',
(
Route<dynamic> route,
) =>
false,
);
}

@override
Widget build(
BuildContext context,
) {
final bool useNavigationRail =
MediaQuery.sizeOf(context)
.width >=
900;

return Scaffold(
backgroundColor:
AdminColors.background,

appBar: AppBar(
title: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
_pageTitle,
),

const SizedBox(
height: 2,
),

Text(
widget.adminId,
style: const TextStyle(
color:
AdminColors.textMuted,
fontSize: 11,
fontWeight:
FontWeight.w400,
),
),
],
),

actions: [
PopupMenuButton<String>(
tooltip:
'Admin menüsü',

icon: const Icon(
Icons
.account_circle_rounded,
),

color:
AdminColors
.surfaceSecondary,

onSelected: (
String value,
) {
if (
value ==
'logout'
) {
_showLogoutDialog();
}
},

itemBuilder: (
BuildContext context,
) {
return <
PopupMenuEntry<
String>>[
PopupMenuItem<String>(
enabled: false,

child: Column(
crossAxisAlignment:
CrossAxisAlignment
.start,

children: [
const Text(
'Admin hesabı',
style:
TextStyle(
color:
AdminColors
.textMuted,
fontSize:
11,
),
),

const SizedBox(
height: 4,
),

Text(
widget.adminId,
style:
const TextStyle(
color:
AdminColors
.textPrimary,
fontWeight:
FontWeight
.w600,
),
),
],
),
),

const PopupMenuDivider(),

const PopupMenuItem<
String>(
value:
'logout',

child: Row(
children: [
Icon(
Icons
.logout_rounded,
color:
AdminColors
.error,
size: 20,
),

SizedBox(
width: 10,
),

Text(
'Çıkış Yap',
style:
TextStyle(
color:
AdminColors
.error,
),
),
],
),
),
];
},
),

const SizedBox(
width: 6,
),
],
),

drawer:
useNavigationRail
? null
: Drawer(
backgroundColor:
AdminColors
.surface,
child:
_buildDrawer(),
),

body:
useNavigationRail
? Row(
children: [
_buildNavigationRail(),

const VerticalDivider(
width: 1,
thickness: 1,
color:
AdminColors
.border,
),

Expanded(
child:
IndexedStack(
index:
_selectedIndex,
children:
_menuItems
.map(
(
_AdminMenuItem
item,
) =>
item.screen,
)
.toList(),
),
),
],
)
: IndexedStack(
index:
_selectedIndex,
children:
_menuItems
.map(
(
_AdminMenuItem
item,
) =>
item.screen,
)
.toList(),
),
);
}
Widget _buildNavigationRail() {
return Container(
width: 245,
color: AdminColors.surface,
child: SafeArea(
top: false,
child: Column(
children: [
const SizedBox(
height: 12,
),

_buildAdminHeader(),

const SizedBox(
height: 12,
),

Expanded(
child: ListView.builder(
padding:
const EdgeInsets
.symmetric(
horizontal: 10,
),
itemCount:
_menuItems.length,
itemBuilder: (
BuildContext context,
int index,
) {
return _buildMenuTile(
index,
closeDrawer: false,
);
},
),
),

const Divider(
color: AdminColors.border,
),

ListTile(
onTap:
_showLogoutDialog,
leading:
const Icon(
Icons.logout_rounded,
color:
AdminColors.error,
),
title:
const Text(
'Çıkış Yap',
style:
TextStyle(
color:
AdminColors.error,
fontWeight:
FontWeight.w600,
),
),
),

const SizedBox(
height: 10,
),
],
),
),
);
}

Widget _buildDrawer() {
return SafeArea(
child: Column(
children: [
const SizedBox(
height: 12,
),

_buildAdminHeader(),

const SizedBox(
height: 10,
),

Expanded(
child: ListView.builder(
padding:
const EdgeInsets
.symmetric(
horizontal: 10,
),
itemCount:
_menuItems.length,
itemBuilder: (
BuildContext context,
int index,
) {
return _buildMenuTile(
index,
closeDrawer: true,
);
},
),
),

const Divider(
color: AdminColors.border,
),

ListTile(
onTap: () {
Navigator.of(context)
.pop();

_showLogoutDialog();
},
leading:
const Icon(
Icons.logout_rounded,
color:
AdminColors.error,
),
title:
const Text(
'Çıkış Yap',
style:
TextStyle(
color:
AdminColors.error,
fontWeight:
FontWeight.w600,
),
),
),

const SizedBox(
height: 10,
),
],
),
);
}
Widget _buildAdminHeader() {
  return Padding(
    padding:
    const EdgeInsets.symmetric(
      horizontal: 16,
    ),
    child: Row(
      children: [
        Container(
          width: 47,
          height: 47,
          decoration:
          BoxDecoration(
            color: AdminColors.primary
                .withValues(
              alpha: 0.15,
            ),
            borderRadius:
            BorderRadius.circular(
              15,
            ),
          ),
          child:
          const Icon(
            Icons
                .admin_panel_settings_rounded,
            color:
            AdminColors.primary,
            size: 27,
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
              const Text(
                'Cadion Admin',
                style:
                TextStyle(
                  color:
                  AdminColors
                      .textPrimary,
                  fontSize:
                  16,
                  fontWeight:
                  FontWeight
                      .w800,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                widget.adminId,
                maxLines: 1,
                overflow:
                TextOverflow
                    .ellipsis,
                style:
                const TextStyle(
                  color:
                  AdminColors
                      .textMuted,
                  fontSize:
                  11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildMenuTile(
    int index, {
      required bool closeDrawer,
    }) {
  final _AdminMenuItem item =
  _menuItems[index];

  final bool selected =
      index ==
          _selectedIndex;

  return Padding(
    padding:
    const EdgeInsets.only(
      bottom: 5,
    ),
    child: Material(
      color:
      selected
          ? AdminColors.primary
          .withValues(
        alpha: 0.15,
      )
          : Colors.transparent,
      borderRadius:
      BorderRadius.circular(
        13,
      ),
      child: ListTile(
        selected:
        selected,

        onTap: () {
          _changePage(
            index,
            closeDrawer:
            closeDrawer,
          );
        },

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            13,
          ),
        ),

        leading:
        Icon(
          selected
              ? item.selectedIcon
              : item.icon,
          color:
          selected
              ? AdminColors.primary
              : AdminColors
              .textSecondary,
        ),

        title:
        Text(
          item.title,
          style:
          TextStyle(
            color:
            selected
                ? AdminColors.primary
                : AdminColors
                .textPrimary,
            fontSize:
            13,
            fontWeight:
            selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

Future<void>
_showLogoutDialog() async {
  final bool? shouldLogout =
  await showDialog<bool>(
    context:
    context,

    builder: (
        BuildContext
        dialogContext,
        ) {
      return AlertDialog(
        backgroundColor:
        AdminColors.surface,

        title:
        const Text(
          'Çıkış yapılsın mı?',
        ),

        content:
        const Text(
          'Admin panelinden çıkış yapacaksınız.',
          style:
          TextStyle(
            color:
            AdminColors
                .textSecondary,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(
                false,
              );
            },
            child:
            const Text(
              'Vazgeç',
            ),
          ),

          FilledButton(
            style:
            FilledButton
                .styleFrom(
              backgroundColor:
              AdminColors
                  .error,
            ),

            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(
                true,
              );
            },

            child:
            const Text(
              'Çıkış Yap',
            ),
          ),
        ],
      );
    },
  );

  if (
  shouldLogout ==
      true &&
      mounted
  ) {
    await _logout();
  }
}
}

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}

class _ComingSoonScreen
    extends StatelessWidget {
  const _ComingSoonScreen({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child:
      SingleChildScrollView(
        padding:
        const EdgeInsets
            .all(
          30,
        ),

        child:
        Container(
          constraints:
          const BoxConstraints(
            maxWidth: 500,
          ),

          padding:
          const EdgeInsets
              .all(
            30,
          ),

          decoration:
          BoxDecoration(
            color:
            AdminColors.surface,

            borderRadius:
            BorderRadius.circular(
              24,
            ),

            border:
            Border.all(
              color:
              AdminColors.border,
            ),
          ),

          child:
          Column(
            mainAxisSize:
            MainAxisSize.min,

            children: [
              Container(
                width: 78,
                height: 78,

                decoration:
                BoxDecoration(
                  color:
                  AdminColors.primary
                      .withValues(
                    alpha: 0.14,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    23,
                  ),
                ),

                child:
                Icon(
                  icon,
                  color:
                  AdminColors.primary,
                  size: 40,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                title,
                textAlign:
                TextAlign.center,

                style:
                const TextStyle(
                  color:
                  AdminColors
                      .textPrimary,
                  fontSize:
                  21,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                description,
                textAlign:
                TextAlign.center,

                style:
                const TextStyle(
                  color:
                  AdminColors
                      .textSecondary,
                  fontSize:
                  13,
                  height:
                  1.5,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'Bu bölüm sıradaki adımlarda aktif hâle getirilecek.',
                textAlign:
                TextAlign.center,

                style:
                TextStyle(
                  color:
                  AdminColors
                      .textMuted,
                  fontSize:
                  11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}