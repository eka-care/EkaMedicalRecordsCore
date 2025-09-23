// MARK: - MRDocumentType
public struct MRDocumentType: Codable {
  let hex: String?
  let bgHex: String?
  let archive: Bool?
  let id: String?
  let displayName: String?

  enum CodingKeys: String, CodingKey {
    case hex = "hex"
    case bgHex = "bg_hex"
    case archive = "archive"
    case id = "id"
    case displayName = "display_name"
  }
}