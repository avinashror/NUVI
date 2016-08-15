#http://feed.omgili.com/5Rh5AMTrc4Pv/mainstream/posts/1470877192283.zip
#require 'open-uri'
#download = open('http://feed.omgili.com/5Rh5AMTrc4Pv/mainstream/posts/1470877192283.zip')
#IO.copy_stream(download, '~/1470877192283.zip')

#http://feed.omgili.com/5Rh5AMTrc4Pv/mainstream/posts/
#http://feed.omgili.com/5Rh5AMTrc4Pv/mainstream/posts/1470884361526.zip

require 'net/http'
require 'zipruby'
require 'nokogiri'
require 'open-uri'
require 'redis'





class NewsFeedUploader

def initialize feed_url
        @feed_url = feed_url
	nk_obj = Nokogiri::HTML(open(@feed_url))
	@links_array = nk_obj.css("a").map{|link| link["href"] if link["href"].include?(".zip")}.compact
	
end

def self.! url
	instance = new url
        instance.download_files_from_url

end


def download_files_from_url
	redis = Redis.new
	@links_array.each do |link|
		url = "#{@feed_url}/#{link}"
		folder_name = "files/#{link.gsub(".zip",'')}"
		Dir.mkdir(folder_name) unless Dir.exist?(folder_name)
		zip_data = Net::HTTP.get(URI.parse(url))
		Zip::Archive.open_buffer(zip_data) do |f|
		   n = f.num_files
		   n.times do |i|
		       name = f.get_name(i)
			
			f.fopen(name) do |file|
			   of = File.open("#{folder_name}/#{name}", 'w')
			   content = file.read
			   of.puts(content)
			   redis.lrem("NEWS_XML",0,content)
			   redis.rpush("NEWS_XML",content)
			   of.close
			end
		   end
		end
	end
end

end

NewsFeedUploader.! "http://feed.omgili.com/5Rh5AMTrc4Pv/mainstream/posts/"


download_files_from_url(links_array)

