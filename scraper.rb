#!/bin/env ruby
# encoding: utf-8

require 'execjs'
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def unbracket(str)
  return ['Independent', 'Independent'] if str.empty?
  cap = str.match(/^(.*?)\s*\((.*?)\)\s*$/) or return [str, str]
  return cap.captures 
end

def scrape_list(url)
  noko = noko_for(url)
  count = 0
  noko.css('div.allTitle a.MemberLink/@href').map(&:text).uniq.each do |link|
    scrape_mp(link)
    count += 1
  end
  puts "Added #{count}"
end

def scrape_mp(url)
  # warn "Getting #{url}"
  noko = noko_for(url)
  sort_name = noko.css('#dnn_ctr476_ViewDeputat_lblName').text.tidy
  data = { 
    id: url[%r{Id/(\d+)/}, 1],
    name: sort_name.split(' ', 2).reverse.join(' '),
    sort_name: sort_name,
    position: noko.css('#dnn_ctr476_ViewDeputat_lblPosition').text.tidy,
    party: noko.css('#dnn_ctr476_ViewDeputat_hlFraction').text.tidy,
    party_id: noko.css('a#dnn_ctr476_ViewDeputat_hlFraction/@href').text[/Id\/(.*?)\//, 1],
    image: noko.css('.allTitle img/@src').first.text,
    term: 2014,
    source: url.to_s,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  data[:position] = '' if data[:position] == 'Depute'

  jsemail = noko.css('#dnn_ctr476_ViewDeputat_fsContactData').xpath('.//a[contains(text(),"E-mail")]/@href').text
  unless jsemail.to_s.empty?
    data[:email] = ExecJS.eval(jsemail.split('+')[1])
  end

  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://www.parlament.md/StructuraParlamentului/Deputies/tabid/87/language/en-US/Default.aspx')

