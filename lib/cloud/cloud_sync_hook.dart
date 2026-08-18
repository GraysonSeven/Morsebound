typedef CloudLocalChangeCallback = void Function();

class CloudSyncHook {
  const CloudSyncHook._();
  static CloudLocalChangeCallback? onLocalChanged;
  static void notifyLocalChanged() => onLocalChanged?.call();
}
