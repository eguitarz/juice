require 'nokogiri'
require 'open-uri'

class Juice
  attr_accessor :title, :content, :remove_list, :remove_parent_lust, :uri, :debug

  def initialize(resource)
    #@debug = @verbose = true
    @remove_list = %w(
      //script
      //style
      //comment()
      //footer
      //aside
      //sidebar
      //nav
      //navigator
      //menu
      //noscript
      //select
      //radio
      //input
      //button
      //fieldset
      //iframe
      //*[contains(@class,'menu')]
      //*[contains(@class,'aside')]
      //*[contains(@class,'nav')]
      //*[contains(@class,'footer')]
      //*[contains(@class,'comment')]
      //*[contains(@class,'breadcrumb')]
      //*[contains(@class,'preview')]
      //*[contains(@class,'Sidebar')]
      //*[@class='ad']
      //*[@class='form']
      //*[contains(@id,'nav')]
      //*[contains(@id,'aside')]
      //*[contains(@id,'comment')]
      //*[contains(@id,'menu')]
      //*[contains(@id,'footer')]
      //*[contains(@id,'breadcrumb')]
      //*[contains(@id,'Footer')]
      //*[contains(@id,'ad')]
      //*[contains(@id,'preview')]
      //*[@id='form']
    )

    @remove_parent_list = %w(
      //a[contains(@rel,'nofollow')]
    )

    @text_per_tag_ratio = 15
    @text_per_link_ratio = 40

    resource = open(resource)
    charset = resource.charset
    @uri = resource.base_uri
    resource = resource.read

    @doc = Nokogiri::HTML(resource, nil, charset) do |config|
      config.noblanks
    end

  end

  def extract
    return 'Invalid content, the website might protecting their content for third party access...' unless validate

    remove_selector = @remove_list.join(' | ')
    @doc.xpath(remove_selector).each do |node|
      node.remove
    end

    remove_selector = @remove_parent_list.join(' | ')
    @doc.xpath(remove_selector).each do |node|
      node.parent.remove
    end

    append_base_uri(@doc)

    remove_classes_ids
    @title = extract_title
    @original_text_size = @doc.content.size
    debug("<p></p>Original text size: #{@original_text_size}")
    tmp_doc = @doc.dup
    extracted_content_size = 0

    begin
      7.times.each do |index|
        debug("processing times: #{index + 1}")
        original_size = @doc.content.size
        extracted_node = extract_content
        extracted_content_size = extracted_node.content.size
        @content = extracted_node.to_html

        debug("original size: " + original_size.to_s)
        debug("content size: " + extracted_content_size.to_s)
        debug("tag_ratio: " +  @text_per_tag_ratio.to_s)
        debug("link_ratio: " +  @text_per_link_ratio.to_s)

        if extracted_content_size < original_size / 10
          debug('Remove too much, redo...')
          @text_per_tag_ratio /= 1.3
          @text_per_link_ratio /= (1 + (index + 1) * 0.1)
        else
          break
        end

        @doc = tmp_doc.dup
      end

      if extracted_content_size < 100
        debug("<p></p>The page might be a index.")
        @content = @doc.to_html
      end

      delete_empty_html
    rescue Exception => e
      @content = 'The source has something wrong... skip this source'
      debug(e)
    end
  end

  def analyze
    puts 'start analyzing...'
    @doc.xpath('//div | //p').each do |node|
      if node.children.count > 0
        ratio = node.content.size / 1.0 / node.children.count
      else
        ratio = node.content.size
      end

      if node.content
        debug(node.name + ': ' + ratio.to_s + ' bytes / tag ' + node.content.slice(0..15))
      else
        debug(node.name + ': ' + ratio.to_s + ' bytes / tag ')
      end

    end
  end

  protected

  def extract_title
    titles = @doc.xpath('//title')
    if titles.empty?
      'Redmoi'
    else
      titles.first.content
    end
  end

  def extract_content
    tmp = @doc.content

    if @doc.xpath('//article').empty?
      trunk = pick_main_trunk
    else
      @is_article = true
      trunk = @doc.xpath('//article').first
    end

    # remove empty branches
    trunk.xpath('.//div').each do |node|
      ratio = node.content.size
      ratio = node.content.size / 1.0 / node.children.count if node.children.count > 0
      if ratio < @text_per_tag_ratio
        if node.xpath('//img').count == 0
          debug('remove ' + node.name + ' ratio: ' + ratio.to_s + ' content: '  + node.content.slice(0..100))
          node.remove
        end
      end
    end

    new_node = remove_needles(trunk)

    # remove empty nodes
    new_node.xpath('//*').each do |node|
      if node.content.size == 0 && node.xpath('//img').count == 0
        debug("remove " + node.name + " " + node.content.slice(0..30))
        node.remove
      end
    end

    new_node
  end

  private

  def pick_main_trunk
    current_node = @doc.xpath('//body').first
    fat_div = 0
    depth = 0
    debug("body nodes: #{current_node.children.count.to_s}, total nodes: #{@doc.xpath('//*').count.to_s}") if current_node
    return current_node if current_node && current_node.children.count > @doc.xpath('//*').count / 5

    while fat_div < 2 && depth < 5
      fat_div = 0

      current_node = @doc if current_node.nil?
      divs = current_node.xpath('./div')

      tmp_div = divs.first
      divs.each do |div|
        debug("<p></p>parsing... #{div.name}, size: #{div.content.size}, #{div.content.slice(0..100)}")
        if div.content.size > div.content.count("\n") + div.content.count("\s")
          fat_div += 1
          tmp_div = div
        end
      end

      if tmp_div
        current_node = tmp_div
      else
        current_node = current_node.xpath('//div').first
      end

      debug("depth: #{depth.to_s} current_node: #{current_node.name}")

      depth += 1
    end

    debug('selected node: ' + current_node.parent.path)
    debug('selected content: ' + current_node.parent.content.slice(0..100))

    debug("depth: " + depth.to_s)
    current_node = current_node.parent if depth < 10
    nodes = current_node.children

    biggest = nodes.first
    biggest_ratio = 100
    biggest_size = 0
    link_count = 0
    nodes.each do |node|
      link_size = 0
      node.xpath('.//a').each do |a|
        link_size += a.content.size
        link_count += 1
      end

      unrelated_size = node.content.count("\n") + node.content.count("\s") + link_size

      ratio = unrelated_size / 1.0 / node.content.size

      # debug
      debug("<p>" + node.content + "</p>")
      debug("<p></p>unrelated_size = " + unrelated_size.to_s)
      debug("<p></p>content_size = " + node.content.size.to_s)
      debug("<p>ratio: #{ratio}, biggest ratio: #{biggest_ratio}, biggest_size: #{biggest_size}</p>")

      if ratio < biggest_ratio && node.content.size > biggest_size && node.content.size - unrelated_size > @original_text_size / 10
        biggest = node
        biggest_ratio = ratio
        biggest_size = biggest.content.size
        debug("picked")
      end
    end

    return @doc if biggest.nil?
    biggest
  end

  def append_base_uri(node)
    node.xpath('//img[@src]').each do |n|
      if n.attr('src').slice(0..3) != 'http'
        begin
          attr = URI.join(@uri.to_s, n.attr('src')).to_s
          n.set_attribute('src', attr)
        rescue
          n.delete('src')
        end
      end
    end

    node.xpath('//a[@href]').each do |n|
      if n.attr('href').slice(0..3) != 'http'
        begin
          attr = URI.join(@uri.to_s, n.attr('href')).to_s
          n.set_attribute('href', attr)
        rescue
          n.delete('href')
        end
      end
    end

  end

  def remove_needles(node)
    node.xpath('.//div | .//p').each do |n|
      link_count = n.xpath('.//a').count
      link_count = 0.1 if link_count == 0
      text_size = n.content.gsub("\n", '').gsub("\s", '').size
      text_size += 100 if n.xpath('.//img').count > 0

      link_count *= 1.5 if link_count > 8
      text_size *= 2 if @is_article

      text_per_link = text_size / 1.0 / link_count
      debug('<p></p>detect: ' + n.content.slice(0..30) + ' text per link: ' + text_per_link.to_s + " (#{text_size} / #{link_count})" + " limit ratio: #{@text_per_link_ratio}" + ' content: ')
      if text_per_link < @text_per_link_ratio
          debug('<p></p>remove ' + n.name + "-- "  + n.content.slice(0..30))
          n.remove
      end
    end

    node
  end

  def validate
    false if @doc.nil? || @doc.content.size == 0
    true
  end

  def remove_classes_ids
    @doc.xpath('//*').each do |node|
      node.delete('class') unless @debug
      node.delete('id') unless @debug
      node.delete('style')
    end
  end

  def delete_empty_html
   #content.gsub!(/(<br\s*\/?>\s*)+/, '')
    content.gsub!(/(<li>[\s$]*<\/li>)/, '')
  end

  def debug(str)
    if @debug
      if @verbose
        puts '[' + caller[0] + ']: ' + str.to_s
      else
        puts str
      end
    end
  end

end
