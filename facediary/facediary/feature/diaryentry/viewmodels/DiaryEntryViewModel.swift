import SwiftUI
import Combine
import AVFoundation

/// Diary entry view model
class DiaryEntryViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Diary text
    @Published var diaryText: String = ""

    /// Captured photo data
    @Published var capturedPhotoData: Data?

    /// Mood scores
    @Published var moodScores: [Mood: Double] = [:]

    /// Selected mood
    @Published var selectedMood: Mood?

    /// Is processing
    @Published var isProcessing: Bool = false

    /// Error message
    @Published var errorMessage: String?

    /// Save succeeded
    @Published var saveSucceeded: Bool = false

    // MARK: - Services

    let cameraService: CameraService
    private let faceRecognitionService: FaceRecognitionServiceProtocol
    private let securityService: SecurityServiceProtocol
    private let persistenceService: DataPersistenceServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private var referenceFaceData: FaceData?
    private var latestFrame: CVPixelBuffer?

    // MARK: - Initialization

    init(
        cameraService: CameraService = CameraService(),
        faceRecognitionService: FaceRecognitionServiceProtocol = VisionFaceRecognitionService(),
        securityService: SecurityServiceProtocol = KeychainSecurityService(),
        persistenceService: DataPersistenceServiceProtocol = FileSystemDataPersistenceService()
    ) {
        self.cameraService = cameraService
        self.faceRecognitionService = faceRecognitionService
        self.securityService = securityService
        self.persistenceService = persistenceService

        setupBindings()
        loadReferenceFaceData()
    }

    // MARK: - Public Methods

    /// Start camera
    func startCamera() {
        Task {
            do {
                try await cameraService.setupAndStart()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to start camera: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Stop camera
    func stopCamera() {
        cameraService.stop()
    }

    /// Capture photo and analyze
    func capturePhotoAndAnalyze() {
        guard let frame = latestFrame else {
            errorMessage = "No video frame available"
            return
        }

        isProcessing = true

        // Convert frame to JPEG data for storage
        let ciImage = CIImage(cvPixelBuffer: frame)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            errorMessage = "Failed to create image"
            isProcessing = false
            return
        }

        let uiImage = UIImage(cgImage: cgImage)
        guard let photoData = uiImage.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to convert image to data"
            isProcessing = false
            return
        }

        // Store photo data
        capturedPhotoData = photoData

        // Analyze face and mood using the same frame
        analyzeFaceAndMood(from: frame)
    }

    /// Save diary
    func saveDiary(completion: @escaping (Bool) -> Void) {
        guard Validator.isValidDiaryText(diaryText) else {
            errorMessage = "Invalid diary text"
            completion(false)
            return
        }

        guard let photoData = capturedPhotoData else {
            errorMessage = "No photo data captured"
            completion(false)
            return
        }

        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Load diary entries
                var entries = try self.persistenceService.load()

                // Create new diary entry
                let newEntry = DiaryEntry(
                    date: Date(),
                    text: self.diaryText,
                    photoData: photoData,
                    moodScores: self.moodScores
                )

                // Save diary entry
                entries.insert(newEntry, at: 0)
                try self.persistenceService.save(entries: entries)

                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.saveSucceeded = true
                    HapticFeedback.success()
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "Failed to save diary: \(error.localizedDescription)"
                    HapticFeedback.error()
                    completion(false)
                }
            }
        }
    }

    /// Update mood
    func updateMood(_ mood: Mood) {
        selectedMood = mood
        // Update mood scores
        if !moodScores.isEmpty {
            // Update mood scores
            var updatedScores = moodScores
            updatedScores[mood] = 1.0
            moodScores = updatedScores
        } else {
            // Set mood scores
            moodScores = [mood: 1.0]
        }
        HapticFeedback.selection()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Setup camera frame publisher to get video frames
        cameraService.framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                self?.latestFrame = frame
            }
            .store(in: &cancellables)
    }

    private func loadReferenceFaceData() {
        do {
            self.referenceFaceData = try securityService.loadFaceData()
        } catch {
            print("Failed to load reference face data: \(error.localizedDescription)")
        }
    }

    /// Analyze face and mood from video frame
    private func analyzeFaceAndMood(from frame: CVPixelBuffer) {
        guard let referenceFaceData = referenceFaceData else {
            errorMessage = "No reference face data"
            isProcessing = false
            return
        }

        // Convert frame to CIImage (same as registration/authentication)
        let ciImage = CIImage(cvPixelBuffer: frame)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try self.faceRecognitionService.recognizeFace(
                    from: ciImage,
                    referenceFaceData: referenceFaceData
                )

                DispatchQueue.main.async {
                    if result.isAuthenticated {
                        // Update mood scores
                        self.moodScores = result.moodScores
                        self.selectedMood = MoodAnalyzer.primaryMood(from: result.moodScores)
                        self.isProcessing = false
                        HapticFeedback.success()
                    } else {
                        // Set error message
                        self.errorMessage = "Face not recognized"
                        self.capturedPhotoData = nil
                        self.isProcessing = false
                        HapticFeedback.error()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to analyze face and mood: \(error.localizedDescription)"
                    self.capturedPhotoData = nil
                    self.isProcessing = false
                    HapticFeedback.error()
                }
            }
        }
    }
}
