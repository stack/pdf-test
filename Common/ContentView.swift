//
//  ContentView.swift
//  PDF Test
//
//  Created by Stephen Gerstacker on 2022-09-09.
//

import PDFKit
import SwiftUI

struct ContentView: View {
    
    @State var renderedImage: NativeImage? = nil
    @State var renderedURL: URL? = nil
    
    var body: some View {
        VStack {
            if let url = renderedURL {
                PDFPreviewView(url: url)
                    .frame(maxHeight: .infinity)
            } else {
                Image(systemName: "doc.text")
                    .frame(maxHeight: .infinity)
            }
            
            if let image = renderedImage {
                Image(nativeImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: .infinity)
            } else {
                Image(systemName: "clock")
                    .frame(maxHeight: .infinity)
            }
            
            Button {
                let pdfRenderer = Renderer()
                renderedURL = pdfRenderer.renderPDF()
                
                let imageRenderer = Renderer()
                renderedImage = imageRenderer.renderImage()
            } label: {
                Text("Render")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
    }
}

extension Image {
    
    init(nativeImage: NativeImage) {
        #if os(macOS)
        self.init(nsImage: nativeImage)
        #else
        self.init(uiImage: nativeImage)
        #endif
    }
}

#if os(macOS)
struct PDFPreviewView: NSViewRepresentable {
    let url: URL?
    
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
    
        if let url = url {
            view.document = PDFDocument(url: url)
        }
        
        view.scaleFactor = view.scaleFactorForSizeToFit
        
        return view
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if let url = url {
            nsView.document = PDFDocument(url: url)
        }
    }
}
#else
struct PDFPreviewView: UIViewRepresentable {
    let url: URL?
    
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
    
        if let url = url {
            view.document = PDFDocument(url: url)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let url = url {
            uiView.document = PDFDocument(url: url)
        }
    }
}
#endif

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
