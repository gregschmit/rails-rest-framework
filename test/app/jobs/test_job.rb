class TestJob < ApplicationJob
  def perform(*args)
    Rails.logger.info("🔥🔥🔥 Test job was called: #{args.inspect} 🔥🔥🔥")
  end
end
