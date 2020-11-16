//
//  ZoneAnnotationView.swift
//  MapboxTesting
//
//  Created by Rustam G on 16.11.2020.
//
import Mapbox
import UIKit

class PointAnnotationView: MGLAnnotationView {

    typealias CoordinateUpdateCallback = (CLLocationCoordinate2D) -> Void

    var coordinateUpdated: CoordinateUpdateCallback?
    
    var name: String = "" {
        didSet {
            updateFrame()
        }
    }

    var bubbleColor: UIColor = .blue {
        didSet {
            setNeedsDisplay()
        }
    }

    var textColor: UIColor {
        bubbleColor.contrastColor
    }

    private static let font = UIFont.systemFont(ofSize: 20, weight: .medium)
    private static let textPadding: CGFloat = 10

    private let bubblePainter = BubblePainter()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    override init(annotation: MGLAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {

        isOpaque = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowRadius = 2
        isDraggable = true
    }

    override func draw(_ rect: CGRect) {

        bubblePainter.draw(withColor: bubbleColor, in: bounds)
        drawText()
    }

    private func drawText() {

        (name as NSString).draw(
            at: CGPoint(x: Self.textPadding, y: Self.textPadding),
            withAttributes: [
                NSAttributedString.Key.font: Self.font,
                NSAttributedString.Key.foregroundColor: textColor
            ]
        )
    }

    private func updateFrame() {

        let textSize = (name as NSString).size(withAttributes: [NSAttributedString.Key.font: Self.font])
        let width = Self.textPadding + textSize.width + Self.textPadding
        let height = Self.textPadding + textSize.height + Self.textPadding + bubblePainter.triangleHeight
        frame = CGRect(x: 0, y: 0, width: width, height: height)

        centerOffset = CGVector(dx: frame.width / 2, dy: -frame.height / 2)
    }

    override var intrinsicContentSize: CGSize {

        return CGSize(width: frame.width, height: frame.height)
    }

    // Custom handler for changes in the annotation’s drag state.
    override func setDragState(_ dragState: MGLAnnotationViewDragState, animated: Bool) {
        super.setDragState(dragState, animated: animated)

        switch dragState {
        case .starting:
            print("Starting", terminator: "")
            startDragging()
        case .dragging:
            print(".", terminator: "")
        case .ending, .canceling:
            print("Ending")
            endDragging()
        case .none:
            break
        @unknown default:
            fatalError("Unknown drag state")
        }
    }

    // When the user interacts with an annotation, animate opacity and scale changes.
    private func startDragging() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 0.8
            self.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        }, completion: nil)

        // Initialize haptic feedback generator and give the user a light thud.
        if #available(iOS 10.0, *) {
            let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
            hapticFeedback.impactOccurred()
        }
    }

    private func updateCoordinate() {

        if let coordinate = annotation?.coordinate {
            coordinateUpdated?(coordinate)
        }
    }

    private func endDragging() {
        transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 1
            self.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
        }, completion: nil)

        // Give the user more haptic feedback when they drop the annotation.
        if #available(iOS 10.0, *) {
            let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
            hapticFeedback.impactOccurred()
        }

        updateCoordinate()
    }
}

struct BubblePainter {

    var cornerRadius: CGFloat = 10
    var triangleHeight: CGFloat = 14

    func draw(withColor color: UIColor, in bounds: CGRect) {

        let path = UIBezierPath()

        // start at lower left corner
        path.move(to: CGPoint(x: 0, y: bounds.height))
        // go to top left corner
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        // draw top left rounded corner
        path.addArc(withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(Double.pi),
                    endAngle: -CGFloat(Double.pi / 2),
                    clockwise: true)
        // go to top right corner
        path.addLine(to: CGPoint(x: bounds.width - cornerRadius, y: 0))
        // draw top right rounded corner
        path.addArc(withCenter: CGPoint(x: bounds.width - cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: -CGFloat(Double.pi / 2),
                    endAngle: 0,
                    clockwise: true)
        // go to bottom right corner
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height - triangleHeight - cornerRadius))
        // draw bottom right rounded corner
        path.addArc(withCenter: CGPoint(x: bounds.width - cornerRadius,
                                        y: bounds.height - cornerRadius - triangleHeight),
                    radius: cornerRadius,
                    startAngle: 0,
                    endAngle: CGFloat(Double.pi / 2),
                    clockwise: true)
        // go to bottom left corner
        path.addLine(to: CGPoint(x: triangleHeight / 2, y: bounds.height - triangleHeight))

        path.close()
        color.setFill()
        path.fill()
    }
}

extension UIColor {

    var contrastColor: UIColor {

        let rgba = self.rgba
        return (rgba.red * 0.299 + rgba.green * 0.587 + rgba.blue * 0.114) > 150
            ? .black
            : .white
    }

    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) { // swiftlint:disable:this large_tuple
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red: red, green: green, blue: blue, alpha: alpha)
    }
}

class PointAnnotation: NSObject, MGLAnnotation {

    var coordinate: CLLocationCoordinate2D

    var type: PointType = .plane

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(_ type: PointType, coordinate: CLLocationCoordinate2D) {
        self.type = type
        self.coordinate = coordinate
    }

    enum PointType: String {

        case plane = "C", trackStart = "A", trackEnd = "B"
    }
}
