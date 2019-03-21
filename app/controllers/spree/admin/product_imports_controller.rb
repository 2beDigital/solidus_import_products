module Spree
  module Admin
    class ProductImportsController < BaseController

      def index
        @product_import = Spree::ProductImport.new
      end

      def show
        @product_import = Spree::ProductImport.find(params[:id])
        @products = @product_import.products
      end

      def create
        import = product_import_params.to_h
        import.merge(created_by: spree_current_user.id)
        data_files = import.delete("data_file")
        delayed_imports = false
        if data_files.size > 1
          data_files.each do |data_file|
            import["data_file"] = data_file
            delayed_imports = import_data(import)
          end         
        else
          import["data_file"] = data_files[0]
          delayed_imports = import_data(import)
        end
        if delayed_imports
          flash[:notice] = t(:product_import_processing)
        else
          flash[:success] = t(:product_import_imported)
        end
        redirect_to admin_product_imports_path
      end

      def destroy
        @product_import = Spree::ProductImport.find(params[:id])
        if @product_import.destroy
          flash[:success] = t(:delete_product_import_successful)
        end
        redirect_to admin_product_imports_path
      end

      private

      def product_import_params
        params.require(:product_import).permit!
      end

      def import_data(import)
        begin
          @product_import = Spree::ProductImport.create(import)
          if @product_import.productsCount > Spree::ProductImport.settings[:num_prods_for_delayed]
            ImportProductsJob.perform_later(@product_import.id)
            delayed = true
          else
            @product_import.import_data!(Spree::ProductImport.settings[:transaction])
            delayed = false
          end
        rescue StandardError => e
          @product_import.error_message=e.message
          @product_import.failure
          if (e.is_a?(OpenURI::HTTPError))
            flash[:error] = t('product_import_http_error')
          else
            flash[:error] = e.message
          end
        end
        return delayed
      end
    end
  end
end
