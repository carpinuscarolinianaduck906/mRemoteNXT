// SPDX-License-Identifier: GPL-2.0-or-later
// mRemoteNXT — Copyright (c) 2026 Razvan Cremenescu
// See LICENSE for full text.

import SwiftUI

@main
struct MRemoteApp: App {
    @StateObject private var model = AppModel()

    init() {
        // Tooltip-uri mai rapide (default macOS ~2s).
        UserDefaults.standard.register(defaults: ["NSInitialToolTipDelay": 500])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 560)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Deschide confCons.xml...") { model.openFilePanel() }
                    .keyboardShortcut("o")
            }
            CommandGroup(after: .saveItem) {
                Button("Salveaza") { model.save() }
                    .keyboardShortcut("s")
                    .disabled(!model.dirty)
            }
            CommandGroup(after: .toolbar) {
                Button("Mareste textul terminalului") { model.zoomTerminal(+1) }
                    .keyboardShortcut("=", modifiers: .command)
                Button("Micsoreaza textul terminalului") { model.zoomTerminal(-1) }
                    .keyboardShortcut("-", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(model)
        }
    }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            AppearanceSettings()
                .tabItem { Label("Aspect", systemImage: "paintbrush") }
            ToolsSettings()
                .tabItem { Label("Unelte externe", systemImage: "wrench.and.screwdriver") }
        }
        .frame(width: 460, height: 400)
    }
}

struct AppearanceSettings: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        Form {
            Section("Aspect") {
                VStack(alignment: .leading) {
                    Text("Marime text interfata: \(Int(model.uiFontSize))")
                    Slider(value: $model.uiFontSize, in: 10...22, step: 1)
                }
                VStack(alignment: .leading) {
                    Text("Marime text terminal: \(Int(model.terminalFontSize))")
                    Slider(value: $model.terminalFontSize, in: 8...28, step: 1)
                }
                Picker("Tema terminal", selection: $model.terminalTheme) {
                    ForEach(TerminalThemes.names, id: \.self) { Text($0).tag($0) }
                }
                VStack(alignment: .leading) {
                    Text("Inaltime rand: \(Int(model.rowHeight))")
                    Slider(value: $model.rowHeight, in: 16...44, step: 1)
                }
                Toggle("Arata tip protocol (RDP/SSH) in lista", isOn: $model.showProtocol)
                Toggle("Inchide tab-ul la deconectare (RDP)", isOn: $model.closeTabOnDisconnect)
                Toggle("Arata parola in clar in status bar", isOn: $model.showPasswordPlain)
            }
        }
        .formStyle(.grouped)
    }
}

struct ToolsSettings: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Macro-uri disponibile: %Host% %Username% %Port% %Password% %Domain% %Name%")
                .font(.caption).foregroundStyle(.secondary)
            List {
                ForEach($model.externalTools) { $tool in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("Nume", text: $tool.name)
                            Button(role: .destructive) { model.deleteTool(tool) } label: {
                                Image(systemName: "trash")
                            }.buttonStyle(.borderless)
                        }
                        TextField("Comanda (ex: ping -c 5 %Host%)", text: $tool.commandLine)
                            .font(.system(.callout, design: .monospaced))
                    }
                    .padding(.vertical, 2)
                }
            }
            Button { model.addTool() } label: { Label("Adauga unealta", systemImage: "plus") }
        }
        .padding()
    }
}
