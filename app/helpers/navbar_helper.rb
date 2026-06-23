# frozen_string_literal: true

# NavbarHelper
module NavbarHelper
  def navbar_active_class(path)
    current_page?(path) ? 'navbar-link active' : 'navbar-link'
  end

  def navbar_link_to(name, path)
    render Buttons::LinkComponent.new(content: name, href: path,
                                      options: { class: navbar_active_class(path) })
  end

  def navbar_dropdown_active?(paths)
    paths.any? { |path| current_page?(path) }
  end

  def navbar_dropdown_trigger_class(paths)
    base = 'navbar-dropdown-trigger'
    navbar_dropdown_active?(paths) ? "#{base} active" : base
  end

  def navbar_dropdown_item_class(path)
    current_page?(path) ? 'navbar-dropdown-item active' : 'navbar-dropdown-item'
  end

  def navbar_dropdown_item_to(name, path)
    link_to name, path, class: navbar_dropdown_item_class(path)
  end
end
