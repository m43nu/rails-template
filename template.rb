require "bundler"
RAILS_REQUIREMENT = '~> 6.0.0'.freeze

def apply_template!
  assert_minimum_rails_version
  assert_valid_options
  assert_postgresql
  add_template_repository_to_source_path

  template 'Gemfile.tt', force: true

  if apply_capistrano?
    template 'DEPLOYMENT.md.tt'
    template 'PROVISIONING.md.tt'
  end

  template 'README.md.tt', force: true
  remove_file 'README.rdoc'

  template 'example.env.tt'
  copy_file 'editorconfig', '.editorconfig'
  copy_file 'gitignore', '.gitignore', force: true
  copy_file 'rspec', '.rspec', force: true
  template 'ruby-version.tt', '.ruby-version', force: true
  copy_file 'simplecov', '.simplecov'

  copy_file 'Capfile' if apply_capistrano?
  copy_file 'Guardfile'
  copy_file 'Procfile'

  apply 'config.ru.rb'
  apply 'app/template.rb'
  apply 'bin/template.rb'
  apply 'config/template.rb'
  apply 'doc/template.rb'
  apply 'lib/template.rb'
  apply 'public/template.rb'
  apply 'spec/template.rb'
  apply 'vendor/template.rb'

  apply 'variants/bootstrap/template.rb' if apply_bootstrap?

  git :init unless preexisting_git_repo?
  empty_directory '.git/safe'

  run_with_clean_bundler_env 'bin/setup'
  create_initial_migration
  generate_spring_binstubs

  binstubs = %w[
    annotate brakeman bundler bundler-audit guard rubocop terminal-notifier sidekiq
  ]
  binstubs.push('capistrano', 'unicorn') if apply_capistrano?
  run_with_clean_bundler_env "bundle binstubs #{binstubs.join(' ')} --force"

  template 'rubocop.yml.tt', '.rubocop.yml', force: true
  run_rubocop_autocorrections

  if apply_alchemycms?
    apply 'variants/alchemycms/template.rb'

    remove_file 'app/controllers/home_controller.rb'
    remove_file 'app/views/home/index.html.haml'
    Dir.delete File.expand_path('app/views/home', destination_root)

    run 'bundle update'
    run 'bin/rake alchemy:install'
    if apply_alchemycms_devise?
      run 'bin/rails g alchemy:devise:install'
    end

    # alchemy creates that stuff again
    remove_file 'app/views/layouts/application.html.erb'
    remove_file 'app/views/layouts/base.html.haml'
    remove_file 'app/assets/stylesheets/application.css'
    # copy our customized config-file
    template 'config/alchemy/config.yml.tt', force: true

    # recreate db, as the main language seems to be set to the wrong one
    run 'bin/rake db:reset'
  end

  apply 'variants/oriented/template.rb' if apply_oriented?

  unless any_local_git_commits?
    git add: '-A .'
    git commit: "-n -m '[template] Set up project'"
    git checkout: '-b development' if apply_capistrano?
    if git_repo_specified?
      git remote: "add origin #{git_repo_url.shellescape}"
      git push: '-u origin --all'
    end
  end
end

require 'fileutils'
require 'shellwords'

# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit {FileUtils.remove_entry(tempdir)}
    git :clone => [
        "--quiet",
        "https://github.com/m43nu/rails-template.git",
        tempdir
    ].join(" ")

    if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) {git checkout: branch}
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

# Bail out if user has passed in contradictory generator options.
def assert_valid_options
  valid_options = {
      skip_gemfile: false,
      skip_bundle: false,
      skip_git: false,
      skip_test_unit: true,
      skip_javascript: true,
      edge: false
  }
  valid_options.each do |key, expected|
    next unless options.key?(key)
    actual = options[key]
    unless actual == expected
      fail Rails::Generators::Error, "Unsupported option: #{key}=#{actual}"
    end
  end
end

def assert_postgresql
  return if IO.read('Gemfile') =~ /^\s*gem ['"]pg['"]/
  fail Rails::Generators::Error,
       'This template requires PostgreSQL, '\
       'but the pg gem isn’t present in your Gemfile.'
end

# Mimic the convention used by capistrano-mb in order to generate
# accurate deployment documentation.
def capistrano_app_name
  app_name.gsub(/[^a-zA-Z0-9_]/, '_')
end

def git_repo_url
  @git_repo_url ||=
      ask_with_default('What is the git remote URL for this project?', :blue, 'skip')
end

def production_hostname
  @production_hostname ||=
      ask_with_default('Production hostname?', :blue, 'example.com')
end

def privileged_user
  @privileged_user ||=
      ask_with_default('SSH User?', :blue, 'wrr10705')
end

def gemfile_requirement(name)
  @original_gemfile ||= IO.read('Gemfile')
  req = @original_gemfile[/gem\s+['"]#{name}['"]\s*(,[><~= \t\d\.\w'"]*)?.*$/, 1]
  req && req.gsub("'", %(")).strip.sub(/^,\s*"/, ', "')
end

def ask_with_default(question, color, default)
  return default unless $stdin.tty?
  question = (question.split("?") << " [#{default}]?").join
  answer = ask(question, color)
  answer.to_s.strip.empty? ? default : answer
end

def git_repo_specified?
  git_repo_url != "skip" && !git_repo_url.strip.empty?
end

def preexisting_git_repo?
  @preexisting_git_repo ||= (File.exist?(".git") || :nope)
  @preexisting_git_repo == true
end

def any_local_git_commits?
  system('git log &> /dev/null')
end

def apply_bootstrap?
  ask_with_default('Use Bootstrap gems, layouts, views, etc.?', :blue, 'yes')\
    =~ /^y(es)?/i
end

def apply_alchemycms?
  ask_with_default('Install and setup AlchemyCMS?', :blue, 'no')\
    =~ /^y(es)?/i
end

def apply_alchemycms_devise?
  @apply_alchemycms_devise ||=
      ask_with_default('Setup AlchemyCMS Devise Authentication?', :blue, 'no')\
      =~ /^y(es)?/i
end

def apply_oriented?
  ask_with_default('Prepare app for oriented.net Hosting?', :blue, 'no')\
    =~ /^y(es)?/i
end

def apply_capistrano?
  return @apply_capistrano if defined?(@apply_capistrano)
  @apply_capistrano = \
     ask_with_default('Use Capistrano for deployment?', :blue, 'no') \
     =~ /^y(es)?/i
end

def run_with_clean_bundler_env(cmd)
  success = if defined?(Bundler)
              Bundler.with_clean_env { run(cmd) }
            else
              run(cmd)
            end
  unless success
    puts "Command failed, exiting: #{cmd}"
    exit(1)
  end
end

def run_rubocop_autocorrections
  run_with_clean_bundler_env "bin/rubocop -a --fail-level A > /dev/null || true"
end

def create_initial_migration
  return if Dir["db/migrate/**/*.rb"].any?
  run_with_clean_bundler_env "bin/rails generate migration initial_migration"
  run_with_clean_bundler_env "bin/rake db:migrate"
end

apply_template!
