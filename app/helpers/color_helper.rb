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
    'gray_light' => 'bg-gray-200',
    'gray_medium' => 'bg-gray-400',
    'gray_dark' => 'bg-gray-600',
    'emerald' => 'bg-emerald-500',
    'indigo' => 'bg-indigo-500',
    'cyan' => 'bg-cyan-500',
    'teal' => 'bg-teal-500',
    'lime' => 'bg-lime-500',
    'amber' => 'bg-amber-500',
    'rose' => 'bg-rose-500'
  }.freeze

  COLOR_40_CLASSES = {
    'red' => 'bg-red-500/40',
    'orange' => 'bg-orange-500/40',
    'yellow' => 'bg-yellow-500/40',
    'green' => 'bg-green-500/40',
    'blue' => 'bg-blue-500/40',
    'purple' => 'bg-purple-500/40',
    'pink' => 'bg-pink-500/40',
    'gray_light' => 'bg-gray-200/40',
    'gray_medium' => 'bg-gray-400/40',
    'gray_dark' => 'bg-gray-600/40',
    'emerald' => 'bg-emerald-500/40',
    'indigo' => 'bg-indigo-500/40',
    'cyan' => 'bg-cyan-500/40',
    'teal' => 'bg-teal-500/40',
    'lime' => 'bg-lime-500/40',
    'amber' => 'bg-amber-500/40',
    'rose' => 'bg-rose-500/40'
  }.freeze

  COLOR_TEXT_CLASSES = {
    'red' => 'text-red-500',
    'orange' => 'text-orange-500',
    'yellow' => 'text-yellow-500',
    'green' => 'text-green-500',
    'blue' => 'text-blue-500',
    'purple' => 'text-purple-500',
    'pink' => 'text-pink-500',
    'gray_light' => 'text-gray-200',
    'gray_medium' => 'text-gray-400',
    'gray_dark' => 'text-gray-600',
    'emerald' => 'text-emerald-500',
    'indigo' => 'text-indigo-500',
    'cyan' => 'text-cyan-500',
    'teal' => 'text-teal-500',
    'lime' => 'text-lime-500',
    'amber' => 'text-amber-500',
    'rose' => 'text-rose-500'
  }.freeze

  COLOR_400_TEXT_CLASSES = {
    'red' => 'text-red-400',
    'orange' => 'text-orange-400',
    'yellow' => 'text-yellow-400',
    'green' => 'text-green-400',
    'blue' => 'text-blue-400',
    'purple' => 'text-purple-400',
    'pink' => 'text-pink-400',
    'emerald' => 'text-emerald-400',
    'indigo' => 'text-indigo-400',
    'cyan' => 'text-cyan-400',
    'teal' => 'text-teal-400',
    'lime' => 'text-lime-400',
    'amber' => 'text-amber-400',
    'rose' => 'text-rose-400'
  }.freeze

  COLOR_BORDER_CLASSES = {
    'red' => 'border-red-500',
    'orange' => 'border-orange-500',
    'yellow' => 'border-yellow-500',
    'green' => 'border-green-500',
    'blue' => 'border-blue-500',
    'purple' => 'border-purple-500',
    'pink' => 'border-pink-500',
    'gray_light' => 'border-gray-200',
    'gray_medium' => 'border-gray-400',
    'gray_dark' => 'border-gray-600',
    'emerald' => 'border-emerald-500',
    'indigo' => 'border-indigo-500',
    'cyan' => 'border-cyan-500',
    'teal' => 'border-teal-500',
    'lime' => 'border-lime-500',
    'amber' => 'border-amber-500',
    'rose' => 'border-rose-500'
  }.freeze

  def color_bg_class(color_name, opacity = 100)
    if opacity == 40
      COLOR_40_CLASSES[color_name.to_s.downcase] || 'bg-gray-500/40'
    else
      COLOR_CLASSES[color_name.to_s.downcase] || 'bg-gray-500'
    end
  end

  def color_text_class(color_name, shade = 500)
    if shade == 400
      COLOR_400_TEXT_CLASSES[color_name.to_s.downcase] || 'text-white'
    else
      COLOR_TEXT_CLASSES[color_name.to_s.downcase] || 'text-white'
    end
  end

  def color_border_class(color_name)
    COLOR_BORDER_CLASSES[color_name.to_s.downcase] || 'border-gray-500'
  end
end
