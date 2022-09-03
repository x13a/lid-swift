import IOKit

// https://github.com/dustinrue/ControlPlane/blob/master/Source/LaptopLidEvidenceSource.m

public struct Lid {
    
    public static let kAppleClamshellStateKey = "AppleClamshellState"
    
    public enum State {
        case unavailable
        case close
        case open
    }
    
    public static func getState() -> State {
        let entry = IORegistryEntryFromPath(
            kIOMasterPortDefault,
            "\(kIOPowerPlane):/IOPowerConnection/IOPMrootDomain"
        )
        guard entry != MACH_PORT_NULL else { return .unavailable }
        defer { IOObjectRelease(entry) }
        guard let state = IORegistryEntryCreateCFProperty(
            entry,
            (kAppleClamshellStateKey as! CFString),
            kCFAllocatorDefault,
            0
        ) else { return .unavailable }
        return state.takeUnretainedValue() as! Bool ? .close : .open
    }
}
