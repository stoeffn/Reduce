import PlaygroundSupport
import SpriteKit

final class Conveyor: Composable, Bordered {
    let node: SKNode = SKCropNode()
    let length: CGFloat

    weak var input: Chainable?
    var output: Chainable?

    // MARK: - Life Cycle

    init(length: CGFloat? = nil) {
        self.length = length ?? conveyorWidth
    }

    convenience init(_ configuration: [String: PlaygroundValue]) {
        self.init(length: configuration["length"]?.cgFloat)
    }

    // MARK: - Configuration

    static func configuration(length: CGFloat = conveyorWidth) -> PlaygroundValue {
        return .dictionary([
            "type": .string(typeName),
            "length": .floatingPoint(Double(length))
        ])
    }

    // MARK: - Chainable

    var size: CGSize {
        return CGSize(width: conveyorWidth * CGFloat(numberOfInputLanes) + borderWidth * 2, height: length)
    }

    // MARK: - Component

    func updateAppearance() {
        node.removeAllChildren()

        let cropNode = node as? SKCropNode
        cropNode?.maskNode = SKSpriteNode(texture: nil, color: .black, size: size)
        setupPanels()
        setupBorder()
    }

    func process(_ items: [Int: Item]) {
        let duration = movementDuration(forDistance: length)
        let movement = SKAction.move(by: CGVector(dx: 0, dy: -length), duration: duration)
        items.values.forEach { $0.node.run(movement) }

        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            let outputComponent = self.output as? Composable
            outputComponent?.process(items)
        }
    }

    // MARK: - Border

    let borderTexture: SKTexture = conveyorBorderTexture
}
