import SwiftUI
import MessageUI

/// Shared mail composition view for feedback and support
struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    let toRecipients: [String]
    let subject: String
    let body: String
    let completion: (Result<Void, Error>) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(toRecipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.completion(.failure(error))
            } else {
                parent.completion(.success(()))
            }
            parent.presentation.wrappedValue.dismiss()
        }
    }
} 