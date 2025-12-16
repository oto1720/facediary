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
        isProcessing = true
        cameraService.takePhoto()
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
        // Setup camera photo publisher
        cameraService.photoPublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to capture photo: \(error.localizedDescription)"
                        self?.isProcessing = false
                        HapticFeedback.error()
                    }
                },
                receiveValue: { [weak self] photoData in
                    self?.capturedPhotoData = photoData
                    self?.analyzeFaceAndMood(from: photoData)
                }
            )
            .store(in: &cancellables)
    }

    private func loadReferenceFaceData() {
        do {
            self.referenceFaceData = try securityService.loadFaceData()
        } catch {
            print("Failed to load reference face data: \(error.localizedDescription)")
        }
    }

    /// Analyze face and mood
    private func analyzeFaceAndMood(from photoData: Data) {
        guard let referenceFaceData = referenceFaceData else {
            errorMessage = "No reference face data"
            isProcessing = false
            return
        }

        guard let uiImage = UIImage(data: photoData),
              let ciImage = CIImage(image: uiImage) else {
            errorMessage = "Failed to create CIImage"
            isProcessing = false
            return
        }

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
