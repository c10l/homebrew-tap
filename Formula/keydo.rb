class Keydo < Formula
  desc "Keyboard remapping daemon with layers, overloads and chords"
  homepage "https://github.com/argenkiwi/keydo"
  url "https://github.com/argenkiwi/keydo/archive/refs/tags/v0.3.4.tar.gz"
  sha256 "7cc061cc1b84bf61ef9cd0072dc5f43a1ccd0e65f73c0408a903653e5083b0f9"
  license "MIT"
  head "https://github.com/argenkiwi/keydo.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  def caveats
    <<~EOS
      keydo captures and injects keyboard input at a low level, so it needs
      elevated privileges: root on Linux, or Accessibility permission on macOS.

      Register and start the daemon with:
        keydo install
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/keydo --version")

    (testpath/"test.conf").write <<~CONF
      [ids]
      *

      [main]
      capslock = overload(nav, esc)

      [nav]
      h = left
    CONF

    system bin/"keydo", "check", testpath/"test.conf"
  end
end
