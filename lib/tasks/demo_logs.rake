NUMBER_OF_LOGS = 1000

namespace :demo do

   desc 'Create log test data'
   task :logs => :setup do
      Rake::Task['demo:logs:delete'].invoke
      Rake::Task['demo:logs:create'].invoke
   end

   namespace :logs do
      desc 'Delete all logs'
      task :delete => :setup do
        remove_logs
      end

      desc 'Create all logs'
      task :create => :setup do
        create_logs
      end
   end
end

def create_logs

  STDERR.puts "--> Creating log ..."
  
#  targets = [[Agent, ["Add new", "Delete", "Edit"], :display_name],
#            [Manager, ["Add new", "Delete", "Edit"], :display_name],
#            [Group, ["Add new", "Delete", "Edit"], :name]]
#
#  targets.each do |t|
#     model, actions, attribute = t
#     t << model.find(:all)
#            end
#            managers = Manager.find(:all)
#
#            start_time = Time.now - 3600*24*30
#            1.upto(NUMBER_OF_LOGS) do |i|
#               start_time += 1000
#               model, actions, attribute, objects = targets[rand(targets.size)]
#               object = objects[rand(objects.size)]
#               action = actions[rand(actions.size)]
#               manager = managers[rand(managers.size)]
#               Log.new(:name => "#{action} #{model}",
#                       :target => object.__send__(attribute),
#                       :status => "Success",
#                       :start_time => start_time,
#                       :remote_ip => "192.168.1.#{rand(254)}",
#                       :user => manager.display_name).save
#            end
#
#            # add login logout log
#            start_time = Time.now - 3600*24*30
#            1.upto( NUMBER_OF_LOGS/10 ) do |i|
#               start_time += 10000
#               manager = managers[rand(managers.size)]
#               Log.new(:name => "#{['login','logout'][rand(2)]}",
#                       :target => manager.display_name,
#                       :status => "Success",
#                       :start_time => start_time,
#                       :remote_ip => "192.168.1.#{rand(254)}",
#                       :user => manager.display_name).save
#            end
#         end
end

def remove_logs

  STDERR.puts "--> Removing log ..."
  Logs.delete_all

end         