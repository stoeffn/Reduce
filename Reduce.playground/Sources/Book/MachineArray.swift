import PlaygroundSupport

public var machineProxy: PlaygroundRemoteLiveViewProxy?

public struct MachineArray<Element> where Element: ItemSerializable, Element: Equatable {
    let items: [Int: Element]

    init(_ items: [Int: Element] = [:]) {
        self.items = items
    }

    public init(_ items: [Element]) {
        let indexedItems = items.indexedDictionary
        self.init(indexedItems)

        machineProxy?.send(command: .reset)
        machineProxy?.send(command: .addComponent(spawner(with: indexedItems)))
        machineProxy?.send(command: .addComponent(conveyor(withLength: 128)))
    }

    public subscript(position: Int) -> Element {
        return items[position]!
    }

    var array: [Element] {
        return items
            .sorted { $0.0 < $1.0 }
            .map { $1 }
    }

    public func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> MachineArray<Element> {
        let result = try items.filterPairs { try isIncluded($1) }
        machineProxy?.send(command: .addComponent(operation(with: result, method: .filter)))
        machineProxy?.send(command: .addComponent(conveyor()))
        return MachineArray(result)
    }

    public func map<T: ItemSerializable>(_ transform: (Element) throws -> T) rethrows -> MachineArray<T> {
        let result = try items.mapPairs { ($0, try transform($1)) }
        machineProxy?.send(command: .addComponent(operation(with: result, method: .map)))
        machineProxy?.send(command: .addComponent(conveyor()))
        return MachineArray<T>(result)
    }

    public func reduce<Result: ItemSerializable>(_ initialResult: Result,
                       _ nextPartialResult: (Result, Element) throws -> Result) rethrows -> Result {
        let result = try items.values.reduce(initialResult, nextPartialResult)
        machineProxy?.send(command: .addComponent(operation(with: [0: result], method: .reduce)))
        machineProxy?.send(command: .addComponent(conveyor()))
        return result
    }

    public static func == (machineArray: MachineArray<Element>, array: Array<Element>) -> Bool {
        return machineArray.array == array
    }

    public static func == (array: Array<Element>, machineArray: MachineArray<Element>) -> Bool {
        return machineArray == array
    }
}

public func triggerMachine() {
    guard let proxy = machineProxy else {
        fatalError("Proxy not available.")
    }
    proxy.send(command: .trigger)
}
