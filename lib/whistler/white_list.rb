require 'xml/libxml'

module Whistler
  
  def self.protocol_attributes
    @_protocol_attributes = %w(src href)
  end
  
  def self.protocol_separator
    @_protocol_seperator = /:|(&#0*58)|(&#x70)|(%|&#37;)3A/
  end
  
  def self.white_tags
    @_white_tags ||= %w(strong em b i p code pre tt output samp kbd var sub sup dfn cite big small address hr br div span h1 h2 h3 h4 h5 h6 ul ol li dt dd abbr acronym a img blockquote del ins fieldset legend)
  end
  
  def self.white_attributes
    @_white_attributes ||= %w(href src width height alt cite datetime title class name)
  end
  
  def self.white_protocols
    @_white_protocols ||= %w(ed2k ftp http https irc mailto news gopher nntp telnet webcal xmpp callto feed)
  end
  
  def white_list(string, opts = {})
    return nil if string.nil?
    w_tags  = get_white_tags(opts)
    w_attrs = get_white_attributes(opts)
    
    parser = XML::HTMLParser.new
    parser.string = string
    doc = parser.parse
    # doc = Hpricot("#{string}")
    # puts doc.inspect
    # doc.traverse_element do |elem|
    #   if elem.elem?
    #     if w_tags.include?(elem.name)
    #       (elem.attributes.keys - w_attrs).each{|a| elem.remove_attribute(a)}
    #       (elem.attributes.keys & Whistler.protocol_attributes).each{|a| elem.remove_attribute(a) if contains_bad_protocols?(elem[a])}
    #     else
    #       elem.parent.children.delete(elem) 
    #     end
    #   else
    #   end
    # end
    # doc.to_html
  end
  
  private
  
  def get_white_tags(opts)
    return opts[:tags] if opts[:tags]
      
    if opts[:add_tags]
      wtags = Whistler.white_tags.dup
      wtags << opts[:add_tags]
      wtags = wtags.flatten
      return wtags
    end
    
    return Whistler.white_tags
  end
  
  def get_white_attributes(opts)
    return opts[:attributes] if opts[:attributes]
    return Whistler.white_attributes
  end
  
  def contains_bad_protocols?(value)
    value =~ Whistler.protocol_separator && !Whistler.white_protocols.include?(value.split(Whistler.protocol_separator).first)
  end 
end
  