require 'json'
require 'net/http'
require 'nokogiri'
require 'open-uri'
require 'xmlsimple'

if ARGV[0] == nil
  
  puts "enter a medium username"
end

user_name = ARGV[0].downcase
if user_name[0] == "@"
  
  user_name = user_name[1..-1]
end

puts "medium user:#{user_name}"




user_page = Nokogiri::HTML(open("https://medium.com/@#{ARGV[0]}"))
user_id = user_page.css('h1.hero-title/a').attr('data-user-id')

puts "medium user id:#{user_id}"


 
json_url = "https://medium.com/_/api/users/#{user_id}/profile/stream?limit=999&source=latest"


uri = URI(json_url)
response = Net::HTTP.get(uri)
feed = JSON.parse(response[16..-1])
posts = feed["payload"]["references"]["Post"].keys

posts.map! do |post|
  post_info = feed["payload"]["references"]["Post"][post]
  
  url = "https://medium.com/_/#{post}"
  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  url = response['location']
  publish_date = Time.at(post_info["firstPublishedAt"].to_s[0..-4].to_i).to_s
  title = post_info["title"]

  page = Nokogiri::HTML(open(url))
  puts url
  ['h1','h4','p','h3','a','figure','img'].each do |style|
    ['name','class','id','data-href','data-image-id','data-action-value','data-action','data-width','data-height'].each do |attr|
      page.css(style).remove_attr(attr)
    end
  end
  page.css('div.aspectRatioPlaceholder-fill').remove
  page.css('div.aspectRatioPlaceholder').remove_attr('class')
  post_html = page.css('div.section-inner').inner_html
  
  {"title" => [title], "publish_date" => [publish_date], "original_url" => [url], "post_content" => [post_html]}

end

File.open("#{user_name}.xml", 'w') { |file| file.write(XmlSimple.xml_out(posts, {"RootName" => "posts", "AnonymousTag" => "post"})) }
