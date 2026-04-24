class ForbidModularGetOutsideModuleConfig {
  const ForbidModularGetOutsideModuleConfig({required this.allowList});

  final Set<String> allowList;

  factory ForbidModularGetOutsideModuleConfig.defaults() {
    return const ForbidModularGetOutsideModuleConfig(allowList: {'AppRouter'});
  }

  bool allowsType(String typeName) {
    return allowList.contains(typeName);
  }
}
