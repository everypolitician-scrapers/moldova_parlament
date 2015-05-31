#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'
require 'date'
require 'csv'

require 'execjs'
require 'colorize'
require 'pry'
require 'csv'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

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
  data = { 
    id: url[%r{Id/(\d+)/}, 1],
    name: noko.css('#dnn_ctr476_ViewDeputat_lblName').text.strip,
    position: noko.css('#dnn_ctr476_ViewDeputat_lblPosition').text.strip,
    party: noko.css('#dnn_ctr476_ViewDeputat_hlFraction').text.strip,
    term: 2014,
    source: url.to_s,
  }
  data[:position] = '' if data[:position] == 'Depute'

  jsemail = noko.css('#dnn_ctr476_ViewDeputat_fsContactData').xpath('.//a[contains(text(),"E-mail")]/@href').text
  unless jsemail.to_s.empty?
    data[:email] = ExecJS.eval(jsemail.split('+')[1])
  end

  ScraperWiki.save_sqlite([:id, :term], data)
end

term = {
  id: 2014,
  name: '2014–2018',
  start_date: '2014',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

scrape_list('http://www.parlament.md/StructuraParlamentului/Deputies/tabid/87/language/en-US/Default.aspx')

