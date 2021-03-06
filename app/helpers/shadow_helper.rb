module ShadowHelper
  class ShadowOptions < Hash
    def initialize
      self[:top] = ShadowLmr.new
      self[:middle] = ShadowLmr.new
      self[:bottom] = ShadowLmr.new
    end

    def top
      self[:top]
    end

    def middle
      self[:middle]
    end

    def bottom
      self[:bottom]
    end
  end

  class ShadowLmr < Hash
    def initialize
      self[:left] = ShadowText.new
      self[:middle] = ShadowText.new
      self[:right] = ShadowText.new
    end

    def left
      self[:left]
    end

    def middle
      self[:middle]
    end

    def right
      self[:right]
    end
  end

  class ShadowText < Hash
    def initialize
      self[:text] = String.new
    end

    def text
      self[:text]
    end

    def text=(val)
      self[:text]=val
    end
  end
  # Creates a table that includes elements created in block and
  # surrounds them with inner shadow
  #
  # ==== Options
  # * top
  # * bottom
  # * left
  # * right
  #
  # ==== Examples
  #
  # inner_shadow do
  #   <div>sth</div>
  # end
  #
  # inner_shadow :top, :bottom) do
  #   <div>Div without top and bottom inner shadow</div>
  # end
  #
  # inner_shadow :left, :style => "background-color: white;") do
  #   <div>This element will has white background</div>
  # end
  #
  # inner_shadow :left, {:style => "background-color: white;", :id => 'inner-td-of-shadowed-table'}, {:id => 'shadow-table-without-left-shadow'}) do
  #   <div>This element will has white background</div>
  # end
  def inner_shadow(*args, &block)
    inner_or_outer_shadow(:inner, '80grey', *args, &block)
  end


  def light_shadow(*args, &block)
    shadow('60blue', *args, &block)
  end


  def strong_shadow(*args, &block)
    shadow('80grey', *args, &block)
  end

  alias_method :dark_shadow, :strong_shadow
  
  # Creates a table that includes elements created in block and
  # surrounds them with outer shadow
  #
  # ==== Options
  # * top
  # * bottom
  # * left
  # * right
  #
  # ==== Examples
  #
  # shadow('80grey' do
  #   <div>sth</div>
  # end
  #
  # shadow('80grey', :top, :bottom) do
  #   <div>Div without top and bottom shadow</div>
  # end
  #
  # shadow('60blue', :left, :style => "background-color: white;") do
  #   <div>This element will has white background</div>
  # end
  #
  # shadow('60blue', :left, {:style => "background-color: white;", :id => 'inner-td-of-shadowed-table'}, {:id => 'shadow-table-without-left-shadow'}) do
  #   <div>This element will has white background</div>
  # end
  #
  # shadow '60blue', :left, {}, {}, {:top => {:left => 'Text in top left table corner.' }} do
  #   <div></div>
  # end
  def shadow(*args, &block)
    inner_or_outer_shadow(:outer, *args, &block)
  end

  private

  # inner_or_outer_shadow(:inner, '80grey', :left, :right ... element-options, table-shadow-boxes-content-hash do ... end
  # inner_or_outer_shadow(:inner, '80grey', :left, :right ... element-options, table-options do ... end
  # inner_or_outer_shadow(:outer, '60blue' ... element-options do ... end
  # inner_or_outer_shadow :outer, '60blue', 'some text', ... element-options
  def inner_or_outer_shadow(*args, &block)
    hashes = []
    while args.last.is_a? Hash do
      hashes << args.extract_options!
    end
    hashes.reverse!

    content_options = hashes.first || {}
    table_options = hashes.second || {}
    element_contents = hashes.third || {}

    type = args.shift

    type = case type
    when :inner then 'inner-shadow'
    when :outer then 'shadow'
    else raise 'Unknown shadow type'
    end

    style = args.shift
    raise 'Wrong argument' unless style.is_a? String

    content_text = ''
    unless block_given?
      content_text = args.shift
      raise 'Wrong argument' unless content_text.is_a? String
    end


    table_options[:class] ||= 'shadow'
    content_options[:class] ||= 'mm-shadow'

    top = !args.include?(:top)
    bottom = !args.include?(:bottom)
    left = !args.include?(:left)
    right = !args.include?(:right)

    text = ''

    #top
    if top
      content = element_contents[:top] || {}
      tr = ''

      element = content[:left] || {}
      tr << content_tag(:td, element.delete(:text), {:class => "tl-#{type}-#{style} shadow-x shadow-y"}.merge(element) ) if left
      
      element = content[:middle] || {}
      tr << content_tag(:td, element.delete(:text), {:class => "tm-#{type}-#{style} shadow-x"}.merge(element) )

      element = content[:right] || {}
      tr << content_tag(:td, element.delete(:text), {:class => "tr-#{type}-#{style} shadow-x shadow-y"}.merge(element) ) if right

      text << content_tag(:tr, tr)
    end

    #middle
    begin
      content = element_contents[:middle] || {}
      tr = ''

      element = content[:left] || {}
      tr << content_tag(:td, element.delete(:text), {:class => "ml-#{type}-#{style} shadow-y"}.merge(element) ) if left
      
      tr << content_tag(:td, (block_given? ? capture(&block) : content_text), content_options)
      
      element = content[:right] || {}
      tr << content_tag(:td, element.delete(:text), {:class => "mr-#{type}-#{style} shadow-y"}.merge(element) ) if right

      text << content_tag(:tr, tr)
    end

    #bottom
    if bottom
      content = element_contents[:bottom] || {}
      tr = ''

      element = content[:left] || {}
      tr << content_tag(:td, element.delete(:text), {:class => "bl-#{type}-#{style} shadow-x shadow-y"}.merge(element) ) if left
      
      element = content[:middle] || {}
      tr << content_tag(:td, element.delete(:text), {:class => "bm-#{type}-#{style} shadow-x"}.merge(element) )

      element = content[:right] || {}
      tr << content_tag(:td, element.delete(:text), {:class => "br-#{type}-#{style} shadow-x shadow-y"}.merge(element) ) if right

      text << content_tag(:tr, tr)
    end

    if block_given?
      concat content_tag(:table, text, table_options)
    else
      content_tag(:table, text, table_options)
    end
  end
end