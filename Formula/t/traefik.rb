class Traefik < Formula
  desc "Modern reverse proxy"
  homepage "https://traefik.io/"
  url "https://github.com/traefik/traefik/releases/download/v3.1.1/traefik-v3.1.1.src.tar.gz"
  sha256 "247a209d2090b4f5e6d1524f1ba1c9b0be1eb8e35f7f9f9a50f439e624059d52"
  license "MIT"
  head "https://github.com/traefik/traefik.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "23f5da1c974248e24ddfdaed06ca27f2de5ca01dce4b9d1a40b5542071af3c51"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "45708903d0cd24d9c1239804add654f9039e194af880d96882bab1c0d033902a"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "16f0796df1028078a78f1c3e7bf474b26a06af7cc8cfcab93b3c1ec634bf4465"
    sha256 cellar: :any_skip_relocation, sonoma:         "74f9f50ff2d449c4659feccc4923e31070ac0290abfb8e7579852c7acf5ec678"
    sha256 cellar: :any_skip_relocation, ventura:        "fc47c23cffb8da6feb0332bc032561e7868faf9a1637589262cc853ced02e116"
    sha256 cellar: :any_skip_relocation, monterey:       "7c8f0126e43c22c631c577b2634ed65c05680e5114baf587fbe42599d4605e4d"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "7c9fee7943d24fbe24c507ba36fc0b8e303d8a95f44f5e0b2a4cc9199a0efb43"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/traefik/traefik/v#{version.major}/pkg/version.Version=#{version}
    ]
    system "go", "generate"
    system "go", "build", *std_go_args(ldflags:), "./cmd/traefik"
  end

  service do
    run [opt_bin/"traefik", "--configfile=#{etc}/traefik/traefik.toml"]
    keep_alive false
    working_dir var
    log_path var/"log/traefik.log"
    error_log_path var/"log/traefik.log"
  end

  test do
    ui_port = free_port
    http_port = free_port

    (testpath/"traefik.toml").write <<~EOS
      [entryPoints]
        [entryPoints.http]
          address = ":#{http_port}"
        [entryPoints.traefik]
          address = ":#{ui_port}"
      [api]
        insecure = true
        dashboard = true
    EOS

    begin
      pid = fork do
        exec bin/"traefik", "--configfile=#{testpath}/traefik.toml"
      end
      sleep 8
      cmd_ui = "curl -sIm3 -XGET http://127.0.0.1:#{http_port}/"
      assert_match "404 Not Found", shell_output(cmd_ui)
      sleep 1
      cmd_ui = "curl -sIm3 -XGET http://127.0.0.1:#{ui_port}/dashboard/"
      assert_match "200 OK", shell_output(cmd_ui)
    ensure
      Process.kill(9, pid)
      Process.wait(pid)
    end

    assert_match version.to_s, shell_output("#{bin}/traefik version 2>&1")
  end
end
