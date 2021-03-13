# frozen_string_literal: true

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
        @product_imports = spree_current_user.product_imports.create(product_import_params)
        if !@product_imports.id.nil?
          ImportProductsJob.perform_later(@product_imports)
          flash[:notice] = t('product_import_processing')
        else
          flash[:error] = t('product_import_error')
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
