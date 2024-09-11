# frozen_string_literal: true

# module ApplicationHelper
module ApplicationHelper
  def render_svg(name, options = {})
    options[:title] ||= name.underscore.humanize
    options[:aria] = true
    options[:nocomment] = true
    options[:class] = options.fetch(:styles, 'fill-current text-white')

    filename = "#{name}.svg"
    inline_svg_tag(filename, options)
  end
end
