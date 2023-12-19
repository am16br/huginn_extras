#https://github.com/aphilas/huginn_price_agent
module Pricey
  require 'nokogiri'
  require 'httparty'
  require 'cgi'

  class AmazonAgent
    def initialize(asin)
      @url = AmazonAgent.create_url asin
      @result
    end

    def parse_page
      Nokogiri::HTML(HTTParty.get(@url))
    end

    def get_product
      parsed_page = parse_page
      price = parsed_page.css('span.a-size-medium.a-color-price').children[0].text.strip[1..-1].to_i
      title = parsed_page.css('#productTitle').text

      puts parsed_page

      @result = {:title => title, :price => price, :link => @url, :retailer => "Amazon"}
    end

    def self.create_url(asin)
      "https://www.amazon.com/dp/#{asin}/"
    end
  end

  class EbayAgent
    attr_reader :url, :results

    def initialize(search_term)
      @url = EbayAgent.create_url search_term
      @results = []
    end

    def parse_page
      Nokogiri::HTML(HTTParty.get(@url))
    end

    def get_products
      parsed_page = parse_page
      titles = parsed_page.css('.s-item__title').map{|title| title.text.strip}
      prices = parsed_page.css('.s-item__price').map{|price| price.text.strip[1..-1].to_i}
      links = parsed_page.css('.s-item__link').map{|url| url['href']}

      @results.clear
      titles.zip(prices, links).each {|title, price, link|
        hash = {:title => title, :price => price, :link => link, :retailer => "Ebay"}
        @results << hash
      }
      @results
    end

    def self.create_url(search_term)
      "https://www.ebay.com/sch/i.html?_from=R40&_trksid=m570.l1313&_nkw=#{CGI.escape search_term}&_sacat=0"
    end
  end

  class FlipkartAgent
    attr_reader :url, :results

    def initialize(search_term)
      @url = FlipkartAgent.create_url search_term
      @results = []
    end

    def parse_page
      Nokogiri::HTML(HTTParty.get(@url))
    end

    def get_products
      parsed_page = parse_page
      # rows = parsed_page.css('div._3O0U0u')

      products = parsed_page.css('div._3liAhj._1R0K0g')

      @results.clear
      products.each do |product|
        title = product.at_css('a._2cLu-l')['title']
        link = 'https://www.flipkart.com' + product.at_css('a._2cLu-l')['href']
        price = (product.at_css('div._1vC4OE').text.strip[1..-1].tr(',', '').to_i * 0.014).round

        break if title.start_with?('<') || link.start_with?('<')
        @results.push({:title => title, :price => price, :link => link, :retailer => "Flipkart"})
        @results
      end
    end

    def self.create_url(search_term)
      "https://www.flipkart.com/search?q=#{CGI.escape search_term}&otracker=search&otracker1=search&marketplace=FLIPKART&as-show=on&as=off"
    end
  end

  class ScrapingAgent
    attr_reader :results, :keyword

    def initialize(keyword, search_amazon = nil, asin = nil)
      @results = []
      @keyword = keyword
      @search_amazon = search_amazon
      @asin = asin
    end

    def get_price
      fk = FlipkartAgent.new @keyword
      fk.get_products
      @results << fk.results

      ebay = EbayAgent.new @keyword
      @results << ebay.get_products

      if @search_amazon && @asin
        amazon = AmazonAgent.new @asin
        @results << amazon.get_product
      end

      @results = @results.flatten
      @results.min_by {|product| product[:price]}
    end
  end
end

module Agents
  class PriceAgent < Agent
    description <<-MD
      Search for a product across various websites to get the lowest price.
      Note: to search for a product in Amazon, you need the ASIN number.
    MD

    event_description <<-MD
      Events are a JSON object containing the lowest price of the product with the following format:
        {
          "title": "Artificial Intelligence: A Modern Approach",
          "price": 5,
          "link": "https://ebay.com/aima-agcy36gdi7q3",
          "retailer": "Ebay"
        }

      Price is in dollars.
    MD

    default_schedule "every_1d"

    def working?
      true
    end

    def default_options
      {
        'keyword' => 'Artificial Intelligence: A Modern Approach'
      }
    end

    def validate_options
      errors.add(:base, "keyword is required") unless options['keyword'].present?
    end

    def check
      create_event :payload => Pricey::ScrapingAgent.new(options['keyword']).get_price
    end
  end
end
