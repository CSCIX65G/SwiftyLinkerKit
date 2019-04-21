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
    
    public var led : GPIO?
    
    var on : Bool? {
        didSet {
            
        }
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
        led = gpio0
        lock.unlock()
        #endif
        
        super.shield(shield, connectedTo: socket)
        
    }
    
    override open func shield(_ shield: LKRBShield, disconnectedFrom s: Socket) {
        lock.lock()
        led?.value = 0
        led = nil
        lock.unlock()
        
        super.shield(shield, disconnectedFrom: s)
    }
    
    
    // MARK: - Description
    
    override open func lockedAppendToDescription(_ ms: inout String) {
        super.lockedAppendToDescription(&ms)
        
        if let led = led { ms += " led=\(led ? "on" : "off")" }
    }
}
