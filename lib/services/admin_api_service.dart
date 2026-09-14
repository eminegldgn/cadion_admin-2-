import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminApiService {
  AdminApiService({
    String? adminId,
  });

  // Eski ekranların AdminApiService(adminId: ...) kullanımı
  // şimdilik hata vermesin diye adminId parametresi bırakıldı.
  // Artık yetkilendirme Admin ID ile değil JWT token ile yapılır.

  static const String _tokenKey =
      'cadion_admin_token';

  static const String _adminIdKey =
      'cadion_admin_id';

  static String? _cachedToken;

  // =======================================================
  // API ADRESİ
  // =======================================================

  static String get baseUrl {
    if (kIsWeb) {
      return 'https://evrak-backend-production.up.railway.app';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      // Android emülatöründen bilgisayarın localhost'una erişim
        return 'https://evrak-backend-production.up.railway.app';

      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      return 'https://evrak-backend-production.up.railway.app';

      case TargetPlatform.iOS:
      // iOS simülatörü
        return 'https://evrak-backend-production.up.railway.app';

      default:
        return 'https://evrak-backend-production.up.railway.app';
    }
  }

  // =======================================================
  // OTURUM VE TOKEN İŞLEMLERİ
  // =======================================================

  Future<String?> getToken() async {
    if (
    _cachedToken != null &&
        _cachedToken!.trim().isNotEmpty
    ) {
      return _cachedToken;
    }

    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    final String? token =
    preferences.getString(_tokenKey);

    if (
    token != null &&
        token.trim().isNotEmpty
    ) {
      _cachedToken = token;
      return token;
    }

    return null;
  }

  Future<String?> getSavedAdminId() async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    return preferences.getString(
      _adminIdKey,
    );
  }

  Future<bool> hasSavedSession() async {
    final String? token =
    await getToken();

    return token != null &&
        token.trim().isNotEmpty;
  }

  Future<void> saveSession({
    required String token,
    required String adminId,
  }) async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    _cachedToken = token;

    await preferences.setString(
      _tokenKey,
      token,
    );

    await preferences.setString(
      _adminIdKey,
      adminId,
    );
  }

  Future<void> logout() async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    _cachedToken = null;

    await preferences.remove(
      _tokenKey,
    );

    await preferences.remove(
      _adminIdKey,
    );
  }

  // =======================================================
  // HEADER'LAR
  // =======================================================

  Map<String, String> get _publicHeaders {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, String>>
  _authorizedHeaders() async {
    final String? token =
    await getToken();

    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (
      token != null &&
          token.trim().isNotEmpty
      )
        'Authorization':
        'Bearer $token',
    };
  }

  // =======================================================
  // ADMIN GİRİŞİ
  // =======================================================

  Future<Map<String, dynamic>> login({
    required String adminId,
    required String password,
  }) async {
    final Map<String, dynamic> result =
    await _post(
      '/api/admin/login',
      authorized: false,
      body: <String, dynamic>{
        'admin_id': adminId.trim(),
        'password': password,
      },
    );

    if (result['success'] == true) {
      final String token =
          result['token']?.toString() ?? '';

      final dynamic adminValue =
      result['admin'];

      String returnedAdminId =
      adminId.trim();

      if (adminValue is Map) {
        final Map<String, dynamic> admin =
        Map<String, dynamic>.from(
          adminValue,
        );

        returnedAdminId =
            admin['id']?.toString() ??
                returnedAdminId;
      }

      if (token.isEmpty) {
        return <String, dynamic>{
          'success': false,
          'error':
          'Sunucu oturum anahtarı göndermedi.',
        };
      }

      await saveSession(
        token: token,
        adminId: returnedAdminId,
      );
    }

    return result;
  }

  Future<Map<String, dynamic>>
  checkAdmin() async {
    final Map<String, dynamic> result =
    await _get(
      '/api/admin/check',
    );

    if (_isUnauthorized(result)) {
      await logout();
    }

    return result;
  }

  Future<Map<String, dynamic>>
  getProfile() async {
    return _get(
      '/api/admin/profile',
    );
  }

  Future<Map<String, dynamic>>
  changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _post(
      '/api/admin/change-password',
      body: <String, dynamic>{
        'current_password':
        currentPassword,
        'new_password':
        newPassword,
      },
    );
  }

  // =======================================================
  // DASHBOARD
  // =======================================================

  Future<Map<String, dynamic>>
  getDashboard() async {
    return _get(
      '/api/admin/dashboard',
    );
  }

  Future<Map<String, dynamic>>
  getSalesStatistics({
    int days = 30,
  }) async {
    return _get(
      '/api/admin/statistics/sales'
          '?days=$days',
    );
  }
// =======================================================
// PLATFORM CÜZDANI
// =======================================================

  Future<Map<String, dynamic>>
  getPlatformWallet() async {
    return _get(
      '/api/admin/platform-wallet',
    );
  }

// =======================================================
// PLATFORM PARA ÇEKME
// =======================================================

  Future<Map<String, dynamic>>
  withdrawPlatformMoney({
    required double amount,
    required String iban,
  }) async {
    return _post(
      '/api/admin/platform-withdraw',
      body: <String, dynamic>{
        'amount': amount,
        'iban': iban.trim(),
      },
    );
  }
  // =======================================================
  // NOT YÖNETİMİ
  // =======================================================

  Future<Map<String, dynamic>>
  getPendingNotes() async {
    return _get(
      '/api/admin/notes/pending',
    );
  }

  Future<Map<String, dynamic>>
  getNotes({
    String status = '',
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, String> query =
    <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status.trim().isNotEmpty) {
      query['status'] =
          status.trim();
    }

    if (search.trim().isNotEmpty) {
      query['search'] =
          search.trim();
    }

    final String queryString =
        Uri(
          queryParameters: query,
        ).query;

    return _get(
      '/api/admin/notes?$queryString',
    );
  }

  Future<Map<String, dynamic>>
  getNoteDetail(
      int noteId,
      ) async {
    return _get(
      '/api/admin/notes/$noteId',
    );
  }

  Future<Map<String, dynamic>>
  approveNote(
      int noteId,
      ) async {
    return _post(
      '/api/admin/notes/$noteId/approve',
    );
  }

  Future<Map<String, dynamic>>
  rejectNote(
      int noteId, {
        String reason = '',
      }) async {
    return _post(
      '/api/admin/notes/$noteId/reject',
      body: <String, dynamic>{
        'rejection_reason':
        reason.trim(),
      },
    );
  }

  // =======================================================
  // KULLANICI YÖNETİMİ
  // =======================================================

  Future<Map<String, dynamic>>
  getUsers({
    String search = '',
    String role = '',
    bool? banned,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, String> query =
    <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search.trim().isNotEmpty) {
      query['search'] =
          search.trim();
    }

    if (role.trim().isNotEmpty) {
      query['role'] =
          role.trim();
    }

    if (banned != null) {
      query['banned'] =
          banned.toString();
    }

    final String queryString =
        Uri(
          queryParameters: query,
        ).query;

    return _get(
      '/api/admin/users?$queryString',
    );
  }

  Future<Map<String, dynamic>>
  getUserDetail(
      String userId,
      ) async {
    return _get(
      '/api/admin/users/'
          '${Uri.encodeComponent(userId)}',
    );
  }

  Future<Map<String, dynamic>>
  banUser(
      String userId,
      ) async {
    return _post(
      '/api/admin/users/'
          '${Uri.encodeComponent(userId)}'
          '/ban',
    );
  }

  Future<Map<String, dynamic>>
  unbanUser(
      String userId,
      ) async {
    return _post(
      '/api/admin/users/'
          '${Uri.encodeComponent(userId)}'
          '/unban',
    );
  }

  Future<Map<String, dynamic>>
  changeUserRole({
    required String userId,
    required String role,
  }) async {
    return _post(
      '/api/admin/users/'
          '${Uri.encodeComponent(userId)}'
          '/role',
      body: <String, dynamic>{
        'role': role.trim(),
      },
    );
  }

  // =======================================================
  // PARA ÇEKME YÖNETİMİ
  // =======================================================

  Future<Map<String, dynamic>>
  getWithdrawals({
    String status = 'pending',
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, String> query =
    <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status.trim().isNotEmpty) {
      query['status'] =
          status.trim();
    }

    final String queryString =
        Uri(
          queryParameters: query,
        ).query;

    return _get(
      '/api/admin/withdrawals'
          '?$queryString',
    );
  }

  Future<Map<String, dynamic>>
  getWithdrawalDetail(
      int requestId,
      ) async {
    return _get(
      '/api/admin/withdrawals/'
          '$requestId',
    );
  }

  Future<Map<String, dynamic>>
  approveWithdrawal(
      int requestId,
      ) async {
    return _post(
      '/api/admin/withdrawals/'
          '$requestId/approve',
    );
  }

  Future<Map<String, dynamic>>
  rejectWithdrawal(
      int requestId, {
        String reason = '',
      }) async {
    return _post(
      '/api/admin/withdrawals/'
          '$requestId/reject',
      body: <String, dynamic>{
        'rejection_reason':
        reason.trim(),
      },
    );
  }

  // =======================================================
  // SATIN ALMALAR
  // =======================================================

  Future<Map<String, dynamic>>
  getPurchases({
    int page = 1,
    int limit = 20,
  }) async {
    return _get(
      '/api/admin/purchases'
          '?page=$page&limit=$limit',
    );
  }
// =======================================================
// ŞİKÂYET YÖNETİMİ
// =======================================================

  Future<Map<String, dynamic>> getReports({
    String status = '',
    String type = '',
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, String> query =
    <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }

    if (type.trim().isNotEmpty) {
      query['type'] = type.trim();
    }

    if (search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final String queryString = Uri(
      queryParameters: query,
    ).query;

    return _get(
      '/api/admin/reports?$queryString',
    );
  }

  Future<Map<String, dynamic>>
  getReportsSummary() async {
    return _get(
      '/api/admin/reports/summary',
    );
  }

  Future<Map<String, dynamic>>
  getReportDetail(
      int reportId,
      ) async {
    return _get(
      '/api/admin/reports/$reportId',
    );
  }

  Future<Map<String, dynamic>>
  updateReportStatus({
    required int reportId,
    required String status,
    String adminNote = '',
    bool removeNote = false,
    bool deleteReview = false,
  }) async {
    return _put(
      '/api/admin/reports/$reportId/status',
      body: <String, dynamic>{
        'status': status.trim(),
        'admin_note': adminNote.trim(),
        'remove_note': removeNote,
        'delete_review': deleteReview,
      },
    );
  }
  // =======================================================
// YORUM YÖNETİMİ
// =======================================================

  Future<Map<String, dynamic>>
  getAdminReviews({
    String search = '',
    int? rating,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, String> query =
    <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    if (
    rating != null &&
        rating >= 1 &&
        rating <= 5
    ) {
      query['rating'] =
          rating.toString();
    }

    final String queryString =
        Uri(
          queryParameters: query,
        ).query;

    return _get(
      '/api/admin/reviews?$queryString',
    );
  }

  Future<Map<String, dynamic>>
  getAdminReviewsSummary() async {
    return _get(
      '/api/admin/reviews/summary',
    );
  }

  Future<Map<String, dynamic>>
  getAdminReviewDetail(
      int reviewId,
      ) async {
    return _get(
      '/api/admin/reviews/$reviewId',
    );
  }

  Future<Map<String, dynamic>>
  deleteAdminReview({
    required int reviewId,
    String reason = '',
  }) async {
    return _deleteWithBody(
      '/api/admin/reviews/$reviewId',
      body: <String, dynamic>{
        'reason': reason.trim(),
      },
    );
  }
  // =======================================================
  // KATEGORİ YÖNETİMİ
  // =======================================================

  Future<Map<String, dynamic>>
  getCategories() async {
    return _get(
      '/api/admin/categories',
    );
  }
  Future<Map<String, dynamic>>
  addCategory(
      String name,
      ) async {
    return _post(
      '/api/admin/categories',
      body: <String, dynamic>{
        'name': name.trim(),
      },
    );
  }

  Future<Map<String, dynamic>>
  updateCategory({
    required int categoryId,
    required String name,
  }) async {
    return _put(
      '/api/admin/categories/'
          '$categoryId',
      body: <String, dynamic>{
        'name': name.trim(),
      },
    );
  }

  Future<Map<String, dynamic>>
  deleteCategory(
      int categoryId,
      ) async {
    return _delete(
      '/api/admin/categories/'
          '$categoryId',
    );
  }
// =======================================================
// ÜNİVERSİTE YÖNETİMİ
// =======================================================

  Future<Map<String, dynamic>>
  getUniversities() async {
    return _get(
      '/api/admin/universities',
    );
  }

  Future<Map<String, dynamic>>
  addUniversity({
    required String name,
    required String city,
    String district = '',
    String type = '',
  }) async {
    return _post(
      '/api/admin/universities',
      body: <String, dynamic>{
        'name': name.trim(),
        'city': city.trim(),
        'district': district.trim(),
        'type': type.trim(),
      },
    );
  }

  Future<Map<String, dynamic>>
  updateUniversity({
    required int universityId,
    required String name,
    required String city,
    String district = '',
    String type = '',
  }) async {
    return _put(
      '/api/admin/universities/$universityId',
      body: <String, dynamic>{
        'name': name.trim(),
        'city': city.trim(),
        'district': district.trim(),
        'type': type.trim(),
      },
    );
  }

  Future<Map<String, dynamic>>
  deleteUniversity(
      int universityId,
      ) async {
    return _delete(
      '/api/admin/universities/$universityId',
    );
  }
  // =======================================================
// DERS YÖNETİMİ
// =======================================================

  Future<Map<String, dynamic>> getCourses({
    String search = '',
  }) async {
    final String query = search.trim().isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search.trim())}';

    return _get(
      '/api/admin/courses$query',
    );
  }

  Future<Map<String, dynamic>> addCourse({
    required String name,
    required int universityId,
  }) async {
    return _post(
      '/api/admin/courses',
      body: {
        'name': name,
        'university_id': universityId,
      },
    );
  }

  Future<Map<String, dynamic>> updateCourse({
    required int courseId,
    required String name,
    required int universityId,
  }) async {
    return _put(
      '/api/admin/courses/$courseId',
      body: {
        'name': name,
        'university_id': universityId,
      },
    );
  }

  Future<Map<String, dynamic>> deleteCourse(
      int courseId,
      ) async {
    return _delete(
      '/api/admin/courses/$courseId',
    );
  }
  // =======================================================
// BİLDİRİM YÖNETİMİ
// =======================================================

  Future<Map<String, dynamic>>
  getAdminNotifications({
    String search = '',
    int page = 1,
    int limit = 50,
  }) async {
    final Map<String, String> query =
    <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final String queryString =
        Uri(
          queryParameters: query,
        ).query;

    return _get(
      '/api/admin/notifications?$queryString',
    );
  }

  Future<Map<String, dynamic>>
  sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
  }) async {
    return _post(
      '/api/admin/notifications/send-user',
      body: <String, dynamic>{
        'user_id': userId.trim(),
        'title': title.trim(),
        'message': message.trim(),
      },
    );
  }

  Future<Map<String, dynamic>>
  sendNotificationToAll({
    required String title,
    required String message,
  }) async {
    return _post(
      '/api/admin/notifications/send-all',
      body: <String, dynamic>{
        'title': title.trim(),
        'message': message.trim(),
      },
    );
  }

  Future<Map<String, dynamic>>
  deleteAdminNotification(
      int notificationId,
      ) async {
    return _delete(
      '/api/admin/notifications/$notificationId',
    );
  }
  // =======================================================
// ADMIN LOGLARI
// =======================================================

  Future<Map<String, dynamic>> getAdminLogs() async {
    return _get(
      '/api/admin/logs',
    );
  }
  // =======================================================
// SİSTEM AYARLARI
// =======================================================

  Future<Map<String, dynamic>>
  getSystemSettings() async {
    return _get(
      '/api/admin/system-settings',
    );
  }

  Future<Map<String, dynamic>>
  updateSystemSettings({
    required double commissionRate,
    required double minNotePrice,
    required double maxNotePrice,
    required int maxPdfSizeMb,
    required bool registrationEnabled,
    required bool noteApprovalRequired,
    required bool notificationsEnabled,
    required bool maintenanceMode,
  }) async {
    return _put(
      '/api/admin/system-settings',
      body: <String, dynamic>{
        'commission_rate':
        commissionRate,
        'min_note_price':
        minNotePrice,
        'max_note_price':
        maxNotePrice,
        'max_pdf_size_mb':
        maxPdfSizeMb,
        'registration_enabled':
        registrationEnabled,
        'note_approval_required':
        noteApprovalRequired,
        'notifications_enabled':
        notificationsEnabled,
        'maintenance_mode':
        maintenanceMode,
      },
    );
  }
  // =======================================================
  // HTTP GET
  // =======================================================

  Future<Map<String, dynamic>> _get(
      String endpoint,
      ) async {
    try {
      final Map<String, String> headers =
      await _authorizedHeaders();

      final http.Response response =
      await http
          .get(
        Uri.parse(
          '$baseUrl$endpoint',
        ),
        headers: headers,
      )
          .timeout(
        const Duration(
          seconds: 20,
        ),
      );

      final Map<String, dynamic> result =
      _parseResponse(response);

      await _handleUnauthorized(
        result,
      );

      return result;
    } catch (error) {
      debugPrint(
        'Admin GET hatası: $error',
      );

      return _connectionError();
    }
  }

  // =======================================================
  // HTTP POST
  // =======================================================

  Future<Map<String, dynamic>> _post(
      String endpoint, {
        Map<String, dynamic>? body,
        bool authorized = true,
      }) async {
    try {
      final Map<String, String> headers =
      authorized
          ? await _authorizedHeaders()
          : _publicHeaders;

      final http.Response response =
      await http
          .post(
        Uri.parse(
          '$baseUrl$endpoint',
        ),
        headers: headers,
        body: jsonEncode(
          body ??
              <String, dynamic>{},
        ),
      )
          .timeout(
        const Duration(
          seconds: 20,
        ),
      );

      final Map<String, dynamic> result =
      _parseResponse(response);

      if (authorized) {
        await _handleUnauthorized(
          result,
        );
      }

      return result;
    } catch (error) {
      debugPrint(
        'Admin POST hatası: $error',
      );

      return _connectionError();
    }
  }

  // =======================================================
  // HTTP PUT
  // =======================================================

  Future<Map<String, dynamic>> _put(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    try {
      final Map<String, String> headers =
      await _authorizedHeaders();

      final http.Response response =
      await http
          .put(
        Uri.parse(
          '$baseUrl$endpoint',
        ),
        headers: headers,
        body: jsonEncode(
          body ??
              <String, dynamic>{},
        ),
      )
          .timeout(
        const Duration(
          seconds: 20,
        ),
      );

      final Map<String, dynamic> result =
      _parseResponse(response);

      await _handleUnauthorized(
        result,
      );

      return result;
    } catch (error) {
      debugPrint(
        'Admin PUT hatası: $error',
      );

      return _connectionError();
    }
  }

  // =======================================================
  // HTTP DELETE
  // =======================================================

  Future<Map<String, dynamic>> _delete(
      String endpoint,
      ) async {
    try {
      final Map<String, String> headers =
      await _authorizedHeaders();

      final http.Response response =
      await http
          .delete(
        Uri.parse(
          '$baseUrl$endpoint',
        ),
        headers: headers,
      )
          .timeout(
        const Duration(
          seconds: 20,
        ),
      );

      final Map<String, dynamic> result =
      _parseResponse(response);

      await _handleUnauthorized(
        result,
      );

      return result;
    } catch (error) {
      debugPrint(
        'Admin DELETE hatası: $error',
      );

      return _connectionError();
    }
  }


  // =======================================================
  // HTTP DELETE + BODY
  // =======================================================

  Future<Map<String, dynamic>>
  _deleteWithBody(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    try {
      final Map<String, String> headers =
      await _authorizedHeaders();

      final http.Request request =
      http.Request(
        'DELETE',
        Uri.parse(
          '$baseUrl$endpoint',
        ),
      );

      request.headers.addAll(
        headers,
      );

      request.body = jsonEncode(
        body ??
            <String, dynamic>{},
      );

      final http.StreamedResponse
      streamedResponse =
      await request
          .send()
          .timeout(
        const Duration(
          seconds: 20,
        ),
      );

      final http.Response response =
      await http.Response.fromStream(
        streamedResponse,
      );

      final Map<String, dynamic> result =
      _parseResponse(
        response,
      );

      await _handleUnauthorized(
        result,
      );

      return result;
    } catch (error) {
      debugPrint(
        'Admin DELETE body hatası: $error',
      );

      return _connectionError();
    }
  }

  // =======================================================
  // CEVAP İŞLEME
  // =======================================================

  Map<String, dynamic> _parseResponse(
      http.Response response,
      ) {
    try {
      final dynamic decoded =
      jsonDecode(response.body);

      final Map<String, dynamic> data =
      decoded is Map
          ? Map<String, dynamic>.from(
        decoded,
      )
          : <String, dynamic>{
        'data': decoded,
      };

      if (
      response.statusCode >= 200 &&
          response.statusCode < 300
      ) {
        data.putIfAbsent(
          'success',
              () => true,
        );

        data['status_code'] =
            response.statusCode;

        return data;
      }

      return <String, dynamic>{
        ...data,
        'success': false,
        'status_code':
        response.statusCode,
        'error':
        data['error']?.toString() ??
            'İşlem gerçekleştirilemedi.',
      };
    } catch (error) {
      return <String, dynamic>{
        'success': false,
        'status_code':
        response.statusCode,
        'error':
        'Sunucudan geçersiz bir cevap alındı.',
      };
    }
  }

  bool _isUnauthorized(
      Map<String, dynamic> result,
      ) {
    return result['status_code'] == 401 ||
        result['code'] ==
            'TOKEN_EXPIRED' ||
        result['code'] ==
            'INVALID_TOKEN' ||
        result['code'] ==
            'TOKEN_MISSING';
  }

  Future<void> _handleUnauthorized(
      Map<String, dynamic> result,
      ) async {
    if (_isUnauthorized(result)) {
      await logout();
    }
  }

  Map<String, dynamic>
  _connectionError() {
    return <String, dynamic>{
      'success': false,
      'error':
      'Sunucuya bağlanılamadı. Node.js sunucusunun çalıştığından emin olun.',
    };
  }
}