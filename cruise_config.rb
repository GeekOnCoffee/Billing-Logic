# Project-specific configuration for CruiseControl.rb

# NOTE: 'Project' and 'SourceControl' below are CruiseControl.rb variables; hence
# the noinspection statement
#noinspection RubyResolve
Project.configure do |project|

  # Send email notifications about broken and fixed builds to email1@your.site, email2@your.site (default: send to nobody)
  project.email_notifier.emails = ['devinterns@hedgeye.com']

  # Set email 'from' field to john@doe.com:
  project.email_notifier.from = 'cruisecontrol@hedgeye.com'

  # Build the project by invoking rake task 'custom'
  # project.rake_task = 'spec'

  # Build the project by invoking shell script "build_my_app.sh". Keep in mind that when the script is invoked,
  # current working directory is <em>[cruise&nbsp;data]</em>/projects/your_project/work, so if you do not keep build_my_app.sh
  # in version control, it should be '../build_my_app.sh' instead
  project.build_command = './config/cruise/run_cruise.sh'

  # Ping Subversion for new revisions every 5 minutes (default: 30 seconds)
  project.scheduler.polling_interval = 5.minutes

  # Am building from the master branch until branch 'develop' comes into effect:
  project.source_control = SourceControl::Git.new :repository => "git@github.com:hedgeyedev/Billing-Logic.git", :branch => 'master'

end
