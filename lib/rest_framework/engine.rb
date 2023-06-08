class RESTFramework::Engine < Rails::Engine
  initializer "rest_framework.assets" do
    config.after_initialize do |app|
      if RESTFramework.config.use_vendored_assets
        app.config.assets.precompile += RESTFramework::EXTERNAL_ASSETS.keys.map do |name|
          "rest_framework/#{name}"
        end
      end
    end
  end
end
