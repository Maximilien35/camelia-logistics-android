import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'services/collaborator_order_service.dart';
import 'services/cache_manager.dart';
import 'services/user_profile_service.dart';

class CollaboratorStateModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollaboratorOrderService _orderService = CollaboratorOrderService();
  final CacheManager _cacheManager = CacheManager();
  final UserProfileService _userProfileService = UserProfileService();

  // State
  User? _currentUser;
  UserProfile? _collaboratorProfile;
  List<Map<String, dynamic>> _assignedOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  Map<String, dynamic>? _selectedOrder;
  bool _isLoading = false;
  String? _errorMessage;
  String _filter = 'ALL'; // ALL, PENDING, IN_PROGRESS, COMPLETED
  double _totalEarnings = 0;
  double _todayEarnings = 0;
  int _totalOrders = 0;
  int _completedToday = 0;
  bool _isOnline = true;

  // Getters
  User? get currentUser => _currentUser;
  UserProfile? get collaboratorProfile => _collaboratorProfile;
  List<Map<String, dynamic>> get assignedOrders => _filteredOrders;
  Map<String, dynamic>? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filter => _filter;
  double get totalEarnings => _totalEarnings;
  double get todayEarnings => _todayEarnings;
  int get totalOrders => _totalOrders;
  int get completedToday => _completedToday;
  bool get isOnline => _isOnline;

  /// Initialize collaborator session
  Future<void> initializeSession() async {
    // Avoid double initialization
    if (_currentUser != null && _assignedOrders.isNotEmpty) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Initialize cache manager first
      await _cacheManager.initialize();
      _isOnline = _cacheManager.isOnline;

      // Check if already logged in
      _currentUser = _auth.currentUser;
      if (_currentUser == null) {
        _errorMessage = 'No user logged in';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load profile and orders
      await loadCollaboratorProfile();
      await loadAssignedOrders();
      await loadEarningsStats();

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load collaborator profile from Firestore
  Future<void> loadCollaboratorProfile() async {
    if (_currentUser == null) return;

    try {
      _collaboratorProfile = await _userProfileService.getProfileFresh(_currentUser!.uid);
      if (_collaboratorProfile == null) {
        _errorMessage = 'Profile not found';
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      notifyListeners();
    }
  }
    

  /// Load assigned orders with cache-first strategy
  Future<void> loadAssignedOrders() async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _assignedOrders = await _orderService.getAssignedOrders(_currentUser!.uid);
      _totalOrders = _assignedOrders.length;
      _applyFilter(_filter);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load orders: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh orders from Firestore (explicit refresh)
  Future<void> refreshOrders() async {
    if (_currentUser == null) return;

    if (!_isOnline) {
      _errorMessage = 'No internet connection';
      notifyListeners();
      return;
    }

    try {
      _assignedOrders = await _orderService.getAssignedOrders(_currentUser!.uid);
      _totalOrders = _assignedOrders.length;
      _applyFilter(_filter);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh: $e';
      notifyListeners();
    }
  }

  /// Load earnings statistics
  Future<void> loadEarningsStats() async {
    if (_currentUser == null) return;

    try {
      final total = await _orderService.getTotalEarnings(_currentUser!.uid);
      final today = await _orderService.getTodayEarnings(_currentUser!.uid);

      _totalEarnings = total;
      _todayEarnings = today;

      // Count completed orders today
      final completedOrders = _assignedOrders
          .where((order) => order['status'] == 'COMPLETED')
          .toList();

      _completedToday = completedOrders.length;

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading earnings: $e');
      }
    }
  }

  /// Accept an order
  Future<bool> acceptOrder(String orderId) async {
    if (_currentUser == null) return false;

    try {
      final success = await _orderService.acceptOrder(orderId, _currentUser!.uid);
      if (success) {
        // Reload orders
        await loadAssignedOrders();
        _errorMessage = null;
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to accept order: $e';
      notifyListeners();
      return false;
    }
  }

  /// Refuse an order
  Future<bool> refuseOrder(String orderId, {String? reason}) async {
    if (_currentUser == null) return false;

    try {
      final success =
          await _orderService.refuseOrder(orderId, _currentUser!.uid, reason: reason);
      if (success) {
        // Reload orders
        await loadAssignedOrders();
        _errorMessage = null;
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to refuse order: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus,
      {String? notes}) async {
    try {
      final success =
          await _orderService.updateOrderStatus(orderId, newStatus, notes: notes);
      if (success) {
        // Update local state
        final index = _assignedOrders.indexWhere((o) => o['id'] == orderId);
        if (index >= 0) {
          _assignedOrders[index]['status'] = newStatus;
          if (notes != null) {
            _assignedOrders[index]['collaboratorNotes'] = notes;
          }
        }

        _applyFilter(_filter);
        await loadEarningsStats();
        _errorMessage = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to update order: $e';
      notifyListeners();
      return false;
    }
  }

  void selectOrder(Map<String, dynamic> order) {
    _selectedOrder = order;
    notifyListeners();
  }

  /// Clear selected order
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  /// Apply filter to orders list
  void applyFilter(String filterType) {
    _filter = filterType;
    _applyFilter(filterType);
    notifyListeners();
  }

  /// Internal filter application
  void _applyFilter(String filterType) {
    if (filterType == 'ALL') {
      _filteredOrders = _assignedOrders;
    } else if (filterType == 'PENDING') {
      _filteredOrders = _assignedOrders
          .where((order) => order['status'] == 'PENDING')
          .toList();
    } else if (filterType == 'IN_PROGRESS') {
      _filteredOrders = _assignedOrders
          .where((order) =>
              order['status'] == 'ACCEPTED' || order['status'] == 'IN_PROGRESS')
          .toList();
    } else if (filterType == 'COMPLETED') {
      _filteredOrders = _assignedOrders
          .where((order) => order['status'] == 'COMPLETED')
          .toList();
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      _orderService.clearAllCache();
      _cacheManager.clearAllCache();
      await _auth.signOut();

      _currentUser = null;
      _collaboratorProfile = null;
      _assignedOrders = [];
      _filteredOrders = [];
      _selectedOrder = null;
      _errorMessage = null;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to logout: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get order by ID
  Map<String, dynamic>? getOrderById(String orderId) {
    try {
      return _assignedOrders.firstWhere((order) => order['id'] == orderId);
    } catch (e) {
      return null;
    }
  }

  /// Format price (handle both int and double)
  static String formatPrice(dynamic price) {
    if (price == null) return '0 FCFA';
    if (price is int) return '$price FCFA';
    if (price is double) return '${price.toStringAsFixed(0)} FCFA';
    return '$price FCFA';
  }

  @override
  void dispose() {
    _cacheManager.dispose();
    super.dispose();
  }
}
