import SwiftUI

/// Shown whenever the user is not logged in.
/// Switches between Login and Sign Up depending on whether an account exists.
struct AuthView: View {
    @EnvironmentObject var dataStore: DataStore

    /// If no account has been created yet, start on sign-up; otherwise login.
    @State private var mode: Mode
    @State private var name            = ""
    @State private var email           = ""
    @State private var password        = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @FocusState private var focused: Field?

    enum Mode  { case login, signUp }
    enum Field { case name, email, password, confirmPassword }

    init(startOnSignUp: Bool = false) {
        _mode = State(initialValue: startOnSignUp ? .signUp : .login)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────
                VStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                    Text("FocusTrack")
                        .font(.largeTitle.bold())
                    Text(mode == .login ? "Welcome back" : "Create your parent account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 36)

                // ── Fields ────────────────────────────────────────────
                VStack(spacing: 14) {
                    if mode == .signUp {
                        AuthField(label: "Your Name", placeholder: "e.g. Sarah Connor",
                                  text: $name, icon: "person.fill", autocap: .words)
                            .focused($focused, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focused = .email }
                    }

                    AuthField(label: "Email", placeholder: "you@example.com",
                              text: $email, icon: "envelope.fill",
                              keyboardType: .emailAddress, autocap: .never)
                        .focused($focused, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focused = .password }

                    AuthField(label: "Password",
                              placeholder: mode == .login ? "Your password" : "Minimum 6 characters",
                              text: $password, icon: "lock.fill", isSecure: true)
                        .focused($focused, equals: .password)
                        .submitLabel(mode == .login ? .done : .next)
                        .onSubmit {
                            if mode == .login { submit() }
                            else { focused = .confirmPassword }
                        }

                    if mode == .signUp {
                        AuthField(label: "Confirm Password", placeholder: "Repeat your password",
                                  text: $confirmPassword, icon: "lock.fill", isSecure: true)
                            .focused($focused, equals: .confirmPassword)
                            .submitLabel(.done)
                            .onSubmit { submit() }
                    }
                }
                .padding(.horizontal, 24)

                // ── Error ─────────────────────────────────────────────
                if let error = errorMessage {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // ── Primary button ────────────────────────────────────
                Button(action: submit) {
                    Text(mode == .login ? "Log In" : "Create Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // ── Toggle mode ───────────────────────────────────────
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        toggleMode()
                    }
                } label: {
                    (mode == .login
                        ? Text("Don't have an account? ").foregroundColor(.secondary)
                            + Text("Sign Up").bold().foregroundColor(.blue)
                        : Text("Already have an account? ").foregroundColor(.secondary)
                            + Text("Log In").bold().foregroundColor(.blue)
                    )
                    .font(.subheadline)
                }
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onTapGesture { focused = nil }
        .onAppear {
            // If no account exists yet, jump straight to sign-up
            if dataStore.account == nil { mode = .signUp }
        }
    }

    // MARK: - Helpers

    private func toggleMode() {
        mode = (mode == .login) ? .signUp : .login
        errorMessage = nil
        name = ""; password = ""; confirmPassword = ""
    }

    private func submit() {
        focused = nil
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedName  = name.trimmingCharacters(in: .whitespaces)

        if mode == .login {
            guard !trimmedEmail.isEmpty, !password.isEmpty else {
                errorMessage = "Please enter your email and password."
                return
            }
            if !dataStore.login(email: trimmedEmail, password: password) {
                errorMessage = "Incorrect email or password."
            }
        } else {
            if trimmedName.isEmpty            { errorMessage = "Please enter your name."; return }
            if trimmedEmail.isEmpty           { errorMessage = "Please enter your email."; return }
            if !trimmedEmail.contains("@")    { errorMessage = "Please enter a valid email address."; return }
            if password.count < 6             { errorMessage = "Password must be at least 6 characters."; return }
            if password != confirmPassword    { errorMessage = "Passwords don't match."; return }

            if let err = dataStore.createAccount(name: trimmedName, email: trimmedEmail, password: password) {
                errorMessage = err
            }
        }
    }
}

// MARK: - Auth Field

private struct AuthField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocap)
                        .autocorrectionDisabled(keyboardType == .emailAddress)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
    }
}
