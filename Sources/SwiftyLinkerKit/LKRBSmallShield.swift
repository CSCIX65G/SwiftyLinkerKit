//
//  LKRBSmallShield.swift
//  SwiftyGPIO
//
//  Created by Van Simmons on 4/20/19.
//

import Foundation
import SwiftyGPIO
import Dispatch

/**
 * The LK-Base-RB2 Shield for Raspberry Pi 3 boards.
 *
 * Ports:
 * - UART
 * - I2C
 * - 12 digital sockets
 * -  4 analog sockets (SPI ADC on board)
 *
 * Detailed information can be found over here:
 *
 *   http://www.linkerkit.de/index.php?title=LK-Base-RB_2
 *
 */
open class LKRBSmallShield {
    
    public static let `default`    = LKRBSmallShield(gpios: defaultGPIOs, spis:  defaultSPIs)
    public static var defaultGPIOs = SwiftyGPIO.GPIOs(for: .RaspberryPi3)
    public static var defaultSPIs  = SwiftyGPIO.hardwareSPIs(for: .RaspberryPi3)
    
    public  let gpios       : [ GPIOName : GPIO ]
    public  let spis        : [ SPIInterface ]
    private var accessories = [ Socket   : LKAccessory ]()
    
    public  let Q = DispatchQueue(label: "de.zeezide.linkerkit.Q.shield")
    
    public init?(gpios: [ GPIOName: GPIO ], spis: [ SPIInterface ]?) {
        #if (!arch(arm64))
        return nil
        #else
        self.gpios = gpios
        self.spis  = spis ?? []
        _ = atexit {
            teardownShield()
        }
        #endif
    }
    
    open func gpios(for socket: Socket) -> ( GPIO, GPIO )? {
        guard let names = socket.gpioNames else { return nil }
        guard let gpio0 = gpios[names.0]   else { return nil }
        guard let gpio1 = gpios[names.1]   else { return nil }
        return ( gpio0, gpio1 )
    }
    
    open func analogInfo(for socket: Socket) -> ( SPIInterface, UInt8, UInt8 )? {
        guard let pins = socket.analogPINs else { return nil }
        guard let spi  = spis.first else { return nil } // TBD: hardcoded by board?
        
        return ( spi, pins.0, pins.1 )
    }
    
    // MARK: - Threadsafe API
    
    @discardableResult
    open func connect<T: LKAccessory>(_ accessory: T, to socket: Socket) -> T {
        Q.async {
            self._connect(accessory, to: socket)
        }
        return accessory
    }
    
    open func disconnect(_ accessory: LKAccessory) {
        Q.async {
            self._disconnect(accessory)
        }
    }
    
    open func getAccessories(_ cb: @escaping ( [ Socket : LKAccessory ] ) -> ()) {
        Q.async {
            cb(self.accessories)
        }
    }
    
    open func teardownOnExit() {
        // called by `atexit` - disable all accessories
        for ( _, accessory ) in accessories {
            accessory.teardownOnExit()
        }
    }
    
    
    // MARK: - Internal Ops
    
    open func _disconnect(_ accessory: LKAccessory) {
        guard let old = accessories.first(where: { $1 === accessory }) else {
            return
        }
        
        let oldSocket = old.0
        accessories.removeValue(forKey: oldSocket)
        accessory.shield(self, disconnectedFrom: oldSocket)
    }
    
    open func _connect(_ accessory: LKAccessory, to socket: Socket) { // Q: own
        if accessories[socket] === accessory { return } // already hooked up
        
        if let old = accessories.first(where: { $1 === accessory }) {
            let oldSocket = old.0
            accessories.removeValue(forKey: oldSocket)
            accessory.shield(self, disconnectedFrom: oldSocket)
        }
        
        if let oldAccessory = accessories[socket] {
            accessories.removeValue(forKey: socket)
            oldAccessory.shield(self, disconnectedFrom: socket)
        }
        
        accessories[socket] = accessory
        accessory.shield(self, connectedTo: socket)
    }
    
    /**
     * Sockets on the LK-RB-SmallShield
     * ```
     *       I2C
     *          UART
     * Analog      GPIO
     * ┌─┐┌─┐┌─┐┌─┐┌─┐
     * │ ││ ││ ││ ││ │
     * │ ││ ││ ││ ││ │
     * └─┘└─┘└─┘└─┘└─┘
     *       G  P  I  O
     *       ┌─┐┌─┐┌─┐
     *       │ ││ ││ │
     *       │ ││ ││ │
     *       └─┘└─┘└─┘
     * ```
     */
    public enum Socket : Hashable {
        // row1
        case analog01
        case analog23
        case uart
        case i2c
        case digital1718
        // row2
        case digital2722
        case digital2324
        case digital2504
        
        public init(row: Int, column: Int) {
            switch ( row, column ) {
            case ( 1, 1 ): self = .analog01
            case ( 1, 2 ): self = .analog23
            case ( 1, 3 ): self = .uart
            case ( 1, 4 ): self = .i2c
            case ( 1, 5 ): self = .digital1718
            case ( 2, 1 ): self = .analog01
            case ( 2, 2 ): self = .analog23
            case ( 2, 3 ): self = .analog23
            default: fatalError("invalid socket position: \(row)/\(column)")
            }
        }
        
        public var gpioNames : ( GPIOName, GPIOName )? {
            switch self {
            case .uart:         return nil // TBD
            case .i2c:          return nil // TBD
            case .analog01:     return ( .P0,  .P1  ) // TBD
            case .analog23:     return ( .P2,  .P3  ) // TBD
            case .digital1718:  return ( .P17, .P18)
            case .digital2722:  return ( .P27, .P22)
            case .digital2324:  return ( .P23, .P24)
            case .digital2504:  return ( .P25, .P4)
            }
        }
        
        public var analogPINs : ( UInt8, UInt8 )? {
            switch self {
            case .analog01:    return ( 0, 1 )
            case .analog23:    return ( 2, 3 )
            default:
                assert(!isAnalog)
                return nil
            }
        }
        
        public var position : ( row: Int, column: Int ) {
            switch self {
            case .analog01:     return ( 1, 1 )
            case .analog23:     return ( 1, 2 )
            case .uart:         return ( 1, 3 )
            case .i2c:          return ( 1, 4 )
            case .digital1718:  return ( 1, 5 )
            case .digital2722:  return ( 2, 1 )
            case .digital2324:  return ( 2, 2 )
            case .digital2504:  return ( 2, 3 )
            }
        }
        
        public var isDigital : Bool {
            switch self {
            case .uart:        return false
            case .i2c:         return false
            case .digital1718: return true
            case .digital2722: return true
            case .digital2324: return true
            case .digital2504: return true
            case .analog01:    return false
            case .analog23:    return false
            }
        }
        public var isAnalog : Bool {
            switch self {
            case .uart:        return false
            case .i2c:         return false
            case .digital1718: return false
            case .digital2722: return false
            case .digital2324: return false
            case .digital2504: return false
            case .analog01:    return true
            case .analog23:    return true
            }
        }
    }
}

fileprivate func teardownShield() {
    LKRBSmallShield.default?.teardownOnExit()
}
