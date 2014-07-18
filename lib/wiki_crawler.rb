require 'rcrawl'

crawl = Rcrawl::Crawler.new('http://ecl.info.kindai.ac.jp/~earth-moon/test/')
crawl.crawl

p crawl

