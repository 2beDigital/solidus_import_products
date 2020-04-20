# frozen_string_literal: true

# This model is the master routine for uploading products
# Requires Paperclip and CSV to upload the CSV file and read it nicely.

# Original Author:: Josh McArthur
# License:: MIT
module Spree
  class ProductImport < ApplicationRecord
    ENCODINGS = %w[iso-8859-1 UTF-8].freeze

    has_attached_file :data_file,
      path: ':rails_root/tmp/product_data/data-files/:basename_:timestamp.:extension',
      url: ':rails_root/tmp/product_data/data-files/:basename_:timestamp.:extension',
      storage: 'filesystem'

    has_attached_file :compress_image_file,
      path: ':rails_root/tmp/product_data/data-files/:basename_:timestamp.:extension',
      url: ':rails_root/tmp/product_data/data-files/:basename_:timestamp.:extension',
      storage: 'filesystem'

    belongs_to :user, class_name: 'Spree::User', foreign_key: 'created_by', inverse_of: :product_imports

    validates_attachment_presence :data_file
    # Content type of csv vary in different browsers.
    validates_attachment :data_file, presence: true, content_type: { content_type: ['text/csv', 'text/plain', 'text/comma-separated-values', 'application/octet-stream', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'] }

    validates_attachment_presence :compress_image_file
    # Content type of zip vary in different browsers.
    validates_attachment :compress_image_file, presence: true, content_type: { content_type: ['application/zip', 'application/octet-stream'] }

    validates_attachment_file_name :compress_image_file, matches: [/zip\Z/]

    after_destroy :destroy_products

    serialize :product_ids, Array
    cattr_accessor :settings

    state_machine initial: :created do
      event :start do
        transition to: :started, from: :created
      end
      event :complete do
        transition to: :completed, from: :started
      end
      event :failure do
        transition to: :failed, from: %i[created started]
      end

      before_transition to: [:failed] do |import|
        import.product_ids = []
        import.failed_at = Time.current
        import.completed_at = nil
      end

      before_transition to: [:completed] do |import|
        import.failed_at = nil
        import.completed_at = Time.current
      end
    end

    def parse
      options = { encoding_csv: encoding_csv, separator_char: separatorChar }
      @parse ||= SolidusImportProducts::Parser.parse(:csv,
        data_file.url(:default, timestamp: false), options)
    end

    def unzip
      dir = compress_image_path
      file_path = compress_image_file.url(:default, timestamp: false)
      if File.exist?(file_path)
        Zip::File.open(file_path) do |zip_file|
          zip_file.each do |f|
            fpath = File.join(dir, f.name)
            zip_file.extract(f, fpath) unless File.exist?(fpath)
          end
        end
      end
      dir
    end

    def products
      Product.where(id: product_ids)
    end

    def add_product(product)
      product_ids << product.id unless product?(product)
    end

    def product?(product)
      product.id && product_ids.include?(product.id)
    end

    def products_count
      parse.product_count
    end

    def destroy_products
      destroy_data_uploaded
      products.destroy_all
    end

    def destroy_data_uploaded
      FileUtils.rm_rf(compress_image_path) unless compress_image_path.nil?
      data_file.destroy
      compress_image_file.destroy
    end

    def compress_image_path
      file_path = compress_image_file.url(:default, timestamp: false)
      File.join(File.dirname(file_path), File.basename(file_path, '.zip')) if File.exist?(file_path)
    end

    def state_datetime
      if failed?
        failed_at
      elsif completed?
        completed_at
      else
        updated_at
      end
    end
  end
end
