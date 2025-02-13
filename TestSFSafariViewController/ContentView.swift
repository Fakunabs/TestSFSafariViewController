//
//  ContentView.swift
//  TestSFSafariViewController
//
//  Created by Xuan Thinh on 10/2/25.
//

import SafariServices
import SwiftUI
import GCDWebServer

struct ContentView: View {
//    @State private var serverForWebHtml: WebServer = .init()
//    @State private var serverPort_ofWebHtml: in_port_t = 0
    
    private let webServerForHtmlFile = GCDWebServer()
    private let webServerForMobileConfigFile = GCDWebServer()
    
    @State private var portHtmlFile: in_port_t = 0
    
//    @State private var serverForFileMobileConfig: WebServer = .init()
//    @State private var serverPort_ofFileConfig: in_port_t = 0

    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Image(uiImage: UIImage(named: "vuive") ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50, alignment: .center)
                Text("Hello, world!")
                    .padding()

                NavigationLink(destination: MyTestSafariViewControllerWrapper(port: self.portHtmlFile)) {
                    Text("Open Safari")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                Button {
                    self.cloneAndModifyMobileConfig()
                } label: {
                    Text("Clone and change mobileconfig file")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Main View")
        }
        .onAppear {
            self.runServerForHtmlFileWeb()
            self.runServerForFileMobileConfig()
        }
    }
    
    func runServerForHtmlFileWeb() {
        guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") else {
            print("Không tìm thấy file HTML trong Bundle")
            return
        }
        
        self.webServerForHtmlFile.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { request in
            return GCDWebServerFileResponse(file: htmlPath)
        }
        
        do {
            try webServerForHtmlFile.start(options: [
                GCDWebServerOption_Port: 12333, // Chọn port bạn muốn
                GCDWebServerOption_BindToLocalhost: true
            ])
            print("Server is running on port \(self.webServerForHtmlFile.port)")
            let port: in_port_t = in_port_t(self.webServerForHtmlFile.port)
            self.portHtmlFile = port
        } catch {
            print("Không thể chạy server: \(error.localizedDescription)")
        }
    }

    func cloneAndModifyMobileConfig() {
        guard let originalFileURL = Bundle.main.url(forResource: "fileTest", withExtension: "mobileconfig") else {
            print("Không tìm thấy file mobileconfig gốc")
            return
        }

        do {
            let fileData = try Data(contentsOf: originalFileURL)
            guard var fileString = String(data: fileData, encoding: .utf8) else {
                print("Không thể đọc nội dung file")
                return
            }

            guard let image = UIImage(named: "vuive"),
                  let imageData = image.pngData()
            else {
                print("Không thể lấy dữ liệu ảnh")
                return
            }

            let base64Icon = imageData.base64EncodedString()

            let webClipConfig = """
            <dict>
                <key>FullScreen</key>
                <true/>
                <key>Icon</key>
                <data>
                    \(base64Icon)
                </data>
                <key>IsRemovable</key>
                <true/>
                <key>Label</key>
                <string>Facebook</string>
                <key>PayloadDescription</key>
                <string>Configures settings for Facebook web clip</string>
                <key>PayloadDisplayName</key>
                <string>Facebook Web Clip</string>
                <key>PayloadIdentifier</key>
                <string>com.example.facebook.webclip</string>
                <key>PayloadType</key>
                <string>com.apple.webClip.managed</string>
                <key>PayloadUUID</key>
                <string>\(UUID().uuidString)</string>
                <key>PayloadVersion</key>
                <integer>1</integer>
                <key>Precomposed</key>
                <true/>
                <key>URL</key>
                <string>fb://</string>
            </dict>
            """

            if let arrayRange = fileString.range(of: "<array>\n\t\t\n\t</array>") {
                fileString.replaceSubrange(arrayRange, with: "<array>\n\t\t\(webClipConfig)\n\t</array>")
            } else {
                print("Không tìm thấy vị trí chèn dữ liệu")
                return
            }
            print("File dưới dạng String là: \(fileString)")

            let newFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("fileTest_Clone.mobileconfig")
            try fileString.write(to: newFileURL, atomically: true, encoding: .utf8)
            print("File đã được lưu tại: \(newFileURL)")

            // Gợi ý mở file để cài đặt (Chỉ áp dụng trên iOS)
            DispatchQueue.main.async {
                UIApplication.shared.open(newFileURL)
            }

        } catch {
            print("Lỗi trong quá trình xử lý file: \(error.localizedDescription)")
        }
    }
    
    func runServerForFileMobileConfig() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let configFilePath = documentsDirectory.appendingPathComponent("fileTest_Clone.mobileconfig").path
        
        self.webServerForMobileConfigFile.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { request in
            if FileManager.default.fileExists(atPath: configFilePath) {
                return GCDWebServerFileResponse(file: configFilePath)
            } else {
                return GCDWebServerErrorResponse(statusCode: 404)
            }
        }
        
        do {
            try webServerForMobileConfigFile.start(options: [
                GCDWebServerOption_Port: 12321, // Chọn port bạn muốn
                GCDWebServerOption_BindToLocalhost: true
            ])
            print("ServerFileConfig is running on port \(webServerForMobileConfigFile.port)")
        } catch {
            print("Không thể chạy server: \(error.localizedDescription)")
        }
    }
    
}


struct SafariViewWrapper: UIViewControllerRepresentable {
    let url: URL
    var onDismiss: () -> Void

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator
        return safariVC
    }

    func updateUIViewController(_: SFSafariViewController, context _: Context) {}

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
            self.parent.onDismiss()
        }
    }
}

// Wrapper for better NavigationLink integration
struct MyTestSafariViewControllerWrapper: View {
    @Environment(\.dismiss) private var dismiss
    let port: in_port_t

    var body: some View {
        SafariViewWrapper(url: URL(string: self.urlString) ?? URL(fileURLWithPath: ""), onDismiss: {
            self.dismiss()
        })
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
