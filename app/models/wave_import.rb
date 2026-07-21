class WaveImport < ApplicationRecord
  belongs_to :account
  belongs_to :user, optional: true

  has_one_attached :file

  enum :status, {
    pending: "pending",
    previewing: "previewing",
    previewed: "previewed",
    importing: "importing",
    completed: "completed",
    failed: "failed"
  }

  SUPPORTED_KINDS = %w[customers accounting].freeze

  validates :file, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  def supported?
    SUPPORTED_KINDS.include?(kind)
  end

  def label
    case kind
    when "customers" then "Customers"
    when "accounting" then "Invoices & products"
    when "vendors" then "Vendors"
    when "bill_items" then "Bills"
    else "Unrecognised file"
    end
  end

  # Preview and commit both need the upload as a real file on disk, since the
  # parsers stream it with CSV.foreach rather than loading it into memory.
  def with_downloaded_file
    file.open(tmpdir: Dir.tmpdir) { |tempfile| yield tempfile.path }
  end

  def preview_rows = preview["rows"] || []
  def preview_summary = preview["summary"] || {}
  def preview_warnings = preview["warnings"] || []
end
