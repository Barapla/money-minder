# frozen_string_literal: true

namespace :sample_data do
  desc 'Create sample obligatory payments for testing'
  task create_obligatory_payments: :environment do
    puts 'Creating sample obligatory payments...'

    user = User.first
    unless user
      puts 'Error: No users found. Please create a user first.'
      exit
    end

    # Get catalogs
    colors = Catalog.by_group('colors').to_a
    icons = Catalog.by_group('transaction_icons').to_a
    categories = Category.limit(10).to_a
    monthly_frequency = Catalog.by_group_and_code('frequency_types', 'monthly')
    obligatory_payment_type = Catalog.by_group_and_code('recurrenceable_types', 'obligatory_payment')

    if colors.empty? || icons.empty? || categories.empty?
      puts 'Error: Missing required catalogs (colors, icons, or categories)'
      exit
    end

    unless monthly_frequency
      puts 'Error: Monthly frequency type not found'
      exit
    end

    unless obligatory_payment_type
      puts 'Error: Obligatory payment recurrenceable type not found'
      exit
    end

    # Sample obligatory payments
    sample_payments = [
      { name: 'Renta del Departamento', amount: 10000, day: 5 },
      { name: 'Netflix Subscription', amount: 199, day: 10 },
      { name: 'Spotify Premium', amount: 115, day: 15 },
      { name: 'Gimnasio', amount: 500, day: 1 },
      { name: 'Internet y Cable', amount: 699, day: 20 },
      { name: 'Seguro de Auto', amount: 1200, day: 25 },
      { name: 'Tarjeta de Crédito', amount: 3000, day: 28 },
      { name: 'Luz y Gas', amount: 800, day: 12 }
    ]

    sample_payments.each_with_index do |payment_data, index|
      # Random color and icon
      color = colors.sample
      icon = icons.sample
      category = categories.sample

      # Create obligatory payment
      payment = ObligatoryPayment.create!(
        user: user,
        name: payment_data[:name],
        amount: payment_data[:amount],
        category: category,
        color: color,
        icon: icon
      )

      # Create monthly recurrence
      Recurrence.create!(
        recurrenceable: payment,
        recurrenceable_type: obligatory_payment_type,
        frequency_type: monthly_frequency,
        frequency_value: 1,
        day_of_month: payment_data[:day]
      )

      puts "✓ Created: #{payment.name} ($#{payment.amount}) - Due day: #{payment_data[:day]}"
    end

    puts "\n#{sample_payments.count} obligatory payments created successfully!"
    puts "Visit /obligatory-payments-calendar to see them!"
  end
end
