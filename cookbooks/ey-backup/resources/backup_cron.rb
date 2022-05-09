provides :backup_cron
unified_mode true

property :minute, String
property :hour, String
property :day, String
property :month, String
property :weekday, String
property :command, String

# Setting all properties as string because crons can be formatted in ways like */5

default_action :create

action :create do
  cron new_resource.name do
    action new_resource.action
    minute new_resource.minute
    hour new_resource.hour
    day new_resource.day
    month new_resource.month
    weekday new_resource.weekday
    command new_resource.command
  end
end