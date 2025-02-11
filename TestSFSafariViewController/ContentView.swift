//
//  ContentView.swift
//  TestSFSafariViewController
//
//  Created by Xuan Thinh on 10/2/25.
//

import SwiftUI
import SafariServices

struct ContentView: View {
    
    private var server: WebServer = WebServer()
    
    @State private var serverPort: in_port_t = 0
    
    
    var body: some View {
        NavigationView {
            VStack {

//                let urlString = "http://localhost:\(port)/index.html"
                
                
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                    .padding()

                NavigationLink(destination: MyTestSafariViewControllerWrapper(port: self.serverPort)) {
                    Text("Open Safari")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Main View")
        }
        .onAppear {
            self.server.run()
            self.serverPort = self.server.listeningPort
        }
    }
}

struct SafariViewWrapper: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: SafariViewWrapper

        init(_ parent: SafariViewWrapper) {
            self.parent = parent
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            controller.dismiss(animated: true)
        }
    }
}


// Wrapper for better NavigationLink integration
struct MyTestSafariViewControllerWrapper: View {
    let port: in_port_t
    
    var body: some View {
        SafariViewWrapper(url: URL(string: self.urlString) ?? URL(fileURLWithPath: ""))
            .ignoresSafeArea() // Safari view typically takes the full screen
            .navigationBarHidden(true)
            .onAppear {
                print(self.urlString)
            }
    }
    
    var urlString: String {
        return "http://localhost:\(port)/index.html"
    }
}

