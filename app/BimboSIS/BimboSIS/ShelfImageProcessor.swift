#if canImport(UIKit)
import UIKit
import Vision
import CoreImage

enum ImageProcessorError: Error {
    case conversionFailed
    case processingFailed
}

actor ShelfImageProcessor {
    static let shared = ShelfImageProcessor()
    
    private let context = CIContext(options: nil)
    
    func processImage(_ image: UIImage) async throws -> UIImage {
        // 1. Convert to CIImage
        guard let cgImage = image.cgImage else {
            throw ImageProcessorError.conversionFailed
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // 2. Perform rectangle detection
        let rectangle = try await detectRectangle(in: cgImage)
        
        // 3. Apply perspective correction
        let processedCIImage = applyPerspectiveCorrection(to: ciImage, rectangle: rectangle)
        
        // 4. Convert back to UIImage and compress
        guard let finalCGImage = context.createCGImage(processedCIImage, from: processedCIImage.extent) else {
            throw ImageProcessorError.processingFailed
        }
        
        // Maintain original orientation if no perspective correction was applied, 
        // otherwise reset to .up since the CIImage pipeline fixes orientation natively.
        let orientation = rectangle == nil ? image.imageOrientation : .up
        let finalImage = UIImage(cgImage: finalCGImage, scale: image.scale, orientation: orientation)
        
        // 5. Compress
        guard let jpegData = finalImage.jpegData(compressionQuality: 0.8),
              let compressedImage = UIImage(data: jpegData) else {
            return finalImage // Fallback
        }
        
        return compressedImage
    }
    
    private func detectRectangle(in cgImage: CGImage) async throws -> VNRectangleObservation? {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNRectangleObservation],
                      let largestRectangle = results.max(by: { $0.boundingBox.area < $1.boundingBox.area }) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: largestRectangle)
            }
            
            // Adjust configuration for shelf detection
            request.minimumConfidence = 0.6
            request.maximumObservations = 5
            request.minimumAspectRatio = 0.2
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func applyPerspectiveCorrection(to image: CIImage, rectangle: VNRectangleObservation?) -> CIImage {
        guard let rectangle = rectangle else { return image }
        
        let imageSize = image.extent.size
        
        // Vision uses normalized coordinates (0.0 to 1.0) with origin at bottom-left
        let topLeft = CGPoint(x: rectangle.topLeft.x * imageSize.width, y: rectangle.topLeft.y * imageSize.height)
        let topRight = CGPoint(x: rectangle.topRight.x * imageSize.width, y: rectangle.topRight.y * imageSize.height)
        let bottomLeft = CGPoint(x: rectangle.bottomLeft.x * imageSize.width, y: rectangle.bottomLeft.y * imageSize.height)
        let bottomRight = CGPoint(x: rectangle.bottomRight.x * imageSize.width, y: rectangle.bottomRight.y * imageSize.height)
        
        // Apply CIPerspectiveCorrection
        let filter = CIFilter(name: "CIPerspectiveCorrection")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        filter?.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        filter?.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        filter?.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
        
        return filter?.outputImage ?? image
    }
}

extension CGRect {
    var area: CGFloat {
        return width * height
    }
}
#endif
