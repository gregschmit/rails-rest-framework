class ApplicationController < ActionController::Base
  def dev_test
    render(plain: params.inspect)
  end
end
