class GatewayFailure implements Exception {
  const GatewayFailure(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}
