require File.dirname(__FILE__) + '/spec_helper'
require 'hpricot'
require 'whistler'

describe Whistler do
  
  def should_white_list(raw, exp, opts = {})
    Hpricot(white_list(raw, opts)).to_html.should == Hpricot(exp).to_html
  end
    
  it "should allow tags" do
    Whistler.white_tags.each do |tag_name|
      raw = "<#{tag_name} title=\"1\" name=\"foo\">foo<bad>bar</bad></#{tag_name}>"
      exp = "<#{tag_name} title=\"1\" name=\"foo\">foo</#{tag_name}>"
      should_white_list raw, exp
    end
  end
  
  it "should not blow up with unclosed tags" do
    raw = "<div>Blah<div>Hey there<br><strong>Hey there</strong></div></div>"
    exp = "<div>Blah<div>Hey there<br /><strong>Hey there</strong></div></div>"
    should_white_list raw, exp
  end

  it "should allow anchors" do
    raw = %(<a href="foo" onclick="bar"><script>baz</script></a>)
    exp = %(<a href="foo"></a>)
    should_white_list raw, exp
  end
  
  it "should allow regular image attributes" do
    %w(src width height alt).each do |img_attr|
      raw = %(<img #{img_attr}="foo" onclick="bar" />)
      exp = %(<img #{img_attr}="foo" />)
      should_white_list raw, exp
    end  
  end
  
  it "should handle non-html" do
    should_white_list "abcde", "abcde"    
  end
  
  it "should handle blank text" do
    white_list("").should == ""
    white_list(nil).should == nil  
  end

  it "should allow custom tags" do
    raw = "<u>foo</u>"
    exp = "<u>foo</u>"
    should_white_list(raw, exp, :add_tags => %w(u))
  end
  
  it "should allow custom tags with attributes" do
    raw = %(<fieldset foo="bar">foo</fieldset>)
    exp = raw.dup
    should_white_list(raw, exp, :attributes => ['foo'])
  end
  
  it "should strip these attributes with bad protocols" do
    [%w(img src), %w(a href)].each do |(tag, attr)|
      raw = %(<#{tag} #{attr}="javascript:bang" title="1">boo</#{tag}>)
      exp = %(<#{tag} title="1">boo</#{tag}>)
      should_white_list(raw, exp)
    end
  end
  
  it "should flag bad protocols" do
    %w(about chrome data disk hcp help javascript livescript lynxcgi lynxexec ms-help ms-its mhtml mocha opera res resource shell vbscript view-source vnd.ms.radio wysiwyg).each do |proto|
      Whistler.contains_bad_protocols?("#{proto}://bad").should be_true
    end
  end
  
  it "should accept good protocols" do
    Whistler.white_protocols.each do |proto|
      Whistler.contains_bad_protocols?("#{proto}://good").should be_false
    end    
  end
  
  it "should reject hex codes in protocol" do
    Whistler.contains_bad_protocols?("%6A%61%76%61%73%63%72%69%70%74%3A%61%6C%65%72%74%28%22%58%53%53%22%29").should be_true
    raw = %(<a href="&#37;6A&#37;61&#37;76&#37;61&#37;73&#37;63&#37;72&#37;69&#37;70&#37;74&#37;3A&#37;61&#37;6C&#37;65&#37;72&#37;74&#37;28&#37;22&#37;58&#37;53&#37;53&#37;22&#37;29">1</a>)
    exp = "<a>1</a>"
    should_white_list(raw, exp)
  end
  
  it "should block script tags" do
    raw = %(<SCRIPT\nSRC=http://ha.ckers.org/xss.js></SCRIPT>)
    should_white_list(raw, "")
  end
  
  it "should not fall for xss image hack" do
    [%(<IMG SRC="javascript:alert('XSS');">), 
     %(<IMG SRC=javascript:alert('XSS')>), 
     %(<IMG SRC=JaVaScRiPt:alert('XSS')>), 
    # %(<IMG """><SCRIPT>alert("XSS")</SCRIPT>">),
     %(<IMG SRC=javascript:alert(&quot;XSS&quot;)>),
     %(<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>),
     %(<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>),
     %(<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>),
     %(<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>),
     %(<IMG SRC="jav\tascript:alert('XSS');">),
     %(<IMG SRC="jav&#x09;ascript:alert('XSS');">),
     %(<IMG SRC="jav&#x0A;ascript:alert('XSS');">),
     %(<IMG SRC="jav&#x0D;ascript:alert('XSS');">),
     %(<IMG SRC=" &#14;  javascript:alert('XSS');">)].each_with_index do |img_hack, i|
       should_white_list(img_hack, "<img>")
     end
    
  end
  
  it "should handle this nasty one" do
     raw = %(<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>)
     exp =  %(&lt;IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>)
     should_white_list(raw, exp)
  end
  
  it "should sanitize tag broken up by null" do
    raw = %(<div><SCR\0IPT>alert(\"XSS\")</SCR\0IPT></div>)
    exp = "<div></div>"
    should_white_list raw, exp    
  end
  
  it "should sanitize invalid script tags" do
    raw = %(<SCRIPT/XSS SRC="http://ha.ckers.org/xss.js"></SCRIPT>)
    exp = "&lt;SCRIPT/XSS SRC=\"http://ha.ckers.org/xss.js\">"
    should_white_list raw, exp
  end
  
  it "should sanitize script tags with multiple open brackets" do
    raw = %(<<SCRIPT>alert("XSS");//<</SCRIPT>)
    exp = "&lt;"
    should_white_list raw, exp
    raw = %(<iframe src=http://ha.ckers.org/scriptlet.html\n<)
    exp = %(&lt;iframe src=http://ha.ckers.org/scriptlet.html\n&lt;)
    should_white_list raw, exp
  end
  
  it "should sanitize unclosed script tags" do
    raw = %(<SCRIPT SRC=http://ha.ckers.org/xss.js?<B>)
    exp = "&lt;SCRIPT SRC=http://ha.ckers.org/xss.js?<b></b>"
    should_white_list raw, exp
  end
  
  it "should sanitize half open scripts" do
    raw = %(<IMG SRC="javascript:alert('XSS')")
    exp = "&lt;IMG SRC=\"javascript:alert('XSS')\""
    should_white_list raw, exp
  end
  
  it "should not fall for ridiculous hack" do
    raw = %(<IMG\nSRC\n=\n"\nj\na\nv\na\ns\nc\nr\ni\np\nt\n:\na\nl\ne\nr\nt\n(\n'\nX\nS\nS\n'\n)\n"\n>)
    exp = "<img />"
    should_white_list raw, exp    
  end

  it "should not allow custom block"
  #   def test_should_allow_custom_block
  #     html = %(<SCRIPT type="javascript">foo</SCRIPT><img>blah</img><blink>blah</blink>)
  #     safe = white_list html do |node, bad|
  #       bad == 'script' ? nil : node
  #     end
  #     assert_equal "<img>blah</img><blink>blah</blink>", safe
  #   end
  # 
  
  it "should sanitize attributes" do
    raw = %(<SPAN title="'><script>alert()</script>">blah</SPAN>)
    exp = %(<span title="'&gt;&lt;script&gt;alert()&lt;/script&gt;">blah</span>)
    should_white_list raw, exp
  end
end