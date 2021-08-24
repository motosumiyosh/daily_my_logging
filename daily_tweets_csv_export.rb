require 'csv'

def execute
  csv_upload(generate_csv)
end

def tweets
  get_range_day.beginning_of_day..get_range_day.end_of_day
  [
    "334",
    "絶起",
    "死の朝",
    "退勤王（読み：タイキング）",
  ]
end

def csv_upload(csv, path = daily_file_path)
  s3_client.put_object(
    bucket: ENV["BUCKET_NAME"],
    key: path,
    body: csv,
  )  
end

def daily_file_path
  get_range_day.strftime("%Y-%m-%d")
end

def s3_client
  Aws::S3::Client.new(
    credentials: aws_credential,
    region: ENV["AWS_REGION"]
  )
end

def aws_credential
  Aws::Credentials.new(
    ENV["ACCESS_KEY_ID"],
    ENV["SECRET_ACCESS_KEY"]
  )
end

def get_range_day
  Time.zone.yesterday
end

def generate_csv
  csv = ''
  csv += CSV.generate_line(headers)
  tweets.each do |t|
    items = tweet_export_items(t)
    csv += CSV.generate_line(item)
  end
  csv
end

def headers
  [
    "送信日時",
    "ツイート",
    "いいね",
    "リプライ",
  ]
end

def tweet_export_items(tweet)
  [
    tweet,
    tweet,
  ]
end

execute