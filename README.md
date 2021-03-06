# m43nu/rails-template

## Description

*Forked from mattbrictson/rails-template*

This is the application template that We use for my Rails 6 projects.

## Requirements

This template currently works with:

* Rails 6.0.x
* PostgreSQL

If you need help setting up a Ruby development environment, check out Matt Brictsons [Rails OS X Setup Guide](https://mattbrictson.com/rails-osx-setup-guide).

## Installation

*Optional.*

To make this the default Rails application template on your system, create a `~/.railsrc` file with these contents:

```
-d postgresql
-m https://raw.githubusercontent.com/m43nu/rails-template/master/template.rb
```

## Usage

This template assumes you will store your project in a remote git repository (e.g. Bitbucket or GitHub) and that you will deploy to a production environment. It will prompt you for this information in order to pre-configure your app, so be ready to provide:

1. The git URL of your (freshly created and empty) Bitbucket/GitHub repository
2. The hostname of your production server

To generate a Rails application using this template, pass the `-m` option to `rails new`, like this:

```
rails new blog \
  -d postgresql \
  -m https://raw.githubusercontent.com/m43nu/rails-template/master/template.rb
```

*Remember that options must go after the name of the application.* The only database supported by this template is `postgresql`.

If you’ve installed this template as your default (using `~/.railsrc` as described above), then all you have to do is run:

```
rails new blog
```

## What does it do?

The template will perform the following steps:

1. Generate your application files and directories
2. Ensure bundler is installed
3. Create the development and test databases
4. Commit everything to git
5. Push the project to the remote git repository you specified

## What is included?

#### These gems are added to the standard Rails stack

* Core
    * [sidekiq][] – Redis-based job queue implementation for Active Job    
* Configuration
    * [dotenv][] – in place of the Rails `secrets.yml`
* Utilities
    * [annotate][] – auto-generates schema documentation
    * [autoprefixer-rails][] – automates cross-browser CSS compatibility
    * [awesome_print][] – try `ap` instead of `puts`
    * [better_errors][] – useful error pages with interactive stack traces
    * [guard][] – runs tests as you develop; mandatory for effective TDD
    * [livereload][] – magically refreshes browsers whenever you save a file
    * [rubocop][] – enforces Ruby code style
    * [haml-rails][] - use haml instead of erb
    * [unpoly][] - an unobtrusive JavaScript framework for server-side web applications
* Deployment via Capistrano (optional)
    * [capistrano-mb][] – capistrano recipes
    * [unicorn][] – the industry-standard Rails server
    * [unicorn-worker-killer][] – to manage memory use
* Security
    * [brakeman][] and [bundler-audit][] – detect security vulnerabilities
* Testing
    * [capybara][] and [poltergeist][] – integration testing
    * [simplecov][] – code coverage reports
    * [shoulda][] – shortcuts for common ActiveRecord tests
    * [test_after_commit][] – ensures after_commit hooks can be tested

#### Mailgun

Action Mailer is configured to use [Mailgun][] to send emails. You can change this by editing `environments/production.rb`.

#### Bootstrap integration (optional)

[Bootstrap][]-related features are opt-in. To apply these to your project, answer "yes" when prompted.

* Bootstrap-themed scaffold templates
* Application layout that includes Bootstrap-style navbar and boilerplate
* View helpers for generating common Bootstrap markup

#### AlchemyCMS integration (optional)

[AlchemyCMS][]-related features are opt-in. To apply these to your project, answer "yes" when prompted.

* Installs AlchemyCMS and AlchemyCMS-Devise
* Application layout ready to use with AlchemyCMS

#### Other tweaks that patch over some Rails shortcomings

* A much-improved `bin/setup` script
* Log rotation so that development and test Rails logs don’t grow out of control

#### Plus lots of documentation for your project

* `README.md`
* `PROVISIONING.md` and `DEPLOYMENT.md` for Capistrano (optional)

## How does it work?

This project works by hooking into the standard Rails [application templates][] system, with some caveats. The entry point is the [template.rb][] file in the root of this repository.

Normally, Rails only allows a single file to be specified as an application template (i.e. using the `-m <URL>` option). To work around this limitation, the first step this template performs is a `git clone` of the `m43nu/rails-template` repository to a local temporary directory.

This temporary directory is then added to the `source_paths` of the Rails generator system, allowing all of its ERb templates and files to be referenced when the application template script is evaluated.

Rails generators are very lightly documented; what you’ll find is that most of the heavy lifting is done by [Thor][]. The most common methods used by this template are Thor’s `copy_file`, `template`, and `gsub_file`. You can dig into the well-organized and well-documented [Thor source code][thor] to learn more.

[sidekiq]:http://sidekiq.org
[haml-rails]:https://github.com/indirect/haml-rails
[unpoly]:https://unpoly.com/
[dotenv]:https://github.com/bkeepers/dotenv
[annotate]:https://github.com/ctran/annotate_models
[autoprefixer-rails]:https://github.com/ai/autoprefixer-rails
[awesome_print]:https://github.com/michaeldv/awesome_print
[better_errors]:https://github.com/charliesome/better_errors
[guard]:https://github.com/guard/guard
[livereload]:https://github.com/guard/guard-livereload
[rubocop]:https://github.com/bbatsov/rubocop
[capistrano-mb]:https://github.com/mattbrictson/capistrano-mb
[unicorn]:http://unicorn.bogomips.org
[unicorn-worker-killer]:https://github.com/kzk/unicorn-worker-killer
[Mailgun]:https://www.mailgun.com/
[brakeman]:https://github.com/presidentbeef/brakeman
[bundler-audit]:https://github.com/rubysec/bundler-audit
[minitest-reporters]:https://github.com/kern/minitest-reporters
[capybara]:https://github.com/jnicklas/capybara
[poltergeist]:https://github.com/teampoltergeist/poltergeist
[mocha]:https://github.com/freerange/mocha
[shoulda]:https://github.com/thoughtbot/shoulda
[simplecov]:https://github.com/colszowka/simplecov
[test_after_commit]:https://github.com/grosser/test_after_commit
[Bootstrap]:http://getbootstrap.com
[AlchemyCMS]:http://alchemy-cms.com
[application templates]:http://guides.rubyonrails.org/generators.html#application-templates
[template.rb]: template.rb
[thor]: https://github.com/erikhuda/thor
