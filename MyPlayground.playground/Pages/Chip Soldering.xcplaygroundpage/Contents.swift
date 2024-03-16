
import UIKit
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

// MARK: Initial Code

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }
    
    public let chipType: ChipType
    
    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }
        
        return Chip(chipType: chipType)
    }
    
    // Тут ошибка, должно быть soldering, а не "sodering" - исправил
    public func soldering() {
        let solderingTime = chipType.rawValue
        sleep(UInt32(solderingTime))
    }
}

// MARK: Storage

final class ChipStorage {
    var chipStorage = [Chip]()
    var isAvailable = false
    var condition = NSCondition()
    var counter = 0
    
    func addThe(chip: Chip) {
        condition.lock()
        chipStorage.append(chip)
        counter += 1
        print("Новый экземпляр Chip No. M3-015-\(self.counter) добавлен в хранилище")
        
        isAvailable = true
        condition.signal()
        condition.unlock()
    }
    
    func removeChip() -> Chip? {
        condition.lock()
        while !isAvailable {
            condition.wait()
            print("Ожидаем новый экземпляр Chip...")
        }
        let chip = chipStorage.removeLast()
        isAvailable = !chipStorage.isEmpty
        condition.unlock()
        return chip
    }
}

// MARK: Threads

final class GeneratingThread: Thread {
    private let chipStorage: ChipStorage
    private var timer = Timer()
    
    init(chipStorage: ChipStorage) {
        self.chipStorage = chipStorage
    }
    
    override func main() {
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(createAChip), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 20))
    }
    
    @objc func createAChip() {
        chipStorage.addThe(chip: Chip.make())
    }
}
    
final class OperatingThread: Thread {
    private let chipStorage: ChipStorage

    init(chipStorage: ChipStorage) {
        self.chipStorage = chipStorage
    }
    
    override func main() {
        while true {
            if let chip = chipStorage.removeChip() {
                chip.soldering()
                print("Ранее добавленный Chip удален из хранилища и припаян к микросхеме")
            }
        }
    }
}

let chipStorage = ChipStorage()
let generatingThread = GeneratingThread(chipStorage: chipStorage)
let operatingThread = OperatingThread(chipStorage: chipStorage)
generatingThread.start()
operatingThread.start()

generatingThread.cancel()
operatingThread.cancel()
