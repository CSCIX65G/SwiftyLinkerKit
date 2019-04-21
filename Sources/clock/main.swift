import SwiftyLinkerKit
import Dispatch

#if (!arch(arm64))

let shield  = LKRBShield.default
let display = LKDigi()

shield?.connect(display, to: .digital45)

print("Make sure the LK-Digi is connected to the digital 4/5 socket!")

let timer = DispatchSource.makeTimerSource()

timer.setEventHandler {
    display.showTime()
}

timer.schedule(deadline  : .now(),
               repeating : .seconds(1),
               leeway    : .milliseconds(1))
timer.resume()

dispatchMain()

#else
print("SwiftyLinkerKit can only be used on arm64")
#endif

