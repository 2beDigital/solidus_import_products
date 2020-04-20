# frozen_string_literal: true

ActiveJob::Base.queue_adapter = :test

RSpec.configure do |config|
  # clean out the queue after each spec
  config.after do
    ActiveJob::Base.queue_adapter.enqueued_jobs = []
    ActiveJob::Base.queue_adapter.performed_jobs = []
  end
end
