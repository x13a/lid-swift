# lid-swift

Swift wrapper on lid state.

## Example

```swift
import Lid

func main() {
    print(Lid.getState())
    let notifier = LidNotifier { arg in
        print(arg & LidNotifier.kClamshellStateBit)
    }
    assert(notifier != nil)
    RunLoop.main.run()
}

main()
```
