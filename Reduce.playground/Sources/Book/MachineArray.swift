import PlaygroundSupport

public struct MachineArray<Element>: MachineSerializable where Element: ItemSerializable {
    let items: [Int: Element]
    let configuration: [PlaygroundValue]

    init(_ items: [Int: Element] = [:], configuration: [PlaygroundValue]? = nil) {
        self.items = items
        self.configuration = configuration ?? MachineArray.spawnerConfiguration(for: items)
    }

    public init(_ items: Element...) {
        self.init(items.indexedDictionary)
    }

    public subscript(position: Int) -> Element {
        return items[position]!
    }

    public func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> MachineArray<Element> {
        let result = try items.filterPairs { try isIncluded($1) }
        return MachineArray(result, configuration: configuration + MachineArray.configuration(for: result, method: .filter))
    }

    public func map<T: ItemSerializable>(_ transform: (Element) throws -> T) rethrows -> MachineArray<T> {
        let result = try items.mapPairs { ($0, try transform($1)) }
        return MachineArray<T>(result, configuration: configuration + MachineArray.configuration(for: result, method: .map))
    }

    public func reduce<Result: ItemSerializable>(_ initialResult: Result,
                       _ nextPartialResult: (Result, Element) throws -> Result) rethrows -> MachineArray<Result> {
        let result = [0: try items.values.reduce(initialResult, nextPartialResult)]
        return MachineArray<Result>(result, configuration: configuration + MachineArray.configuration(for: result, method: .reduce))
    }

    private static func configuration(for items: [Int: ItemSerializable], method: Operation.Method) -> [PlaygroundValue] {
        let operation = Operation.configuration(forItems: items, method: method)
        let conveyor = Conveyor.configuration()
        return [operation, conveyor]
    }
}
