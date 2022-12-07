module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :random_token

    def connect
      self.random_token = SecureRandom.hex(4)
    end
  end
end
