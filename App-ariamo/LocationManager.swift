import Foundation
import CoreLocation
import MapKit
import SwiftUI
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var permissionDenied = false
    
    // Mappa centrata su Napoli di default
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    private var hasSetInitialRegion = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        // Controlliamo lo stato all'avvio senza forzare
        checkAuthorization()
    }
    
    // *** QUESTA È LA FUNZIONE CHE MANCAVA E CHE RISOLVE L'ERRORE IN CONTENTVIEW ***
    func enableLocation() {
        print("🔘 Richiesta attivazione GPS in corso...")
        switch manager.authorizationStatus {
        case .notDetermined:
            print("❓ Stato: Non determinato. Chiedo il permesso...")
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("⛔️ Stato: Negato. Suggerisco impostazioni...")
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ Stato: Già autorizzato. Avvio aggiornamenti.")
            manager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func centerMapOnUser() {
        guard let location = userLocation else { return }
        withAnimation {
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            print("ℹ️ CheckAuth: Utente deve ancora decidere.")
            break
        case .restricted, .denied:
            print("❌ CheckAuth: Permesso negato.")
            DispatchQueue.main.async {
                self.permissionDenied = true
                self.userLocation = nil
            }
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ CheckAuth: Permesso concesso.")
            DispatchQueue.main.async {
                self.permissionDenied = false
            }
            manager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location
            self.permissionDenied = false
            
            if !self.hasSetInitialRegion {
                withAnimation {
                    self.region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
                self.hasSetInitialRegion = true
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("🔥 Errore GPS: \(error.localizedDescription)")
    }
}
