class Rnitro < Formula
  desc "Real-time CPU monitor for macOS — usage, temperature, and per-core stats"
  homepage "https://getrnitro.netlify.app/"
  url "https://github.com/ilikemacos/rNitro/releases/download/v8.3.6-Final/rNitro-v8.3.6-Final-arm64.zip"
  version "8.3.6"
  sha256 "0cbda46b537adf349c38c6dc3f5d080d866d601eb2a75009b61346c67a03002a"
  license "MIT"

  depends_on macos: ">= :monterey"
  depends_on arch: :arm64

  def install
    app = "rNitro.app"
    odie "Expected #{app} in the download archive" unless (buildpath/app).directory?

    dest_root = if File.writable?("/Applications")
      Pathname("/Applications")
    else
      Pathname("#{ENV['HOME']}/Applications")
    end
    app_dest = dest_root/app
    rm_rf app_dest if app_dest.exist?
    cp_r buildpath/app, app_dest

    (bin/"rnitro").write <<~EOS
      #!/bin/bash
      set -euo pipefail
      exec /usr/bin/open -a "#{app_dest}" "$@"
    EOS
    (bin/"rnitro").chmod 0755
  end

  def post_install
    dest = File.writable?("/Applications") ? "/Applications/rNitro.app" : "#{ENV['HOME']}/Applications/rNitro.app"
    system "/usr/bin/xattr", "-dr", "com.apple.quarantine", dest
  end

  def uninstall
    rm_rf "/Applications/rNitro.app"
    rm_rf "#{Dir.home}/Applications/rNitro.app"
  end

  def caveats
    dest = File.writable?("/Applications") ? "/Applications/rNitro.app" : "#{ENV['HOME']}/Applications/rNitro.app"
    <<~EOS
      rNitro was installed to #{dest}
      Run `rnitro` from Terminal or open it from Applications.

      First launch: if macOS blocks the app, right-click rNitro.app → Open → Open.
      Release: https://github.com/ilikemacos/rNitro/releases/tag/v8.3.6-Final
    EOS
  end

  test do
    assert_predicate bin/"rnitro", :exist?
  end
end

