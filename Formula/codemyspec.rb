# Homebrew formula for CodeMySpec (macOS).
#
# Installs the plain `mix release` tarball — a self-contained OTP release (ERTS
# + start.boot on disk, no runtime extraction). `brew services` registers it
# with launchd, so there's no Shawl and no MSI on macOS.
#
# v1.5.25 / 1.5.25 / 91a71291b25018f4766d0fb947db76b1a1c0a58aa36af95264ad881a010088ce are templated by the
# release workflow (release-extension.yml) into the published copy.
class Codemyspec < Formula
  desc "CodeMySpec local server (Phoenix + MCP) on port 4003"
  homepage "https://codemyspec.com"
  version "1.5.25"
  url "https://github.com/Code-My-Spec/plugins/releases/download/v1.5.25/cms-darwin-arm64.tar.gz"
  sha256 "91a71291b25018f4766d0fb947db76b1a1c0a58aa36af95264ad881a010088ce"

  def install
    # The tarball extracts to bin/, lib/, releases/, erts-* at top level.
    libexec.install Dir["*"]
    # Expose the release launcher as `cms`. A wrapper (not a symlink) so the
    # launcher resolves RELEASE_ROOT from libexec, not the bin symlink.
    (bin/"cms").write <<~SH
      #!/bin/bash
      exec "#{libexec}/bin/code_my_spec_cli" "$@"
    SH
    chmod 0755, bin/"cms"
  end

  service do
    run [opt_bin/"cms", "start"]
    keep_alive true
    log_path var/"log/codemyspec.log"
    error_log_path var/"log/codemyspec.log"
  end

  test do
    assert_match version.to_s,
      shell_output("#{bin}/cms eval 'IO.puts Application.spec(:code_my_spec, :vsn)'")
  end
end
