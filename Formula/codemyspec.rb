# Homebrew formula for the CodeMySpec loop (macOS, Apple silicon).
#
# Installs the plain `mix release` tarball that `just package` builds (bundled
# ERTS, no Elixir/Erlang needed) and exposes it as the `workflow` command.
# A template: `just release` fills in 3.0.6, https://github.com/Code-My-Spec/workflow/releases/download/v3.0.6/codemyspec-darwin-arm64.tar.gz and b49d4357f5328b6f0cbc2926ac9b7ffec1358c1cc8e3f83c7f7c1395f2a2459e and
# writes the result to the tap (see packaging/README.md).
class Codemyspec < Formula
  desc "CodeMySpec loop: runs agents on works, dials the CodeMySpec server"
  homepage "https://codemyspec.com"
  version "3.0.6"
  url "https://github.com/Code-My-Spec/workflow/releases/download/v3.0.6/codemyspec-darwin-arm64.tar.gz"
  sha256 "b49d4357f5328b6f0cbc2926ac9b7ffec1358c1cc8e3f83c7f7c1395f2a2459e"

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
