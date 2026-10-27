import CoreWLAN
import Foundation
import Security

struct WiFiNetwork: Sendable {
    enum Security: String, Sendable {
        case open = "nopass"
        case wep = "WEP"
        case wpa = "WPA"
    }

    let ssid: String
    let security: Security
    let password: String?

    /// The text phone cameras read as "join this Wi-Fi network".
    var qrPayload: String {
        var payload = "WIFI:T:\(security.rawValue);S:\(Self.escaped(ssid));"
        if let password { payload += "P:\(Self.escaped(password));" }
        return payload + ";"
    }

    /// The network this Mac is on, with its password from the System keychain.
    @MainActor
    static func current() async throws -> WiFiNetwork {
        guard let interface = CWWiFiClient.shared().interface(), let ssid = interface.ssid() else {
            throw WiFiError.notConnected
        }
        let security = try Security(interface.security())
        guard security != .open else {
            return WiFiNetwork(ssid: ssid, security: security, password: nil)
        }
        return WiFiNetwork(ssid: ssid, security: security, password: try await password(for: ssid))
    }

    /// Blocks while macOS asks for an administrator's password, so it runs off the main actor.
    @concurrent
    private static func password(for ssid: String) async throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "AirPort",
            kSecAttrAccount as String: ssid,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let password = String(data: data, encoding: .utf8) else {
                throw WiFiError.keychain(errSecDecode)
            }
            return password
        case errSecItemNotFound:
            throw WiFiError.noSavedPassword(ssid)
        case errSecUserCanceled, errSecAuthFailed:
            throw WiFiError.cancelled
        default:
            throw WiFiError.keychain(status)
        }
    }

    private static let specialCharacters: Set<Character> = ["\\", ";", ",", ":", "\""]

    private static func escaped(_ value: String) -> String {
        value.reduce(into: "") { result, character in
            if specialCharacters.contains(character) { result.append("\\") }
            result.append(character)
        }
    }
}

private extension WiFiNetwork.Security {
    init(_ security: CWSecurity) throws {
        switch security {
        case .none, .OWE, .oweTransition:
            self = .open
        case .WEP:
            self = .wep
        case .dynamicWEP, .wpaEnterprise, .wpaEnterpriseMixed, .wpa2Enterprise, .enterprise, .wpa3Enterprise:
            throw WiFiError.enterprise
        default:
            self = .wpa
        }
    }
}

enum WiFiError: LocalizedError {
    case locationDenied
    case notConnected
    case enterprise
    case noSavedPassword(String)
    case keychain(OSStatus)
    case qrCode
    case cancelled

    var errorDescription: String? {
        switch self {
        case .locationDenied:
            "macOS only shares the Wi-Fi network's name with apps that have location access. Turn on WiFi QR in System Settings › Privacy & Security › Location Services."
        case .notConnected:
            "This Mac isn't connected to Wi-Fi."
        case .enterprise:
            "This network signs in with an account, so it has no shared password."
        case .noSavedPassword(let ssid):
            "There's no saved password for “\(ssid)”."
        case .keychain(let status):
            SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error \(status)."
        case .qrCode:
            "Couldn't make the QR code."
        case .cancelled:
            nil
        }
    }
}
