require "./app"

# map "/assets" do
#   run SeabassTasks::App.settings.sprockets
# end

map "/" do
  run SeabassTasks::App
end