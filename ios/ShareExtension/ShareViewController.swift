import UIKit
import UniformTypeIdentifiers

/// Principal class of the Share Extension. Extracts shared text (or fetches
/// the article behind a shared URL), stores it in the shared App Group, and
/// offers to open Speed Reader.
final class ShareViewController: UIViewController {

    private let statusLabel = UILabel()
    private let openButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildUI()
        processIncomingContent()
    }

    // MARK: - UI

    private func buildUI() {
        statusLabel.textColor = .white
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statusLabel.text = String(localized: "Processing…")

        spinner.color = .white
        spinner.startAnimating()

        openButton.setTitle(String(localized: "Open in Speed Reader"), for: .normal)
        openButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        openButton.backgroundColor = UIColor(red: 1, green: 68 / 255, blue: 68 / 255, alpha: 1)
        openButton.setTitleColor(.white, for: .normal)
        openButton.layer.cornerRadius = 10
        openButton.isHidden = true
        openButton.addTarget(self, action: #selector(openContainingApp), for: .touchUpInside)

        doneButton.setTitle(String(localized: "Done"), for: .normal)
        doneButton.setTitleColor(.white.withAlphaComponent(0.6), for: .normal)
        doneButton.addTarget(self, action: #selector(finish), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [spinner, statusLabel, openButton, doneButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            openButton.heightAnchor.constraint(equalToConstant: 46),
            openButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 220)
        ])
        preferredContentSize = CGSize(width: view.bounds.width, height: 220)
    }

    // MARK: - Content extraction

    private var providers: [NSItemProvider] {
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        return items.flatMap { $0.attachments ?? [] }
    }

    private func processIncomingContent() {
        let available = providers
        if let textProvider = available.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            loadText(from: textProvider)
        } else if let urlProvider = available.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            loadURL(from: urlProvider)
        } else {
            showResult(text: "", title: nil)
        }
    }

    private func loadText(from provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, _ in
            let text = item as? String ?? ""
            self?.finishOnMain(text: text, title: nil)
        }
    }

    private func loadURL(from provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
            guard let url = item as? URL else {
                self?.finishOnMain(text: "", title: nil)
                return
            }
            self?.fetchArticle(from: url)
        }
    }

    /// Fetches the shared page and extracts readable text. Falls back to the
    /// URL string itself when the fetch or the parse fails.
    private func fetchArticle(from url: URL) {
        let request = URLRequest(url: url, timeoutInterval: 6)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let data,
                  let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let html = String(data: data, encoding: .utf8) else {
                self?.finishOnMain(text: url.absoluteString, title: url.host)
                return
            }
            let extracted = TextCleaner.clean(ShareViewController.stripHTML(html))
            let body = extracted.isEmpty ? url.absoluteString : extracted
            self?.finishOnMain(text: body, title: url.host)
        }.resume()
    }

    /// Regex tag-stripping: drops style/script blocks, then replaces tags with spaces.
    static func stripHTML(_ html: String) -> String {
        var withoutBlocks = html
        for tag in ["style", "script", "head", "nav", "footer", "noscript"] {
            withoutBlocks = withoutBlocks.replacingOccurrences(
                of: #"(?is)<\#(tag)\b.*?</\#(tag)>"#,
                with: " ",
                options: .regularExpression
            )
        }
        return withoutBlocks.replacingOccurrences(
            of: #"<[^>]+>"#,
            with: " ",
            options: .regularExpression
        )
    }

    private func finishOnMain(text: String, title: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.showResult(text: text, title: title)
        }
    }

    // MARK: - Result

    private func showResult(text: String, title: String?) {
        spinner.stopAnimating()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusLabel.text = String(localized: "No readable text found.")
            openButton.isHidden = true
            return
        }

        AppGroupStore.savePending(text: trimmed, title: title)
        let words = trimmed.split(whereSeparator: \.isWhitespace).count
        statusLabel.text = String(
            format: String(localized: "Saved %d words to Speed Reader."), words
        )
        openButton.isHidden = false
    }

    // MARK: - Actions

    /// Best-effort open of the containing app via the responder chain; the
    /// data itself is already safe in the App Group for the next launch.
    @objc private func openContainingApp() {
        guard let url = URL(string: "speedreader://read") else { return finish() }
        var responder: UIResponder? = self
        let openURL = sel_registerName("openURL:")
        while let current = responder {
            if current.responds(to: openURL), current.perform(openURL, with: url) != nil {
                break
            }
            responder = current.next
        }
        finish()
    }

    @objc private func finish() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
