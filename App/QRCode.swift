import CoreImage.CIFilterBuiltins

enum QRCode {
    /// Rendered large with hard edges, so it stays sharp when a view scales it down.
    static func image(for text: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = (600 / output.extent.width).rounded(.up)
        let image = output.samplingNearest().transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return CIContext().createCGImage(image, from: image.extent)
    }
}
