//
//  PodMenuView.swift
//  podAppFPv1.00
//
//  Created by S R on 3/27/26.
//


import SwiftUI
import AVFoundation

struct PodMenuView: View {
    @Binding var selectedScanType: ScanType?
    @Binding var scannedItems: [ScanItem]
    @Binding var showScanner: Bool
    @Binding var cameraPosition: AVCaptureDevice.Position
    @Binding var failedQueue: [PendingUpload]
    @Binding var vehicleRegistration: String
    @Binding var selectedCourier: String
    @Binding var scannedAWB: String
    @Binding var retryingUploadIDs: Set<UUID>
    @Binding var retryStatusByID: [UUID: String]

    var onResumeFailedUpload: (PendingUpload) -> Void
    var onRetryFailedUpload: (PendingUpload) -> Void
    var onDeleteFailedUpload: (PendingUpload) -> Void
    var onStartFreshSession: () -> Void

    @State private var showAWBScanner = false
    @State private var awbCameraPosition: AVCaptureDevice.Position = .back
    @State private var showCourierList = false
    @State private var menuScrollPosition: ScanType? = nil
    
    private let couriers = [
        "ANYVAN", "CITYSPRINT", "DHL", "FEDEX", "HERMES", "JEAVONS",
        "KUEHNE AND NAGEL", "MENZIES PARCELS", "MFC", "MPD",
        "PARCELFORCE", "PARCEL MONKEY", "ROYAL MAIL", "STEDER",
        "TNT", "UPS", "YODEL", "OTHER"
    ]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private var isScanButtonEnabled: Bool {
        guard let selectedScanType else { return false }

        switch selectedScanType {
        case .outForDelivery:
            return !vehicleRegistration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .shippedByCourier:
            return !selectedCourier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                topSection
                failedQueueSection
            }
            .padding(20)

            if showAWBScanner {
                awbScannerOverlay
            }
        }
    }

    private var topSection: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 20) {
                menuCard
                    .frame(width: geometry.size.width * 0.48, height: 420, alignment: .topLeading)

                additionalInputCard
                    .frame(width: geometry.size.width * 0.22, height: 420, alignment: .topLeading)

                currentSessionCard
                    .frame(width: geometry.size.width * 0.26, height: 420, alignment: .topLeading)
            }
        }
        .frame(height: 420)
    }

    private var menuCard: some View {
        VStack(alignment: .center, spacing: 18) {
            Text("MENU")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)

            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(ScanType.allCases) { scanType in
                            VStack(spacing: 6) {
                                Text(scanType.rawValue)
                                    .font(.title2)
                                    .fontWeight(selectedScanType == scanType ? .bold : .regular)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(
                                selectedScanType == scanType
                                ? AnyShapeStyle(FPTheme.primaryGradient.opacity(0.22))
                                : AnyShapeStyle(Color.clear)
                            )
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                            .id(scanType)
                        }
                    }
                    .padding(.bottom, 180)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $menuScrollPosition, anchor: .top)
                .onAppear {
                    menuScrollPosition = selectedScanType
                }
                .onChange(of: menuScrollPosition) { _, newValue in
                    guard let newValue else { return }
                    selectedScanType = newValue
                }
                .onChange(of: selectedScanType) { _, newValue in
                    guard let newValue else { return }

                    menuScrollPosition = newValue

                    if newValue != .outForDelivery {
                        vehicleRegistration = ""
                    }

                    if newValue != .shippedByCourier {
                        selectedCourier = ""
                        scannedAWB = ""
                        showCourierList = false
                    }
                }

                RoundedRectangle(cornerRadius: 12)
                    .stroke(FPTheme.brandOrange.opacity(0.55), lineWidth: 2)
                    .frame(height: 70)
                    .allowsHitTesting(false)
            }

            Button(action: {
                guard isScanButtonEnabled else { return }

                onStartFreshSession()
                cameraPosition = .back

                let hasExistingSession = !scannedItems.isEmpty
                let isSameSessionType = scannedItems.allSatisfy { $0.scanType == selectedScanType }

                if !hasExistingSession || isSameSessionType {
                    showScanner = true
                } else {
                    scannedItems = []
                    vehicleRegistration = ""
                    selectedCourier = ""
                    scannedAWB = ""
                    showScanner = true
                }
            }) {
                Text("SCAN POD")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(width: 170)
                    .padding(.vertical, 12)
                    .background(
                        isScanButtonEnabled
                        ? AnyShapeStyle(FPTheme.buttonBackground)
                        : AnyShapeStyle(FPTheme.disabledButtonBackground)
                    )
                    .foregroundColor(isScanButtonEnabled ? .black : .gray)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(!isScanButtonEnabled)
        }
        .padding(24)
        .background(FPTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: FPTheme.softShadow, radius: 10, x: 0, y: 4)
    }

    private var additionalInputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ADDITIONAL INPUT")
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if selectedScanType == .outForDelivery {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enter vehicle registration")
                        .font(.headline)

                    TextField("Vehicle registration", text: $vehicleRegistration)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(FPTheme.subtleBorder.opacity(0.4))
                        .cornerRadius(10)
                }
            } else if selectedScanType == .shippedByCourier {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select courier")
                        .font(.headline)

                    Button(action: {
                        showCourierList.toggle()
                    }) {
                        HStack {
                            Text(selectedCourier.isEmpty ? "Choose courier" : selectedCourier)
                                .foregroundColor(selectedCourier.isEmpty ? .gray : .black)
                            Spacer()
                            Image(systemName: showCourierList ? "chevron.up" : "chevron.down")
                                .foregroundColor(.black)
                        }
                        .padding(12)
                        .background(FPTheme.subtleBorder.opacity(0.4))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    if showCourierList {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(couriers, id: \.self) { courier in
                                    HStack {
                                        Text(courier)
                                            .foregroundColor(.black)

                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedCourier = courier
                                        showCourierList = false
                                    }

                                    Divider()
                                }
                            }
                        }
                        .frame(height: 180)
                        .background(FPTheme.background)
                        .cornerRadius(10)
                    }

                    Button(action: {
                        awbCameraPosition = .back
                        showAWBScanner = true
                    }) {
                        Text("SCAN AWB")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(FPTheme.buttonBackground)
                            .foregroundColor(FPTheme.buttonText)
                            .shadow(
                                color: FPTheme.softShadow,
                                radius: 6,
                                x: 0,
                                y: 3
                            )
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    if !scannedAWB.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Scanned AWB")
                                .font(.headline)

                            Text(scannedAWB)
                                .font(.subheadline)
                                .foregroundColor(FPTheme.graphite)
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(FPTheme.subtleBorder.opacity(0.4))
                                .cornerRadius(10)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No additional input required for this status.")
                        .foregroundColor(FPTheme.graphite)

                    Spacer()
                }
            }

            Spacer()
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: FPTheme.softShadow, radius: 10, x: 0, y: 4)
    }

    private var currentSessionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CURRENT SESSION")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if !scannedItems.isEmpty {
                    Text("\(scannedItems.count)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(FPTheme.primaryGradient.opacity(0.25))
                        .cornerRadius(10)
                }
            }

            if scannedItems.isEmpty {
                Text("No active scans")
                    .foregroundColor(FPTheme.graphite)
            } else {
                Text("Tap a scanned item to return to scanning.")
                    .font(.caption)
                    .foregroundColor(FPTheme.graphite)

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(scannedItems.enumerated()), id: \.element.id) { index, item in
                            Button(action: {
                                cameraPosition = .back
                                showScanner = true
                            }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("#\(index + 1)")
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)

                                        Spacer()

                                        Text(item.scanType.rawValue)
                                            .font(.caption)
                                            .foregroundColor(FPTheme.graphite)
                                    }

                                    Text(item.code)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.75)
                                        .textSelection(.enabled)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(FPTheme.background)
                                .cornerRadius(12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(24)
        .background(FPTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: FPTheme.softShadow, radius: 10, x: 0, y: 4)
    }

    private var failedQueueSection: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Text("\(failedQueue.count) item(s)")
                    .foregroundColor(FPTheme.graphite)
            }

            if failedQueue.isEmpty {
                Text("No failed uploads")
                    .foregroundColor(FPTheme.graphite)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                failedQueueTable
            }
        }
        .padding(24)
        .padding(.top, 52)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(FPTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: FPTheme.softShadow, radius: 10, x: 0, y: 4)
        .overlay(alignment: .top) {
            ZStack {
                Rectangle()
                    .fill(FPTheme.darkGradient)

                Text("FAILED QUEUE")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            .frame(height: 52)
            .clipShape(
                RoundedCorner(radius: 16, corners: [.topLeft, .topRight])
            )
        }
        .clipped()
    }

    private var failedQueueTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Created")
                    .frame(width: 130, alignment: .leading)
                Text("Status")
                    .frame(width: 180, alignment: .leading)
                Text("Extra Input")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Items")
                    .frame(width: 60, alignment: .leading)
                Text("Retry Status")
                    .frame(width: 110, alignment: .leading)
                Text("Actions")
                    .frame(width: 250, alignment: .leading)
            }
            .font(.headline)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(failedQueue) { item in
                        HStack {
                            Text(dateFormatter.string(from: item.createdAt))
                                .frame(width: 130, alignment: .leading)

                            Text(item.selectedScanType.rawValue)
                                .frame(width: 180, alignment: .leading)
                                .lineLimit(1)

                            Text(extraInputSummary(for: item))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                                .foregroundColor(FPTheme.graphite)

                            Text("\(item.scannedItems.count)")
                                .frame(width: 60, alignment: .leading)

                            retryStatusView(for: item)
                                .frame(width: 110, alignment: .leading)

                            HStack(spacing: 8) {
                                Button("Resume") {
                                    onResumeFailedUpload(item)
                                }
                                .buttonStyle(.bordered)

                                Button("Retry") {
                                    onRetryFailedUpload(item)
                                }
                                .buttonStyle(.bordered)
                                .disabled(retryingUploadIDs.contains(item.id))

                                Button("Delete") {
                                    onDeleteFailedUpload(item)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                                .disabled(retryingUploadIDs.contains(item.id))
                            }
                            .frame(width: 250, alignment: .leading)
                        }
                        .font(.subheadline)
                        .padding(.vertical, 10)

                        Divider()
                    }
                }
            }
        }
    }

    private func extraInputSummary(for item: PendingUpload) -> String {
        if !item.vehicleRegistration.isEmpty {
            return "Vehicle: \(item.vehicleRegistration)"
        }

        if !item.selectedCourier.isEmpty && !item.scannedAWB.isEmpty {
            return "\(item.selectedCourier) • AWB: \(item.scannedAWB)"
        }

        if !item.selectedCourier.isEmpty {
            return item.selectedCourier
        }

        if !item.scannedAWB.isEmpty {
            return "AWB: \(item.scannedAWB)"
        }

        return "-"
    }

    @ViewBuilder
    private func retryStatusView(for item: PendingUpload) -> some View {
        if retryingUploadIDs.contains(item.id) {
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Retrying...")
                    .foregroundColor(FPTheme.graphite)
            }
        } else {
            Text(retryStatusByID[item.id] ?? "-")
                .foregroundColor(
                    retryStatusByID[item.id] == "Success" ? .green :
                    retryStatusByID[item.id] == "Failed again" ? .red : .gray
                )
        }
    }

    private var awbScannerOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("SCAN AWB")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        showAWBScanner = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)

                    QRScannerView(cameraPosition: $awbCameraPosition) { code in
                        scannedAWB = code.trimmingCharacters(in: .whitespacesAndNewlines)
                        showAWBScanner = false
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Text("Point the camera at the AWB code")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title3)
            }
            .padding(20)
            .frame(width: 1000, height: 650)
            .background(Color.gray.opacity(0.9))
            .cornerRadius(16)
            .shadow(color: FPTheme.softShadow, radius: 10, x: 0, y: 4)
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
