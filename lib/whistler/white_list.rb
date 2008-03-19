require 'hpricot'
module Whistler
  
  def self.protocol_attributes
    @_protocol_attributes = %w(src href)
  end
  
  def self.protocol_separator
    @_protocol_seperator = /:|(&#0*58)|(&#x70)|(%|&#37;)3A/
  end
  
  # An array of default allowed tags.
  def self.white_tags
    @_white_tags ||= %w(strong em b i p code pre tt output samp kbd var sub sup dfn cite big small address hr br div span h1 h2 h3 h4 h5 h6 ul ol li dt dd abbr acronym a img blockquote del ins fieldset legend)
  end
  
  # An array of default allowed attributes
  def self.white_attributes
    @_white_attributes ||= %w(href src width height alt cite datetime title class name)
  end
  
  # An array of default allowed protocols
  def self.white_protocols
    @_white_protocols ||= %w(ed2k ftp http https irc mailto news gopher nntp telnet webcal xmpp callto feed)
  end
  
  
  # This is the work horse of the Whistler gem.  It whitelists a string of Markup.
  # *string* - The string to white list
  # *opts* - A group of options to apply for this run
  # === valid options
  # * <tt>:tags</tt> - An array of allowed tags.  This list is exlusive of all others and only tags included in this list will be allowed
  # * <tt>:add_tags</tt> - An array of extra allowed tags.  All normal tags are allowed, plus the ones specified in this array
  # * <tt>:attributes</tt> - An array of allowed attributes.  This list is exlusive of all others and only attributes included will be allowed.
  # 
  # === Example
  # {{{
  #   Whistler.white_list(my_markup_string, :add_tags => %w(object param) )
  # }}}
  # Allows object and param tags in addition to normal allowed tags. 
  def self.white_list(string, opts = {})
    return nil if string.nil?
    w_tags  = get_white_tags(opts)
    w_attrs = get_white_attributes(opts)
    
    string = string.gsub("\000", "")
    
    doc = Hpricot(string)
    doc.traverse_element do |elem|
      if elem.elem?
        if w_tags.include?(elem.name)
          (elem.attributes.keys - w_attrs).each{|a| elem.remove_attribute(a)}
          (elem.attributes.keys & Whistler.protocol_attributes).each{|a| elem.remove_attribute(a) if contains_bad_protocols?(elem[a])}
          elem.raw_attributes.each{|a,v| elem.raw_attributes[a] = clean_attribute(v)}
        else
          elem.parent.children.delete(elem) 
        end
      elsif elem.text?
        elem.parent.replace_child(elem, Hpricot::Text.new(escape_text(elem.to_s)))    
      end
    end
    doc.to_html
  end
  
  def white_list(string, opts = {} )
    Whistler.white_list(string, opts)
  end
  
  private
  
  def self.get_white_tags(opts)
    return opts[:tags] if opts[:tags]
      
    if opts[:add_tags]
      wtags = Whistler.white_tags.dup
      wtags << opts[:add_tags]
      wtags = wtags.flatten
      return wtags
    end
    
    return Whistler.white_tags
  end
  
  def self.get_white_attributes(opts)
    return opts[:attributes] if opts[:attributes]
    return Whistler.white_attributes
  end
  
  def self.contains_bad_protocols?(value)
    value =~ Whistler.protocol_separator && !Whistler.white_protocols.include?(value.split(Whistler.protocol_separator).first)
  end 
  
  def self.escape_text(string)
    string.gsub(/</, "&lt;")
  end
  
  def self.clean_attribute(a)
    a.gsub(/</, "&lt;").gsub(/>/, "&gt;")
  end
end
  