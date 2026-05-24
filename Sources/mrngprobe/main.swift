// SPDX-License-Identifier: GPL-2.0-or-later
// mRemoteNXT — Copyright (c) 2026 Razvan Cremenescu
// See LICENSE for full text.

import Foundation
import MRNGCore

guard CommandLine.arguments.count > 1 else {
    print("Folosire: mrngprobe <cale-catre-confCons.xml>")
    exit(1)
}
let path = CommandLine.arguments[1]

do {
    let doc = try ConfConsParser.parse(fileURL: URL(fileURLWithPath: path))
    print("=== confCons \(doc.confVersion) | \(doc.encryptionEngine)/\(doc.blockCipherMode) | KDF \(doc.kdfIterations) ===")

    let all = doc.allNodes()
    let containers = all.filter { $0.isContainer }
    let connections = all.filter { !$0.isContainer }
    print("Noduri: \(all.count) | foldere: \(containers.count) | conexiuni: \(connections.count) | radacini: \(doc.roots.count)")

    var byProto: [String: Int] = [:]
    for c in connections { byProto[c.protocolType, default: 0] += 1 }
    print("Protocoale:", byProto.sorted { $0.value > $1.value }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))

    // Valideaza parola master pe Protected.
    let pw = MRNGCrypto.defaultPassword
    let ok = MRNGCrypto.passwordIsCorrect(protectedBase64: doc.protected, password: pw, iterations: doc.kdfIterations)
    print("Parola master '\(pw)': \(ok ? "corecta" : "GRESITA")")

    // Cate parole se decripteaza cu succes (fara a le afisa)?
    let withPw = connections.filter { !$0.encryptedPassword.isEmpty }
    let decryptOK = withPw.filter { MRNGCrypto.decrypt(base64: $0.encryptedPassword, password: pw, iterations: doc.kdfIterations) != nil }
    print("Parole criptate: \(withPw.count) | decriptate cu succes: \(decryptOK.count)")

    // Exemplu de conexiune SSH cu campuri rezolvate (parola mascata).
    if let ssh = connections.first(where: { $0.protocolType.hasPrefix("SSH") && !$0.hostname.isEmpty }) {
        let hasPw = !ssh.encryptedPassword.isEmpty
        print("Exemplu SSH: name=\"\(ssh.name)\" host=\(ssh.hostname):\(ssh.port) user=\(ssh.username) pwd=\(hasPw ? "***" : "(none)")")
    }

    // Test criptare round-trip.
    let secret = "Parola!Test#123"
    let enc = MRNGCrypto.encrypt(plaintext: secret, password: pw, iterations: doc.kdfIterations)
    let dec = MRNGCrypto.decrypt(base64: enc, password: pw, iterations: doc.kdfIterations)
    print("Encrypt round-trip: \(dec == secret ? "OK" : "ESUAT (\(dec ?? "nil"))")")

    // Test serializare round-trip: serialize -> re-parse -> compara.
    let xml = ConfConsSerializer.serialize(doc)
    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("mrng_roundtrip.xml")
    try xml.write(to: tmp, atomically: true, encoding: .utf8)
    let doc2 = try ConfConsParser.parse(fileURL: tmp)
    let n2 = doc2.allNodes()
    print("Serialize round-trip: noduri \(all.count) -> \(n2.count) | conexiuni \(connections.count) -> \(n2.filter{!$0.isContainer}.count) | \(all.count == n2.count ? "OK" : "DIFERA")")
    // Verifica ca o parola criptata e inca decriptabila dupa round-trip.
    if let p = doc2.allNodes().first(where: { !$0.encryptedPassword.isEmpty }) {
        let ok = MRNGCrypto.decrypt(base64: p.encryptedPassword, password: pw, iterations: doc2.kdfIterations) != nil
        print("Parola pastrata dupa serialize: \(ok ? "OK" : "ESUAT")")
    }
} catch {
    print("Eroare parsare: \(error)")
    exit(1)
}
