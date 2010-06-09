require "java"
require "rexml/document"

class SwingXml
  def initialize(xml)
    document = REXML::Document.new(xml)
    @widget_hash = {}
    @widget = handle document.root, nil
  end

  attr_reader :widget

  def [](widget_symbol)
    @widget_hash[widget_symbol.to_sym]
  end

  private
  def handle(element, parent)
    raise ArgumentError, "Element #{element.name} does not have an sxmlId!" unless element.attributes.has_key? "sxmlId"
    raise ArgumentError, "Duplicate key found on #{element.name} (#{element.attributes['sxmlId']})!" if @widget_hash.has_key? element.attributes["sxmlId"].to_sym

    widget = eval "#{element.name}.new"
    @widget_hash[element.attributes["sxmlId"].to_sym] = widget

    element.attributes.each do |name, value|
       eval "widget.set_#{name} #{value}" unless name.index("sxml") == 0
    end

    element.elements.each do |child|
       handle child, widget
    end

    if element.attributes.has_key? "sxmlAction"
       eval "parent.#{element.attributes['sxmlAction']} widget" unless parent.nil?
    else
       parent.add widget unless parent.nil?
    end

    widget
  end
end
