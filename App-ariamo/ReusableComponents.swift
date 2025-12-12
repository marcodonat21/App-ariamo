import SwiftUI
import UIKit

// --- COMPONENTI UI RIUTILIZZABILI ---

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.system(.body, design: .rounded)) // FONT ARROTONDATO
        .padding()
        .background(Color.white) // SFONDO BIANCO
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2) // Ombra leggera per stacco
        .padding(.horizontal, 40)
    }
}

// Bottone Sociale Grande (Usato in AuthLandingScreen per Login/Sign up con terze parti)
struct SocialButton: View {
    var text: String
    var icon: String
    var color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                Text(text)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(30)
            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 2)
        }
        .padding(.horizontal, 40)
    }
}

// NUOVO: Bottone Sociale Piccolo (Usato in AuthLandingScreen per l'HStack dei social)
struct SocialButtonSmall: View {
    let icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.title)
            .foregroundColor(.black)
            .padding()
            .background(Color.inputGray)
            .clipShape(Circle())
    }
}

// Bottone per la selezione del Genere
struct GenderButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(isSelected ? .white : .gray)
                .padding()
                .frame(width: 100)
                .background(isSelected ? Color.appMint : Color.inputGray) // appMint da AppConstants
                .cornerRadius(20)
        }
    }
}

// --- PREVIEWS ---

struct ReusableComponents_Previews: PreviewProvider {
    @State static var testText = "Esempio"
    
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Test CustomTextField:")
            CustomTextField(placeholder: "Email", text: $testText)
            CustomTextField(placeholder: "Password", text: $testText, isSecure: true)
            
            Text("Test SocialButton:")
            SocialButton(text: "Connect with Google", icon: "g.circle.fill", color: .red)
            
            Text("Test GenderButton:")
            HStack {
                GenderButton(title: "Man", isSelected: true) {}
                GenderButton(title: "Woman", isSelected: false) {}
            }
            
            Text("Test SocialButtonSmall:")
            SocialButtonSmall(icon: "applelogo")
            
        }
        .padding(.top, 50)
        .background(Color.white)
    }
}

// --- COMPONENTE FOTOCAMERA ---
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera // Apre la fotocamera
        picker.allowsEditing = true // Permette di ritagliare (quadrato)
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
