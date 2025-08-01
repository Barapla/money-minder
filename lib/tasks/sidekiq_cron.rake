# frozen_string_literal: true

# lib/tasks/sidekiq_cron.rake
namespace :sidekiq_cron do
  desc 'Load cronjobs from hash'
  task load: :environment do
    cron_jobs = {
      'process_recurring_transactions' => {
        'cron' => ENV.fetch('RECURRING_TRANSACTIONS_CRON', '*/5 * * * *'),
        'class' => 'RecurringTransactionsJob',
        'description' => 'Process all pending recurring transactions'
      },
      'cleanup_recurring_transactions' => {
        'cron' => ENV.fetch('CLEANUP_TRANSACTIONS_CRON', '*/5 * * * *'),
        'class' => 'RecurringTransactionsCleanupJob',
        'description' => 'Clean up completed recurring transactions'
      }
    }

    Sidekiq::Cron::Job.load_from_hash(cron_jobs)
    puts 'Cronjobs loaded successfully!'

    # Mostrar jobs cargados
    Sidekiq::Cron::Job.all.each do |job|
      puts "- #{job.name}: #{job.cron} (#{job.status})"
    end
  end

  desc 'List all cronjobs'
  task list: :environment do
    puts 'Current cronjobs:'
    Sidekiq::Cron::Job.all.each do |job|
      puts "- #{job.name}: #{job.cron} (#{job.status})"
    end
  end

  desc 'Remove all cronjobs'
  task clear: :environment do
    Sidekiq::Cron::Job.destroy_all!
    puts 'All cronjobs removed!'
  end

  desc 'Enable a specific cronjob'
  task :enable, [:job_name] => :environment do |t, args|
    job = Sidekiq::Cron::Job.find(args[:job_name])
    if job
      job.enque!
      puts "Job '#{args[:job_name]}' enabled!"
    else
      puts "Job '#{args[:job_name]}' not found!"
    end
  end

  desc 'Disable a specific cronjob'
  task :disable, [:job_name] => :environment do |t, args|
    job = Sidekiq::Cron::Job.find(args[:job_name])
    if job
      job.disable!
      puts "Job '#{args[:job_name]}' disabled!"
    else
      puts "Job '#{args[:job_name]}' not found!"
    end
  end
end
