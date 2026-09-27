import Foundation
import Compression

enum ZipArchiveError: Error, LocalizedError {
    case corrupt(String)
    case unsupportedCompression(String)

    var errorDescription: String? {
        switch self {
        case .corrupt(let entry): return "Corrupt ZIP data near '\(entry)'"
        case .unsupportedCompression(let method): return "Unsupported ZIP compression method \(method)"
        }
    }
}

/// Minimal read-only ZIP parser (central directory + raw DEFLATE via libcompression).
/// Just enough to unpack an EPUB container without external dependencies.
enum ZipArchive {

    struct Entry {
        let name: String
        let data: Data
    }

    private static let localFileHeaderSignature: UInt32 = 0x0403_4b50
    private static let centralDirectorySignature: UInt32 = 0x0201_4b50
    private static let endOfCentralDirectorySignature: UInt32 = 0x0605_4b50

    /// Extracts all non-directory entries, keyed by name.
    static func extractEntries(from archive: Data) throws -> [Entry] {
        let directory = try parseCentralDirectory(archive)
        var entries: [Entry] = []
        for record in directory where !record.name.hasSuffix("/") {
            let data = try entryData(for: record, in: archive)
            entries.append(Entry(name: record.name, data: data))
        }
        return entries
    }

    // MARK: - Central directory

    private struct DirectoryRecord {
        let name: String
        let compressionMethod: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localHeaderOffset: Int
    }

    private static func parseCentralDirectory(_ data: Data) throws -> [DirectoryRecord] {
        let eocdOffset = try findEndOfCentralDirectory(data)
        let entryCount = Int(readUInt16(data, at: eocdOffset + 10))
        var records: [DirectoryRecord] = []
        var cursor = Int(readUInt32(data, at: eocdOffset + 16)) // directory start offset

        for _ in 0..<entryCount {
            guard cursor + 46 <= data.count,
                  readUInt32(data, at: cursor) == centralDirectorySignature else {
                throw ZipArchiveError.corrupt("central directory")
            }
            let nameLength = Int(readUInt16(data, at: cursor + 28))
            let extraLength = Int(readUInt16(data, at: cursor + 30))
            let commentLength = Int(readUInt16(data, at: cursor + 32))
            let nameEnd = cursor + 46 + nameLength
            guard nameEnd + extraLength + commentLength <= data.count else {
                throw ZipArchiveError.corrupt("central directory entry")
            }
            records.append(
                DirectoryRecord(
                    name: readString(data, in: (cursor + 46)..<nameEnd),
                    compressionMethod: readUInt16(data, at: cursor + 10),
                    compressedSize: Int(readUInt32(data, at: cursor + 20)),
                    uncompressedSize: Int(readUInt32(data, at: cursor + 24)),
                    localHeaderOffset: Int(readUInt32(data, at: cursor + 42))
                )
            )
            cursor = nameEnd + extraLength + commentLength
        }
        return records
    }

    private static func findEndOfCentralDirectory(_ data: Data) throws -> Int {
        let minimumTail = 22
        guard data.count >= minimumTail else { throw ZipArchiveError.corrupt("end of central directory") }
        let scanStart = max(0, data.count - 65_557)
        var offset = data.count - minimumTail
        while offset >= scanStart {
            if readUInt32(data, at: offset) == endOfCentralDirectorySignature { return offset }
            offset -= 1
        }
        throw ZipArchiveError.corrupt("end of central directory")
    }

    // MARK: - Entry payloads

    private static func entryData(for record: DirectoryRecord, in archive: Data) throws -> Data {
        guard record.localHeaderOffset + 30 <= archive.count,
              readUInt32(archive, at: record.localHeaderOffset) == localFileHeaderSignature else {
            throw ZipArchiveError.corrupt(record.name)
        }
        let nameLength = Int(readUInt16(archive, at: record.localHeaderOffset + 26))
        let extraLength = Int(readUInt16(archive, at: record.localHeaderOffset + 28))
        let dataStart = record.localHeaderOffset + 30 + nameLength + extraLength
        guard dataStart + record.compressedSize <= archive.count else {
            throw ZipArchiveError.corrupt(record.name)
        }
        let payload = archive.subdata(in: dataStart..<(dataStart + record.compressedSize))

        switch record.compressionMethod {
        case 0:
            return payload
        case 8:
            return try inflate(payload, uncompressedSize: record.uncompressedSize, entryName: record.name)
        default:
            throw ZipArchiveError.unsupportedCompression(String(record.compressionMethod))
        }
    }

    /// libcompression's COMPRESSION_ZLIB decodes raw DEFLATE streams (no zlib header), which is
    /// exactly what ZIP stores.
    private static func inflate(_ payload: Data, uncompressedSize: Int, entryName: String) throws -> Data {
        guard uncompressedSize > 0 else { return Data() }
        var destination = Data(count: uncompressedSize)
        let written: Int = destination.withUnsafeMutableBytes { destinationBuffer in
            payload.withUnsafeBytes { sourceBuffer in
                guard let source = sourceBuffer.bindMemory(to: UInt8.self).baseAddress,
                      let target = destinationBuffer.bindMemory(to: UInt8.self).baseAddress else {
                    return 0
                }
                return compression_decode_buffer(
                    target, destinationBuffer.count,
                    source, payload.count,
                    nil, COMPRESSION_ZLIB
                )
            }
        }
        guard written == uncompressedSize else { throw ZipArchiveError.corrupt(entryName) }
        return destination
    }

    // MARK: - Little-endian readers

    private static func readUInt16(_ data: Data, at offset: Int) -> UInt16 {
        let start = data.startIndex + offset
        let bytes = [UInt8](data[start..<data.index(start, offsetBy: 2)])
        return UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
    }

    private static func readUInt32(_ data: Data, at offset: Int) -> UInt32 {
        let start = data.startIndex + offset
        let bytes = [UInt8](data[start..<data.index(start, offsetBy: 4)])
        return UInt32(bytes[0])
            | (UInt32(bytes[1]) << 8)
            | (UInt32(bytes[2]) << 16)
            | (UInt32(bytes[3]) << 24)
    }

    private static func readString(_ data: Data, in range: Range<Int>) -> String {
        let slice = data.subdata(in: (data.startIndex + range.lowerBound)..<(data.startIndex + range.upperBound))
        return String(data: slice, encoding: .utf8) ?? ""
    }
}
