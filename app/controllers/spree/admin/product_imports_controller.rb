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
        Delayed::Job.enqueue ImportProducts::ImportJob.new(@product_import, spree_current_user)
        flash[:notice] = t('product_import_processing')
        redirect_to admin_product_imports_path
      end

      def destroy
        @product_import = Spree::ProductImport.find(params[:id])
        if @product_import.destroy
          flash[:notice] = t('delete_product_import_successful')
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
