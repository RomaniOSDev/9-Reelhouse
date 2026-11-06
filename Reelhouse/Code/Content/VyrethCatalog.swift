import Foundation

enum VyrethCatalog {
    static let book: VyrethBook = {
        guard let url = Bundle.main.url(forResource: "vyreth_book", withExtension: "json") else {
            fatalError("Missing bundled study book")
        }
        do {
            return try JSONDecoder().decode(VyrethBook.self, from: Data(contentsOf: url))
        } catch {
            fatalError("Study book could not be read")
        }
    }()
}
