// Network Info Interface and Implementation
//
// Used to check network connectivity status before making API calls.

/// Network info interface
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Simple implementation that always returns true
/// For production, use connectivity_plus package
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // TODO: Implement actual network check with connectivity_plus package
    // For now, always return true and let Dio handle network errors
    
    return true;
  }
}
