module WaveImporter
  # Wave's exports have no file-type marker beyond their headers, and users
  # rename downloads freely — so the file is identified by which headers it
  # carries rather than by its name.
  #
  # Real-world exports arrive in shapes a naive `CSV.read` chokes on: saved by
  # Excel on Windows (Windows-1252 or UTF-16, not UTF-8), semicolon-delimited
  # in some locales, or with a BOM / stray whitespace on the header row. Any of
  # those made every header comparison miss and the file read as
  # "unrecognised". Everything here — detection and both parsers — goes through
  # `table`, so the whole importer sees one clean, UTF-8, comma-agnostic view.
  #
  # detect logs a single greppable "[WaveImporter]" line describing exactly how
  # the file was read (size, encoding, delimiter, columns), so a misread in
  # production is diagnosable from the logs alone.
  class FileDetector
    SIGNATURES = {
      "customers" => %w[customer_name customer_currency],
      "vendors" => %w[vendor_name vendor_currency],
      "bill_items" => %w[vendor bill_date],
      "accounting" => [ "Transaction ID", "Account Name" ]
    }.freeze

    # Kept for backwards reference; reading now goes through read_utf8.
    ENCODING = "bom|utf-8".freeze

    DELIMITERS = [ ",", ";", "\t", "|" ].freeze
    DELIMITER_NAMES = { "," => "comma", ";" => "semicolon", "\t" => "tab", "|" => "pipe" }.freeze

    # Strips a stray BOM and surrounding whitespace so " customer_name " and
    # "﻿customer_name" both match "customer_name".
    HEADER_CLEANER = ->(header) { header.to_s.sub(/\A﻿/, "").strip }

    class << self
      def detect(path)
        raw = File.binread(path)
        text = decode(raw)
        delimiter = guess_delimiter(text)
        headers = parse_table(text, delimiter).headers.map { |h| HEADER_CLEANER.call(h) }.reject(&:blank?)
        kind = SIGNATURES.find { |_, required| required.all? { |h| headers.include?(h) } }&.first

        log_detection(path:, raw:, text:, delimiter:, headers:, kind:)
        { kind: kind, headers: headers }
      rescue CSV::MalformedCSVError, ArgumentError => e
        logger.warn("[WaveImporter] detect FAILED path=#{path} bytes=#{safe_bytesize(path)} #{e.class}: #{e.message}")
        { kind: nil, headers: [], error: e.message }
      end

      # A CSV::Table with cleaned string headers, whatever the file's encoding
      # or delimiter. Used by the parsers too, so detection and parsing never
      # disagree about how the file reads.
      def table(path)
        text = read_utf8(path)
        parse_table(text, guess_delimiter(text))
      end

      def read_utf8(path)
        decode(File.binread(path))
      end

      private

      def parse_table(text, delimiter)
        CSV.parse(text, headers: true, col_sep: delimiter, header_converters: [ HEADER_CLEANER ])
      end

      # Returns the file as a valid UTF-8 string regardless of how it was saved.
      def decode(raw)
        # UTF-16 (Excel "Unicode Text") announces itself with a byte-order mark.
        return transcode(raw.byteslice(2..).to_s, "UTF-16LE") if raw.start_with?("\xFF\xFE".b)
        return transcode(raw.byteslice(2..).to_s, "UTF-16BE") if raw.start_with?("\xFE\xFF".b)

        raw = raw.byteslice(3..).to_s if raw.start_with?("\xEF\xBB\xBF".b) # UTF-8 BOM

        utf8 = raw.dup.force_encoding("UTF-8")
        # Excel-on-Windows saves as Windows-1252; those bytes are invalid UTF-8.
        utf8 = transcode(raw, "Windows-1252") unless utf8.valid_encoding?
        utf8
      end

      # dup first: force_encoding mutates the receiver's encoding tag in place,
      # and the same raw byte string is reused for logging afterwards.
      def transcode(bytes, from)
        bytes.dup.force_encoding(from).encode("UTF-8", invalid: :replace, undef: :replace)
      end

      # Picks the delimiter that appears most on the header line (default comma),
      # so semicolon- or tab-separated exports parse into real columns instead
      # of one giant header.
      def guess_delimiter(text)
        header_line = text.each_line.find { |line| line.strip.present? }.to_s
        best = DELIMITERS.max_by { |delimiter| header_line.count(delimiter) }
        header_line.count(best).positive? ? best : ","
      end

      # A label for the byte-level shape of the file, so the log says *why* a
      # given encoding path was taken.
      def encoding_label(raw)
        return "utf-16le (BOM)" if raw.start_with?("\xFF\xFE".b)
        return "utf-16be (BOM)" if raw.start_with?("\xFE\xFF".b)
        return "utf-8 (BOM)" if raw.start_with?("\xEF\xBB\xBF".b)
        raw.dup.force_encoding("UTF-8").valid_encoding? ? "utf-8" : "windows-1252 (fallback)"
      end

      def log_detection(path:, raw:, text:, delimiter:, headers:, kind:)
        first_line = text.each_line.find { |l| l.strip.present? }.to_s.chomp
        logger.info(
          "[WaveImporter] detect path=#{File.basename(path)} " \
          "bytes=#{raw.bytesize} " \
          "encoding=#{encoding_label(raw)} " \
          "head_hex=#{raw.byteslice(0, 8).unpack1('H*')} " \
          "delimiter=#{DELIMITER_NAMES[delimiter] || delimiter.inspect} " \
          "columns=#{headers.size} " \
          "kind=#{kind.inspect}#{' NO-SIGNATURE-MATCH' if kind.nil?} " \
          "headers=#{headers.first(15).inspect} " \
          "raw_header=#{first_line[0, 300].inspect}"
        )
      end

      def safe_bytesize(path)
        File.size(path)
      rescue StandardError
        "?"
      end

      def logger
        Rails.logger
      end
    end
  end
end
