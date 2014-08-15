# encoding: utf-8

# Encapsulates specific view service classes in standard interface
class PageMeta
  attr_reader :meta

  def initialize(meta_instance)
    @meta = meta_instance
  end

  def title
    @meta.respond_to?(:title) ? @meta.title : nil
  end

  def subtitle
    @meta.respond_to?(:subtitle) ? @meta.subtitle : nil
  end

  def description
    @meta.respond_to?(:description) ? @meta.description : nil
  end
end
