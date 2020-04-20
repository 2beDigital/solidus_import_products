# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::User, type: :model do
  let(:admin_user) { create(:admin_user) }

  it { expect(admin_user).to respond_to(:product_imports) }
  it { is_expected.to have_many(:product_imports) }
end
