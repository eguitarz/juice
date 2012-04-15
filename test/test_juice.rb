require 'test/unit'
require '/Users/eguitarz/Developer/juice/lib/juice.rb'

class JuiceTest < Test::Unit::TestCase
  #@@uri = 'http://blog.goo.ne.jp/yoneyonehiro/e/81b5bf5486eb5da6be1e0057e71cac20'
  #@@uri = 'http://tw.news.yahoo.com/%E5%A4%A7%E5%B8%AB%E7%9C%8B%E8%98%8B%E6%9E%9C-%E9%9C%B8%E6%AC%8A%E6%9C%83%E4%B8%8B%E6%BB%91-050808591.html'
  #@@uri = 'http://tw.news.yahoo.com/%E5%BD%B1-%E6%B5%B7%E4%B8%AD%E9%9C%B8%E7%8E%8B%E9%AF%8A%E9%AD%9A%E7%AB%9F%E6%80%95-%E7%A3%81%E9%90%B5-%E9%81%87%E5%88%B0%E7%AB%8B%E5%8D%B3%E9%96%83%E8%BA%B2-233200848.html'
  #@@uri = 'http://dale-ma.heroku.com/blog/2012/03/25/first-trial-on-octopress/'
  #@@uri = 'http://www.ruby-doc.org/core-1.9.3/String.html'
  #@@uri = 'http://ihower.tw/rails3/intro.html'
  #@@uri = 'http://www.nytimes.com/2012/04/12/us/zimmerman-to-be-charged-in-trayvon-martin-shooting.html?_r=1&hp'
  #@@uri = 'http://www.bnext.com.tw/focus/view/cid/103/id/22818'
  #@@uri = 'http://blog.xdite.net/posts/2012/04/07/startup-rapid-development/'
  #@@uri = 'http://www.kaiak.tw/2012/03/giorgia-zanellato.html'
  #@@uri = 'http://www.commonhealth.com.tw/article/article.action?id=5016934'
  #@@uri = 'http://www.hpx-party.com/blog/archives/4881'
  #@@uri = 'http://phrogz.net/programmingruby/language.html'
  #@@uri = 'http://blog.yam.com/tzui/article/48599613'
  #@@uri = 'http://www.kt.com/corp/intro.jsp'
  #@@uri = 'http://fr.wikipedia.org/wiki/Gouvernement_fran%C3%A7ais'
  #@@uri = 'http://tw.yahoo.com/'
  #@@uri = 'http://olemortenamundsen.wordpress.com/2010/09/13/working-with-private-rubygems-in-rails-3-deploying-to-heroku/'
  def test_extract
    juice = Juice.new(@@uri)
    #juice.scan(doc)

    juice.extract
    #puts juice.title
    puts juice.content

  end

  def test_analyze
    #juice = Juice.new(@@uri)
    #juice.analyze
  end

end
