/// Configuration for [ForbidModularGetOutsideModuleAnalyzer].
class ForbidModularGetOutsideModuleConfig {
  /// Creates a config with the given [allowList].
  const ForbidModularGetOutsideModuleConfig({required this.allowList});

  /// Type names exempt from the rule.
  final Set<String> allowList;

  /// Returns the default config with an empty allow-list.
  factory ForbidModularGetOutsideModuleConfig.defaults() {
    return const ForbidModularGetOutsideModuleConfig(allowList: {});
  }

  /// Returns true if [typeName] is in the allow-list.
  bool allowsType(String typeName) {
    return allowList.contains(typeName);
  }
}
