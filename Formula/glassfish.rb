class Glassfish < Formula
  desc "Java EE application server"
  homepage "https://glassfish.org/"
  url "https://download.eclipse.org/ee4j/glassfish/glassfish-7.0.7.zip"
  mirror "https://github.com/eclipse-ee4j/glassfish/releases/download/7.0.7/glassfish-7.0.7.zip"
  sha256 "d6465b3e85eb9717e5934332a47648d9928f87063cdd37873c94dd1d234efad9"
  license "EPL-2.0"

  livecheck do
    url "https://projects.eclipse.org/projects/ee4j.glassfish/downloads"
    regex(/href=.*?glassfish[._-]v?(\d+(?:\.\d+)+)\.zip/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "41b0df03f99eb41938ec3ab11c644e68a6233c5d93ac687b823468a1635bce7e"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "41b0df03f99eb41938ec3ab11c644e68a6233c5d93ac687b823468a1635bce7e"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "41b0df03f99eb41938ec3ab11c644e68a6233c5d93ac687b823468a1635bce7e"
    sha256 cellar: :any_skip_relocation, ventura:        "41b0df03f99eb41938ec3ab11c644e68a6233c5d93ac687b823468a1635bce7e"
    sha256 cellar: :any_skip_relocation, monterey:       "41b0df03f99eb41938ec3ab11c644e68a6233c5d93ac687b823468a1635bce7e"
    sha256 cellar: :any_skip_relocation, big_sur:        "41b0df03f99eb41938ec3ab11c644e68a6233c5d93ac687b823468a1635bce7e"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "b24f7470842debfe625465cc06ecc808abdf720a4240b1ef5804a4a7300e750f"
  end

  depends_on "openjdk@17"

  conflicts_with "payara", because: "both install the same scripts"

  def install
    # Remove all windows files
    rm_rf Dir["bin/*.bat", "glassfish/bin/*.bat"]

    libexec.install Dir["*"]
    bin.install Dir["#{libexec}/bin/*"]

    env = Language::Java.overridable_java_home_env("17")
    env["GLASSFISH_HOME"] = libexec
    bin.env_script_all_files libexec/"bin", env

    File.open(libexec/"glassfish/config/asenv.conf", "a") do |file|
      file.puts "AS_JAVA=\"#{env[:JAVA_HOME]}\""
    end
  end

  def caveats
    <<~EOS
      You may want to add the following to your .bash_profile:
        export GLASSFISH_HOME=#{opt_libexec}
    EOS
  end

  test do
    port = free_port
    # `asadmin` needs this to talk to a custom port when running `asadmin version`
    ENV["AS_ADMIN_PORT"] = port.to_s

    cp_r libexec/"glassfish/domains", testpath
    inreplace testpath/"domains/domain1/config/domain.xml", "port=\"4848\"", "port=\"#{port}\""

    fork do
      exec bin/"asadmin", "start-domain", "--domaindir=#{testpath}/domains", "domain1"
    end
    sleep 60

    output = shell_output("curl -s -X GET localhost:#{port}")
    assert_match "GlassFish Server", output

    assert_match version.to_s, shell_output("#{bin}/asadmin version")
  end
end
