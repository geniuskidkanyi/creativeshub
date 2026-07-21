class ProcessWaveImportJob < ApplicationJob
  queue_as :default

  # mode is :preview (dry run, writes nothing) or :commit.
  def perform(wave_import, mode:)
    wave_import.update!(status: mode == :preview ? :previewing : :importing, error_message: nil)

    wave_import.with_downloaded_file do |path|
      mode == :preview ? run_preview(wave_import, path) : run_commit(wave_import, path)
    end
  rescue StandardError => e
    Rails.logger.error "Wave import #{wave_import.id} failed: #{e.class}: #{e.message}"
    wave_import.update!(status: :failed, error_message: "#{e.class}: #{e.message}")
  end

  private

  def run_preview(wave_import, path)
    detection = WaveImporter::FileDetector.detect(path)
    kind = detection[:kind]

    preview = WaveImporter::Previewer.new(wave_import.account, kind: kind, path: path).call
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
