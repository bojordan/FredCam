import Foundation
import SwiftUI

class PrinterSettings: ObservableObject {
    @Published var printerIP: String {
        didSet { UserDefaults.standard.set(printerIP, forKey: "printerIP") }
    }
    @Published var accessCode: String {
        didSet { UserDefaults.standard.set(accessCode, forKey: "accessCode") }
    }

    var isConfigured: Bool {
        !printerIP.isEmpty && !accessCode.isEmpty
    }

    var streamURL: URL? {
        guard isConfigured else { return nil }
        return URL(string: "rtsps://bblp:\(accessCode)@\(printerIP):322/streaming/live/1")
    }

    init() {
        self.printerIP = UserDefaults.standard.string(forKey: "printerIP") ?? ""
        self.accessCode = UserDefaults.standard.string(forKey: "accessCode") ?? ""
    }
}
