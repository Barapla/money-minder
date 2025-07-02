# frozen_string_literal: true

# app/helpers/color_helper.rb
module ColorHelper
  COLOR_CLASSES = {
    'red' => 'bg-red-500',
    'orange' => 'bg-orange-500',
    'yellow' => 'bg-yellow-500',
    'green' => 'bg-green-500',
    'blue' => 'bg-blue-500',
    'purple' => 'bg-purple-500',
    'pink' => 'bg-pink-500',
    'emerald' => 'bg-emerald-500',
    'indigo' => 'bg-indigo-500',
    'cyan' => 'bg-cyan-500',
    'teal' => 'bg-teal-500',
    'lime' => 'bg-lime-500',
    'amber' => 'bg-amber-500',
    'rose' => 'bg-rose-500'
  }.freeze

  def color_bg_class(color_name)
    COLOR_CLASSES[color_name.to_s.downcase] || 'bg-gray-500'
  end

  def color_text_class(color_name)
    COLOR_CLASSES[color_name.to_s.downcase]&.gsub('bg-', 'text-') || 'text-gray-500'
  end

  def color_border_class(color_name)
    COLOR_CLASSES[color_name.to_s.downcase]&.gsub('bg-', 'border-') || 'border-gray-500'
  end
end
