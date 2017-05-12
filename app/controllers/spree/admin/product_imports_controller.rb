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
        @product_import = Spree::ProductImport.create(product_import_params)
				@product_import.created_by=spree_current_user.id
				@product_import.save
        begin
          numProds=@product_import.productsCount
          if numProds > Spree::ProductImport.settings[:num_prods_for_delayed]
						ImportProductsJob.perform_later(@product_import.id)
					  flash[:notice] = t('product_import_processing')
          else
            @product_import.import_data!(Spree::ProductImport.settings[:transaction])
					  flash[:success] = t('product_import_imported')
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
        redirect_to admin_product_imports_path
      end

      def destroy
        @product_import = Spree::ProductImport.find(params[:id])
        if @product_import.destroy
          flash[:success] = t('delete_product_import_successful')
        end
        redirect_to admin_product_imports_path
      end

      private
        def product_import_params
          params.require(:product_import).permit!
        end
    end
  end
end
