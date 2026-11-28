# Homebrew formula for the CodeMySpec loop (macOS, Apple silicon).
#
# Installs the plain `mix release` tarball that `just package` builds (bundled
# ERTS, no Elixir/Erlang needed) and exposes it as the `workflow` command.
# A template: its url and sha256 are the only lines to fill in (`just release`
# fills https://github.com/Code-My-Spec/workflow/releases/download/v3.0.18/codemyspec-darwin-arm64.tar.gz and 99eb02f5ea88e33ef29b931339ba3adbc3ac74dba6fe32593482e4044c6e314f and writes the result to the tap; see
# packaging/README.md). Homebrew reads the version from the url's v<version>.
class Codemyspec < Formula
  desc "CodeMySpec loop: runs agents on works, dials the CodeMySpec server"
  homepage "https://codemyspec.com"
  url "https://github.com/Code-My-Spec/workflow/releases/download/v3.0.18/codemyspec-darwin-arm64.tar.gz"
  sha256 "99eb02f5ea88e33ef29b931339ba3adbc3ac74dba6fe32593482e4044c6e314f"

  depends_on arch: :arm64
  depends_on "git"
  depends_on "just"
  # The release's crypto NIF links Homebrew's OpenSSL.
  depends_on "openssl@3"

  def install
    # The tarball extracts to bin/, lib/, releases/, erts-*.
    libexec.install Dir["*"]
    # A wrapper, not a symlink, so the launcher resolves its root from libexec.
    (bin/"workflow").write <<~SH
      #!/bin/bash
      exec "#{libexec}/bin/workflow" "$@"
    SH
    chmod 0755, bin/"workflow"
  end

  service do
    run [opt_bin/"workflow", "start"]
    keep_alive true
    # launchd gives a bare PATH; the loop shells out to `claude`, `git` and `just`.
    environment_variables PATH: "#{HOMEBREW_PREFIX}/bin:#{Dir.home}/.local/bin:/usr/bin:/bin"
    log_path var/"log/codemyspec.log"
    error_log_path var/"log/codemyspec.log"
  end

  def caveats
    <<~EOS
      Sign the loop in to its server, once ~/.workflow/config.json names it:
        workflow sign-in

      Install Claude Code (the `claude` command) yourself; brew does not provide it:
        curl -fsSL https://claude.ai/install.sh | bash
      then run `claude` once to sign in.

      The loop listens on 127.0.0.1:4010; set WORKFLOW_PORT to change it.
    EOS
  end

  test do
    assert_match "workflow", shell_output("#{bin}/workflow version")
  end
end
