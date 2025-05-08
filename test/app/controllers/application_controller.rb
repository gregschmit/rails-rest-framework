class ApplicationController < ActionController::Base
  include ActiveStorage::SetCurrent

  protect_from_forgery
end
