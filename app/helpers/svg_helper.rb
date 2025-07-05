# frozen_string_literal: true

# app/helpers/svg_helper.rb
module SvgHelper
  def render_svg(name, css_class = nil)
    options = {}
    options[:class] = css_class if css_class

    inline_svg_tag("icons/#{name}.svg", options)
  end
end
