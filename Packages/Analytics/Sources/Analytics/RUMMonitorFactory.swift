public enum RUMMonitorFactory {
    public static func makeDefault() -> any RUMMonitoring {
        return NoOpRUMMonitor()
    }
}
