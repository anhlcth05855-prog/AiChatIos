import Foundation

#if canImport(Darwin)
import Darwin
#endif

public struct HardwareSpecs {
    public let totalRamBytes: UInt64
    public let availableRamBytes: UInt64
    public let thermalState: ProcessInfo.ThermalState
    public let chipFamily: String
    
    public var formattedTotalRam: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalRamBytes), countStyle: .memory)
    }
    
    public var formattedAvailableRam: String {
        ByteCountFormatter.string(fromByteCount: Int64(availableRamBytes), countStyle: .memory)
    }
    
    public var thermalStatusText: String {
        switch thermalState {
        case .nominal: return "Mát (Nominal) 🟢"
        case .fair: return "Bình thường (Fair) 🟡"
        case .serious: return "Nhiệt độ cao (Serious) 🟠"
        case .critical: return "Quá tải nhiệt (Critical) 🔴"
        @unknown default: return "Ổn định"
        }
    }
}

public final class HardwareMemoryMonitor: ObservableObject {
    
    public static let shared = HardwareMemoryMonitor()
    
    @Published public var currentSpecs: HardwareSpecs
    
    private init() {
        self.currentSpecs = HardwareMemoryMonitor.fetchSpecs()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateChanged),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func thermalStateChanged() {
        DispatchQueue.main.async {
            self.refresh()
        }
    }
    
    public func refresh() {
        self.currentSpecs = HardwareMemoryMonitor.fetchSpecs()
    }
    
    public static func fetchSpecs() -> HardwareSpecs {
        let total = ProcessInfo.processInfo.physicalMemory
        var available: UInt64 = 0
        
        #if canImport(Darwin)
        available = UInt64(os_proc_available_memory())
        #else
        available = total / 2
        #endif
        
        let thermal = ProcessInfo.processInfo.thermalState
        let chip = detectChipFamily()
        
        return HardwareSpecs(
            totalRamBytes: total,
            availableRamBytes: available,
            thermalState: thermal,
            chipFamily: chip
        )
    }
    
    public func canSafelyRun(requiredRamBytes: Int64) -> Bool {
        refresh()
        let safetyMargin: Int64 = 350 * 1024 * 1024 // 350MB buffer for iOS UI
        return Int64(currentSpecs.availableRamBytes) > (requiredRamBytes + safetyMargin)
    }
    
    private static func detectChipFamily() -> String {
        #if targetEnvironment(simulator)
        return "Apple Silicon (Simulator)"
        #else
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let identifier = String(cString: machine)
        
        if identifier.contains("iPhone16") || identifier.contains("iPhone17") {
            return "A18 / A18 Pro (Apple Neural Engine 35 TOPS)"
        } else if identifier.contains("iPhone15") {
            return "A16 / A17 Pro (Apple Neural Engine)"
        } else if identifier.contains("iPad") {
            return "Apple M-Series / A-Series Bionic"
        } else {
            return "Apple Silicon Unified Memory"
        }
        #endif
    }
}
