# The wkhtmltopdf-binary gem's `wkhtmltopdf` executable is a Ruby wrapper that
# picks — and on first run extracts — the precompiled binary for this platform,
# then execs it. wicked_pdf shells that wrapper out at request time, where the
# puma systemd environment has no `ruby` in PATH (rbenv), so it dies with
# "/usr/bin/env: 'ruby': No such file or directory". Resolve the native binary
# here at boot instead, where Ruby is running, and hand wicked_pdf that path.
WickedPdf.configure do |config|
  wrapper = Gem.bin_path("wkhtmltopdf-binary", "wkhtmltopdf")
  bin_dir = File.dirname(wrapper)
  find_native = -> { Dir[File.join(bin_dir, "wkhtmltopdf_*")].grep_v(/\.gz\z/).select { |f| File.file?(f) && File.executable?(f) } }

  native = find_native.call
  if native.empty?
    # First run on this machine: the wrapper extracts the platform binary
    # beside itself. Invoke it through the current Ruby explicitly.
    system(RbConfig.ruby, wrapper, "--version", out: File::NULL, err: File::NULL)
    native = find_native.call
  end

  if native.any?
    config.exe_path = native.max_by { |f| File.mtime(f) }
  else
    Rails.logger.warn "wicked_pdf: no native wkhtmltopdf binary found in #{bin_dir}; " \
                      "falling back to the gem wrapper, which needs `ruby` in PATH."
  end
end
