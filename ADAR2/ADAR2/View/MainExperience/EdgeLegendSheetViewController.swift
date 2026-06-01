import UIKit

final class EdgeLegendSheetViewController: UIViewController {

    // MARK: - Data

    private let nodeLegend: [(String, String)] = [
        ("circle.fill",   "Data type (class / struct / enum / protocol)"),
        ("square.fill",   "Method"),
        ("triangle.fill", "Property"),
    ]

    private let defaultEdgeLegend: [(UIColor, String)] = [
        (.black,  "Any relationship"),
        (.orange, "Structural issue (cycle / crossing / low cohesion)"),
    ]

    private let structuredEdgeLegend: [(UIColor, String)] = [
        (.blue,    "Property of"),
        (.yellow,  "Method of"),
        (.black,   "Is of type of"),
        (.red,     "Inherits"),
        (.green,   "Method uses property"),
        (.orange,  "Method uses init"),
        (.brown,   "Method uses type property / method"),
        (.magenta, "Method uses type (params or return type)"),
        (.orange,  "Structural issue (cycle / crossing / low cohesion)"),
    ]

    // MARK: - Subviews

    private let segmentedControl = UISegmentedControl(items: ["Default", "Structured"])
    private let scrollView = UIScrollView()
    private let legendStack = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        legendStack.axis = .vertical
        legendStack.spacing = 12
        legendStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(legendStack)

        view.addSubview(segmentedControl)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            legendStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 4),
            legendStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            legendStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            legendStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            legendStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        reload()
    }

    // MARK: - Actions

    @objc private func segmentChanged() {
        reload()
    }

    // MARK: - Helpers

    private func reload() {
        legendStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        legendStack.addArrangedSubview(makeSectionHeader("Nodes"))
        for (symbol, label) in nodeLegend {
            legendStack.addArrangedSubview(makeShapeRow(symbol: symbol, text: label))
        }

        legendStack.setCustomSpacing(20, after: legendStack.arrangedSubviews.last!)
        legendStack.addArrangedSubview(makeSectionHeader("Edges"))
        let edgeItems = segmentedControl.selectedSegmentIndex == 0 ? defaultEdgeLegend : structuredEdgeLegend
        for (color, label) in edgeItems {
            legendStack.addArrangedSubview(makeColorRow(color: color, text: label))
        }
    }

    private func makeSectionHeader(_ title: String) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }

    private func makeShapeRow(symbol: String, text: String) -> UIView {
        let image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 20))
        let imageView = UIImageView(image: image)
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 32),
            imageView.heightAnchor.constraint(equalToConstant: 24),
        ])

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [imageView, label])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        return row
    }

    private func makeColorRow(color: UIColor, text: String) -> UIView {
        let swatch = UIView()
        swatch.backgroundColor = color
        swatch.layer.cornerRadius = 6
        swatch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            swatch.widthAnchor.constraint(equalToConstant: 32),
            swatch.heightAnchor.constraint(equalToConstant: 12),
        ])

        if color == .black {
            swatch.layer.borderWidth = 0.5
            swatch.layer.borderColor = UIColor.separator.cgColor
        }

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [swatch, label])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        return row
    }
}
