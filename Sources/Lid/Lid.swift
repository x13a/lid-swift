import IOKit

// https://github.com/dustinrue/ControlPlane/blob/master/Source/LaptopLidEvidenceSource.m
// https://github.com/objective-see/DoNotDisturb/blob/master/launchDaemon/launchDaemon/Lid.m

public struct Lid {
    
    public enum State {
        case unavailable
        case close
        case open
    }
    
    public static let kAppleClamshellStateKey = "AppleClamshellState"
    
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

public class LidNotifier {
    
    public typealias Callback = (_ arg: Int ) -> ()
    public static let kClamshellStateBit = 1 << 0
    public static let kClamshellSleepBit = 1 << 1
    
    public static let kIOPMMessageClamshellStateChange =
        iokit_family_msg(sub_iokit_powermanagement, 0x100)
    
    private static func err_system(_ x: Int32) -> Int32 {
        return Int32(bitPattern: (UInt32(bitPattern: x) & 0x3f) << 26)
    }
    
    private static func err_sub(_ x: Int32) -> Int32 {
        return (x & 0xfff) << 14
    }
    
    private static func iokit_family_msg(
        _ sub: Int32,
        _ message: Int32
    ) -> UInt32 { return UInt32(bitPattern: sys_iokit|sub|message) }
    
    private static let sys_iokit = err_system(0x38)
    private static let sub_iokit_powermanagement = err_sub(13)
    
    private let callback: Callback
    private let notifyPort: IONotificationPortRef!
    private var notification: io_object_t = 0
    
    public init?(callback: @escaping Callback) {
        notifyPort = IONotificationPortCreate(kIOMasterPortDefault)
        guard notifyPort != nil else { return nil }
        IONotificationPortSetDispatchQueue(
            notifyPort,
            DispatchQueue.global(qos: .background)
        )
        let service = IOServiceGetMatchingService(
            kIOMasterPortDefault,
            IOServiceMatching("IOPMrootDomain")
        )
        guard service != IO_OBJECT_NULL else {
            IONotificationPortDestroy(notifyPort)
            return nil
        }
        defer { IOObjectRelease(service) }
        let ioCallback: IOServiceInterestCallback = {
            ctx, _, messageType, messageArgument in
            guard let ctx = ctx else { return }
            guard messageType == LidNotifier.kIOPMMessageClamshellStateChange
            else { return }
            Unmanaged<LidNotifier>
                .fromOpaque(ctx)
                .takeUnretainedValue()
                .callback(Int(bitPattern: messageArgument))
        }
        self.callback = callback
        guard IOServiceAddInterestNotification(
            notifyPort,
            service,
            kIOGeneralInterest,
            ioCallback,
            Unmanaged.passUnretained(self).toOpaque(),
            &notification
        ) == KERN_SUCCESS else {
            IONotificationPortDestroy(notifyPort)
            return nil
        }
    }
    
    deinit {
        IOObjectRelease(notification)
        IONotificationPortDestroy(notifyPort)
    }
}
