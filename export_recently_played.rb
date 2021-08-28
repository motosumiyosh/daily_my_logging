require "csv"
require "net/http"
require "json"
require "time"

def execute
  before = ""
  items = []
  is_items_present = true

  while is_items_present do
    params = {
      "market": "JP"
    }
    params.store("before", before) if !before.empty?

    res = send_request(params)

    is_items_present = !JSON.parse(res.body)["items"].empty?
    next unless is_items_present

    JSON.parse(res.body)["items"].each {|item| items << item }
    before = JSON.parse(res.body)["cursors"]["before"]
  end

  export_csv(items)
end

def send_request(params)
  uri = URI.parse(api_uri + recently_played_endpoint)
  uri.query = URI.encode_www_form(params)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  req = Net::HTTP::Get.new uri.request_uri
  req["Authorization"] = "Bearer #{access_token}"
  req["Accept-Language"] = "ja;q=1"

  http.request(req)
end

def api_uri
  "https://api.spotify.com/"
end

def recently_played_endpoint
  "v1/me/player/recently-played"
end

def export_csv(items)
  CSV.open("sample.csv", "wb") do |csv|
    csv << csv_headers
    items.each { |item| csv << csv_values(item) }
  end
end

def access_token
  params = {
    refresh_token: refresh_token,
    grant_type: "refresh_token",
    client_id: ENV["SPOTIFY_API_CLIENT_ID"],
    client_secret: ENV["SPOTIFY_API_CLIENT_SECRET"],
  }
  uri = URI.parse("https://accounts.spotify.com/api/token")
  response = Net::HTTP.post_form(uri, params)
  JSON.parse(response.body)["access_token"]
end

def refresh_token
  ENV["SPOTIFY_API_REFRESH_TOKEN"]
end

def csv_values(item)
  [
    item["track"]["name"],
    item["track"]["id"],
    item["track"]["popularity"],
    item["track"]["album"]["name"],
    item["track"]["album"]["id"], 
    item["track"]["album"]["artists"].map { |a| a["name"] }.join(", "),
    item["track"]["album"]["artists"].map { |a| a["id"] }.join(", "),
    item["track"]["album"]["release_date"],
    item["track"]["artists"].map { |a| a["name"] }.join(", "),
    item["track"]["artists"].map { |a| a["id"] }.join(", "),
    item["track"]["album"]["artists"].count > 1,
    item["track"]["artists"].count > 1,
    Time.parse(item["played_at"]).localtime.strftime("%Y-%m-%d %H:%M:%S"),
  ]
end

def csv_headers
  [
    "track_name",
    "track_id",
    "track_popularity",
    "album_name",
    "album_id",
    "album_artists_name",
    "album_artists_ids",
    "album_release_date",
    "track_artists_name",
    "track_artists_ids",
    "is_track_artists_multiple",
    "is_album_artists_multiple",
    "played_at",
  ]
end

execute