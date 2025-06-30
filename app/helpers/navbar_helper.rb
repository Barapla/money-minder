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
end
