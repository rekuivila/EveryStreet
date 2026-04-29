import SwiftUI
import AuthenticationServices
import MapKit

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var showEmailSignIn = false
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )
    )

    var body: some View {
        ZStack {
            // Full-screen dark map background — non-interactive
            Map(position: $mapPosition)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .overlay(Color.black.opacity(0.58).ignoresSafeArea())

            VStack(spacing: 0) {
                Spacer()
                logoSection
                Spacer()
                authSection
            }
        }
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInView()
                .presentationDetents([.medium])
                .environment(authViewModel)
        }
        .alert("Sign In Error", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") { authViewModel.errorMessage = nil }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
    }

    private var logoSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 76))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 8)

            Text("Every Street")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Walk every street in your neighborhood.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 56)
    }

    private var authSection: some View {
        VStack(spacing: 14) {
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task { await authViewModel.handleAppleSignIn(result: result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 54)
            .cornerRadius(14)

            Button("Sign in with email") {
                showEmailSignIn = true
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 52)
    }
}

private struct EmailSignInView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    isLoading = true
                    Task {
                        defer { isLoading = false }
                        do {
                            try await authViewModel.signInWithEmail(email: email, password: password)
                            dismiss()
                        } catch {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Continue").fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(14)
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
