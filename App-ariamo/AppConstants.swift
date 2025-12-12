import SwiftUI
import Foundation

// --- 1. CONFIGURAZIONE COLORI ---
// I colori che usi nel flusso principale (verde) e in Onboarding (menta)
extension Color {
    static let inputGray = Color(UIColor.systemGray6)
}

// --- 2. MODELLI DATI GLOBALI ---

// Modello per le attività (usato in ActivityListScreen)
struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let color: Color
}

// Modello dati temporaneo per l'evento in creazione (usato in CreationWizard)
struct DatiEvento {
    var tipo: String = ""
    var data: Date = Date()
    var luogo: String = ""
}
