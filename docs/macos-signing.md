# Signing and notarizing Last Train Out for macOS

One workflow, **macOS app** (`.github/workflows/macos-app.yml`), produces two kinds of build:

| Build | When | What you get |
| --- | --- | --- |
| **Development** | every push to the development branch, or *Run workflow* | `LastTrainOut-macos-universal.zip`: the app, ad-hoc signed. Needs no credentials. macOS asks for confirmation the first time it is opened. |
| **Signed** | only when you start the workflow by hand and tick **Sign with Developer ID and notarize** | `LastTrainOut-macos-universal-signed.zip`: the same app signed with your Developer ID, notarized by Apple and stapled. Opens on any Mac with no warning. |

The signed build is an extra job at the end of the same run. It never runs on a push. Until its
secrets exist it stops at its first step and says which secret is missing; the development build
from that run is still produced and can still be downloaded.

## What the signing job does

1. Checks that the credentials exist (only that they are set; values are never printed).
2. Downloads the development build that the earlier jobs in the same run tested and launched.
   What gets signed is exactly what was tested.
3. Imports your certificate into a temporary keychain that exists only on that runner.
4. Signs the executable and the bundle with **Developer ID Application**, a secure timestamp and
   the **hardened runtime** (required for notarization).
5. Launches the signed app twice in self-test mode (without and with its window), to prove the
   hardened build still works.
6. Sends it to Apple's notary service and waits for the verdict, printing Apple's log.
7. **Staples** the ticket to the app and checks that Gatekeeper accepts it (`spctl`).
8. Zips the app, checks the ZIP against the bundle, and uploads it as
   **LastTrainOut-macos-universal-signed.zip**.
9. Deletes the temporary keychain.

If signing, notarization or stapling fails, the job fails and no signed ZIP is uploaded. Nothing
is skipped or worked around.

## What you need to set up (once)

Requires an active Apple Developer Program membership. Do all of this yourself: these are your
credentials and they should never be pasted into a chat, an issue or a commit.

The secret names are the same as TIDEBORN's, so the same certificate and notary credentials can
be reused. GitHub secrets belong to one repository, though: they have to be added to this
repository as well (or be organization secrets shared with it).

### 1. A Developer ID Application certificate, exported as a .p12

On your Mac:

1. Open **Xcode → Settings → Accounts**, select your Apple ID and team, **Manage Certificates…**,
   click **+** and choose **Developer ID Application**. (Only the Account Holder of the team can
   create this type.) If you already have one in Keychain Access, skip this.
2. Open **Keychain Access → login → My Certificates**. Find
   **Developer ID Application: Your Name (TEAMID)**, and check it has a private key under it.
3. Right-click it → **Export…** → format **Personal Information Exchange (.p12)**. Choose a strong
   export password and remember it.
4. In Terminal, turn the file into text and copy it to the clipboard:

   ```bash
   base64 -i ~/Desktop/DeveloperID.p12 | pbcopy
   ```

It must be a **Developer ID Application** certificate. "Apple Development", "Apple Distribution"
and "Mac App Distribution" certificates cannot be used for apps distributed outside the App Store.

### 2. Credentials for the notary service - choose ONE of these

**Option A (recommended): an App Store Connect API key.** It is not tied to your Apple ID password
and can be revoked on its own.

1. Go to App Store Connect → **Users and Access → Integrations → App Store Connect API → Team Keys**.
2. Create a key with the **Developer** role. Note the **Key ID** and the **Issuer ID** shown on the page.
3. Download the `AuthKey_XXXXXXXXXX.p8` file (it can only be downloaded once), then:

   ```bash
   base64 -i ~/Downloads/AuthKey_XXXXXXXXXX.p8 | pbcopy
   ```

**Option B: your Apple ID with an app-specific password.**

1. At https://account.apple.com → **Sign-In and Security → App-Specific Passwords**, create one
   named e.g. "Last Train Out notarization". This is not your normal Apple ID password.
2. Find your 10-character **Team ID** at https://developer.apple.com/account under Membership details.

### 3. Add them as encrypted repository secrets

In the repository: **Settings → Secrets and variables → Actions → New repository secret**.
GitHub encrypts them; they cannot be read back, only replaced.

| Secret name | Value | Needed |
| --- | --- | --- |
| `MACOS_CERTIFICATE_P12_BASE64` | the base64 text of the .p12 (step 1.4) | always |
| `MACOS_CERTIFICATE_PASSWORD` | the export password you chose for the .p12 | always |
| `APPLE_API_KEY_P8_BASE64` | the base64 text of the .p8 key | Option A |
| `APPLE_API_KEY_ID` | the Key ID | Option A |
| `APPLE_API_ISSUER_ID` | the Issuer ID | Option A |
| `APPLE_ID` | your Apple ID email | Option B |
| `APPLE_APP_SPECIFIC_PASSWORD` | the app-specific password | Option B |
| `APPLE_TEAM_ID` | your Team ID | Option B |

Set either the three Option A secrets or the three Option B secrets. If both are set, the API key
is used.

After adding them, delete the `.p12` and `.p8` files from your Desktop/Downloads, or keep them
somewhere safe such as a password manager. Never add them to the repository.

### 4. Run it

1. Open **Actions → macOS app → Run workflow**.
2. Choose the branch to build (the development branch).
3. Tick **Sign with Developer ID and notarize** and press **Run workflow**.

When the run finishes, download **LastTrainOut-macos-universal-signed.zip** from the run's
Artifacts, unzip it and open the app. It should open with no Gatekeeper warning. The run's
summary page shows the ZIP's SHA-256.

## How the credentials are protected

- Nothing secret is in the repository: no certificate, key, password or team identifier. The
  export preset (`export_presets.cfg`) uses ad-hoc signing and holds no identity.
- Secrets are referenced only by the signing job, only passed to the steps that need them as
  environment variables, and GitHub masks them in logs. The workflow checks that they exist but
  never prints them.
- The signing job runs only when someone with write access starts the workflow by hand and
  ticks the box. Pushes never run it, and the workflow has no pull-request trigger, so code from
  a branch cannot reach the secrets on its own.
- The certificate is decoded to a temporary file, imported into a keychain with a random password
  that exists only for that job, and both are deleted afterwards. The runner itself is destroyed
  when the job ends.
- For an extra lock, put the secrets in a GitHub **Environment** with required reviewers and add
  `environment: <name>` to the `sign` job, so every signed build needs your approval.

## If something fails

- **"Missing repository secret ..."** - the secret named in the message is not set in this
  repository. Add it (step 3) and run the workflow again.
- **"not a 'Developer ID Application' certificate with its private key"** - the .p12 holds the
  wrong certificate type, or was exported without its private key. Re-export from *My Certificates*.
- **Notarization "Invalid"** - the step prints Apple's log, which names the problem. The usual
  causes are a missing hardened runtime, a missing secure timestamp, or an unsigned binary.
- **The signed app fails its self-test but the development build passes** - the hardened runtime
  is blocking something. `tools/macos/entitlements.plist` is empty on purpose (a plain GDScript
  game on the standard Godot template needs no exceptions); add only the specific entitlement the
  failure points to.
- **HTTP 401/403 from notarytool** - wrong key/issuer IDs, a revoked key, or new Apple Developer
  agreements waiting to be accepted at developer.apple.com.

## Status

The signing job has been written but **has not been run with real credentials**: it cannot run
without yours. What has been exercised is the part before any credential is used - with no
secrets configured, the job stops at its first step and lists what is missing, and the
development build of the same run stays available. The signing, notarization and stapling
commands are Apple's standard tools and follow the same steps as TIDEBORN's release workflow;
the first run with your credentials is the real test.
