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

  service do
    if OS.linux?
      # keydo refuses to start unless /run/keydo exists, and upstream's own
      # systemd unit provides it via `RuntimeDirectory=keydo` and `Group=keydo`.
      # Homebrew's service DSL can express neither, so create the directory
      # ourselves (setgid, so the socket inside inherits the keydo group) before
      # exec'ing the daemon.
      setup = [
        "groupadd -f keydo",
        "mkdir -p /run/keydo",
        "chown root:keydo /run/keydo",
        "chmod 2750 /run/keydo",
        "exec #{opt_bin}/keydo daemon",
      ].join(" && ")
      run ["/bin/sh", "-c", setup]
      require_root true
    else
      run [opt_bin/"keydo", "daemon"]
    end

    keep_alive true
    restart_delay 5
  end

  def caveats
    if OS.mac?
      <<~EOS
        keydo needs Accessibility permission to capture and inject key events.
        Grant it under System Settings -> Privacy & Security -> Accessibility.

        Start the daemon with:
          brew services start keydo
      EOS
    else
      <<~EOS
        keydo needs root to read input devices and inject events, so start it with:
          sudo brew services start keydo

        To use the CLI without root, add yourself to the keydo group and log back
        in for it to take effect:
          sudo usermod -aG keydo $USER

        If you previously ran `sudo keydo install`, remove that service first with
        `sudo keydo uninstall` so two daemons do not fight over the keyboard.
      EOS
    end
  end

  test do
    assert_match "Usage: keydo", shell_output("#{bin}/keydo --help")

    (testpath/"default.conf").write <<~CONF
      [ids]
      *

      [main]
      capslock = overload(nav, esc)

      [nav]
      h = left
    CONF
    system bin/"keydo", "check", testpath/"default.conf"

    (testpath/"invalid.conf").write "this is not a valid config\n"
    shell_output("#{bin}/keydo check #{testpath}/invalid.conf", 1)
  end
end
