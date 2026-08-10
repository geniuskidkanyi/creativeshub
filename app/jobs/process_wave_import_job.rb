class ProcessWaveImportJob < ApplicationJob
  queue_as :default

  # mode is :preview (dry run, writes nothing) or :commit.
  def perform(wave_import, mode:)
    log_source(wave_import, mode)
    wave_import.update!(status: mode == :preview ? :previewing : :importing, error_message: nil)

    wave_import.with_downloaded_file do |path|
      Rails.logger.info "[WaveImporter] import=#{wave_import.id} downloaded to=#{path} size_on_disk=#{File.size(path)}"
      mode == :preview ? run_preview(wave_import, path) : run_commit(wave_import, path)
    end
    notify_import_finished(wave_import) if mode == :commit
  rescue StandardError => e
    Rails.logger.error "[WaveImporter] import=#{wave_import.id} FAILED #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    wave_import.update!(status: :failed, error_message: "#{e.class}: #{e.message}")
    notify_import_finished(wave_import) if mode == :commit
  end

  private

  # Tell the account the import finished (or failed) — they may have navigated
  # away from the auto-refreshing page.
  def notify_import_finished(wave_import)
    recipients = wave_import.account.notification_recipients
    return if recipients.blank?

    ImportCompletedNotifier.with(wave_import: wave_import).deliver(recipients)
  rescue StandardError => e
    Rails.logger.warn "[WaveImporter] import=#{wave_import.id} notify failed: #{e.class}: #{e.message}"
  end

  # One line describing the blob that was actually uploaded — filename,
  # declared content type, stored byte size, checksum and which storage
  # service it came from. Confirms the file reached the worker intact.
  def log_source(wave_import, mode)
    blob = wave_import.file.blob
    Rails.logger.info(
      "[WaveImporter] import=#{wave_import.id} mode=#{mode} account=#{wave_import.account_id} " \
      "filename=#{blob&.filename.to_s.inspect} content_type=#{blob&.content_type.inspect} " \
      "byte_size=#{blob&.byte_size} checksum=#{blob&.checksum.inspect} service=#{blob&.service_name}"
    )
  rescue StandardError => e
    Rails.logger.warn "[WaveImporter] import=#{wave_import.id} could not read blob metadata: #{e.class}: #{e.message}"
  end

  def run_preview(wave_import, path)
    detection = WaveImporter::FileDetector.detect(path)
    kind = detection[:kind]

    preview = WaveImporter::Previewer.new(wave_import.account, kind: kind, path: path).call
    # Record the columns we actually read so an unrecognised file can be
    # diagnosed (wrong delimiter, wrong export, garbled encoding) instead of
    # being a dead end.
    preview = preview.merge("detected_headers" => detection[:headers], "detect_error" => detection[:error])
    wave_import.update!(kind: kind, preview: preview, status: :previewed, previewed_at: Time.current)
  end

  def run_commit(wave_import, path)
    result = WaveImporter::Committer.new(wave_import.account, kind: wave_import.kind, path: path).call

    wave_import.update!(
      status: :completed,
      committed_at: Time.current,
      result: {
        "clients_created" => result.clients_created,
        "clients_updated" => result.clients_updated,
        "invoices_created" => result.invoices_created,
        "invoices_skipped" => result.invoices_skipped,
        "products_created" => result.products_created,
        "items_created" => result.items_created,
        "errors" => result.errors.first(50)
      }
    )
  end
end
