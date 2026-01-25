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
    private let persistenceService: DataPersistenceServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private var latestFrame: CVPixelBuffer?

    // MARK: - Initialization

    init(
        cameraService: CameraService = CameraService(),
        persistenceService: DataPersistenceServiceProtocol = FileSystemDataPersistenceService()
    ) {
        self.cameraService = cameraService
        self.persistenceService = persistenceService

        setupBindings()
    }

    // MARK: - Public Methods

    /// Start camera
    func startCamera() {
        Task {
            do {
                try await cameraService.setupAndStart()
            } catch {
                await MainActor.run {
                    errorMessage = "カメラの起動に失敗しました"
                }
            }
        }
    }

    /// Stop camera
    func stopCamera() {
        cameraService.stop()
    }

    /// Capture photo
    func capturePhoto() {
        guard let frame = latestFrame else {
            errorMessage = "カメラの映像を取得できませんでした"
            return
        }

        isProcessing = true

        // Convert frame to JPEG data for storage
        let ciImage = CIImage(cvPixelBuffer: frame)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            errorMessage = "画像の作成に失敗しました"
            isProcessing = false
            return
        }

        let uiImage = UIImage(cgImage: cgImage)
        guard let photoData = uiImage.jpegData(compressionQuality: 0.8) else {
            errorMessage = "画像の変換に失敗しました"
            isProcessing = false
            return
        }

        // Store photo data
        capturedPhotoData = photoData
        isProcessing = false
        HapticFeedback.success()
    }

    /// Save diary
    func saveDiary(completion: @escaping (Bool) -> Void) {
        guard Validator.isValidDiaryText(diaryText) else {
            errorMessage = "日記の内容を入力してください"
            completion(false)
            return
        }

        guard let photoData = capturedPhotoData else {
            errorMessage = "写真が撮影されていません"
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
                    self.errorMessage = "日記の保存に失敗しました"
                    HapticFeedback.error()
                    completion(false)
                }
            }
        }
    }

    /// Update mood
    func updateMood(_ mood: Mood) {
        selectedMood = mood
        // Set mood scores
        moodScores = [mood: 1.0]
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
}
