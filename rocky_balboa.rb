require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'active_support/all'
require 'audite'

module Capybara::Poltergeist
  class Client
    private

    def redirect_stdout
      prev = STDOUT.dup
      prev.autoclose = false
      $stdout = @write_io
      STDOUT.reopen(@write_io)

      prev = STDERR.dup
      prev.autoclose = false
      $stderr = @write_io
      STDERR.reopen(@write_io)
      yield
    ensure
      STDOUT.reopen(prev)
      $stdout = STDOUT
      STDERR.reopen(prev)
      $stderr = STDERR
    end
  end
end

class WarningSuppressor
  class << self
    def write(message)
      if message =~ /QFont::setPixelSize: Pixel size <= 0/ || message =~/CoreText performance note:/ then 0 else puts(message);1;end
    end
  end
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: false, phantomjs_logger: WarningSuppressor)
end

Capybara.current_driver = :poltergeist
Capybara.run_server = false
Capybara.app_host = 'http://punchlock.herokuapp.com'

module RockyBalboa
  class Puncher
    include Capybara::DSL

    def initialize(email, password)
      raise 'InvalidCredentials' if email.blank? or password.blank?

      @email = email
      @password = password

      play_theme!
      login!
    end

    def punch!(options = {})
      project = options.fetch(:project)
      from = Date.parse options.fetch(:from)
      to = Date.parse options.fetch(:to)

      start_hour   = options.fetch(:start_hour)
      lunch_hour   = options.fetch(:lunch_hour)
      return_hour  = lunch_hour + 1
      exit_hour    = (8 - (lunch_hour - start_hour)) + (lunch_hour + 1)

      (from..to).each do |date|
        next if date.saturday? || date.sunday?

        create_punch(project, date, start_hour, lunch_hour)
        create_punch(project, date, return_hour, exit_hour)
      end
    end

    private

    def play_theme!
      Thread.new do
        player = Audite.new
        player.load('rocky_balboa_theme.mp3')
        player.start_stream
      end
    end

    def create_punch(project, date, start_hour, end_hour)
      puts "Punch for #{date.to_s} - From: #{start_hour} To: #{end_hour}"

      visit('/punches/new')

      fill_in 'punch[from(4i)]', with: start_hour
      fill_in 'punch[to(4i)]', with: end_hour
      fill_in 'when_day', with: date.to_s
      select project, from: 'punch[project_id]'

      click_button 'Create Punch'
    end

    def login!
      visit('/users/sign_in')

      fill_in 'Email', with: @email
      fill_in 'Password', with: @password

      click_button 'Sign in'
    end
  end
end

puncher = RockyBalboa::Puncher.new(ENV['EMAIL'], ENV['PASSWORD'])
puncher.punch!(start_hour: 10, lunch_hour: 13, from: ENV['FROM'], to: ENV['TO'], project: ENV['PROJECT'])
