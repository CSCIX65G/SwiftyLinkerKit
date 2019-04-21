//
//  LKLed.swift
//  SwiftyGPIO
//
//  Created by Van Simmons on 4/21/19.
//

/**
 * A LinkerKit LK-LED component.
 *
 * See here for details:
 *
 *   http://www.linkerkit.de/index.php?title=LK-LED5-Green
 *
 * Example:
 *
 *     let shield  = LKRBShield.default
 *     let led = LKButton2()
 *
 *     shield.connect(buttons, to: .digital2122)
 *
 *     led.on = true
 *     led.on = false
 *
 */
open class LKLed : LKAccessoryBase  {
    
    public var gpio0 : GPIO?
    public var gpio1 : GPIO?

    public var on : Bool {
        didSet {
            gpio0?.value = on ? 1 : 0
            gpio1?.value = on ? 1 : 0
        }
    }
    
    override init() {
        on = false
        super.init()
    }
    
    // MARK: - Accessory Registration
    
    override open func shield(_ shield: LKRBShield, connectedTo socket: Socket) {
        assert(socket.isDigital, "attempt to connect digital accessory \(self) " +
            "to non-digital socket: \(socket)")
        
        guard let ( gpio0, gpio1 ) = shield.gpios(for: socket) else { return }
        
        #if !os(macOS)
        gpio0.direction = .OUT
        gpio1.direction = .OUT

        // read initial state
        lock.lock()
        gpio0.value = 0
        gpio1.value = 0
        self.gpio0 = gpio0
        self.gpio1 = gpio1
        lock.unlock()
        #endif
        
        super.shield(shield, connectedTo: socket)
    }
    
    override open func shield(_ shield: LKRBShield, disconnectedFrom s: Socket) {
        lock.lock()
        gpio0?.value = 0
        gpio1?.value = 0
        lock.unlock()
        
        super.shield(shield, disconnectedFrom: s)
    }
    
    
    // MARK: - Description
    
    override open func lockedAppendToDescription(_ ms: inout String) {
        super.lockedAppendToDescription(&ms)
        ms += " led=\(on ? "on" : "off")"
    }
}
